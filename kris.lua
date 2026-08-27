local kris = {}

function kris.init(mod)

  local GameVersion = require("src.core.GameVersion")
  local isGen2 = GameVersion.generation(GameVersion.get()) == 2

  local PaletteFX = require("src.render.PaletteFX")
  local Json = require("src.link.Json")
  local originalSpriteObp = PaletteFX.spriteObp
  local advancedPack = assert(PaletteFX.gbcPack())

  -- Sprite variant discovery
  -- ----------------------------------
  local SPRITES_DIR = "assets/sprites"

  local function readMeta(key)
    local metaPath = SPRITES_DIR .. "/" .. key .. "/meta.json"
    if mod.assets:info(metaPath) then
      local ok, decoded = pcall(Json.decode, mod:read(metaPath))
      if ok and type(decoded) == "table" then return decoded end
    end
    return {}
  end

  local function fileVariant(key, name, trueColor)
    local rel = SPRITES_DIR .. "/" .. key .. "/" .. name
    if mod.assets:info(rel) then
      return { path = rel, trueColor = trueColor }
    end
    return nil
  end

  local function byLabel(a, b)
    return a.label < b.label
  end

  local function toChoicePairs(list)
    local out = {}
    for _, entry in ipairs(list) do
      table.insert(out, { entry.label, entry.key })
    end
    return out
  end

  local function defaultKey(list, preferred)
    for _, entry in ipairs(list) do
      if entry.key == preferred then return preferred end
    end
    return list[1] and list[1].key or preferred
  end

  local battleSpriteVariants = {}
  local frontSpriteVariants = {}
  local battleChoices = {}
  local frontChoices = {}

  for _, key in ipairs(mod.assets:list(SPRITES_DIR)) do
    local info = mod.assets:info(SPRITES_DIR .. "/" .. key)
    if info and info.type == "directory" then
      local meta = readMeta(key)
      local label = meta.label or key:upper()

      local back = fileVariant(key, "back.png", false)
      local backColor = fileVariant(key, "backColor.png", true)
      local front = fileVariant(key, "front.png", false)
      local frontColor = fileVariant(key, "frontColor.png", true)

      if back or backColor then
        battleSpriteVariants[key] = { dmg = back or backColor, fullColor = backColor or back }
        table.insert(battleChoices, { label = label, key = key })
      end
      if front or frontColor then
        frontSpriteVariants[key] = { dmg = front or frontColor, fullColor = frontColor or front }
        table.insert(frontChoices, { label = label, key = key })
      end
    end
  end

  table.sort(battleChoices, byLabel)
  table.sort(frontChoices, byLabel)

  -- Define mod options
  -- ----------------------------------
  mod.options:define({
    {
      key = "battleSprite", type = "choice", label = "BATTLE SPRITE",
      choices = toChoicePairs(battleChoices), default = defaultKey(battleChoices, "original")
    },
    {
      key = "frontSprite", type = "choice", label = "FRONT SPRITE",
      choices = toChoicePairs(frontChoices), default = defaultKey(frontChoices, "original")
    },
    {
      key = "colorMode", type = "choice", label = "COLOR PALETTE",
       choices = {
         {"DMG COMPATIBLE", "dmg"},
         {"FULL COLOR", "fullColor"}},
         default = "dmg"}
  })

  -- Assign player sprite based on mod options
  -- -----------------------------------------
  mod.hooks:wrap("player.sprite", function(next, path, ctx)
    path = next(path,ctx)
    if ctx.demo then return path end

    local colorMode = mod.options:get("colorMode")
    local variants, selected

    if ctx.side == "back" then
      variants = battleSpriteVariants
      selected = mod.options:get("battleSprite")
    elseif ctx.side == "front" then
      variants = frontSpriteVariants
      selected = mod.options:get("frontSprite")
    else
      return path
    end

    local variant = variants[selected] and variants[selected][colorMode]

    if variant then
      ctx.trueColor = variant.trueColor
      return mod.assets:path(variant.path)

    end
    return path
  end)

  -- Scale sprite
  -- ---------------------------------------------------
  for label, colorModes in pairs(battleSpriteVariants) do
    for colorMode, asset in pairs(colorModes) do
      local labelId = label .. "_" .. colorMode
      mod.content.battle_sprite_scales:register(labelId, {
        path = mod.assets:path(asset.path),
	scale = 1.0,
      })
    end
  end
  

  -- Recoloring the "advanced" color palette
  -- Falls back to this default unless the selected sprite folder
  -- provides its own via meta.json. -Elvie
  -- ------------------------------------------
  local DEFAULT_CRYSTAL_COLORS = {
    {255, 255, 255},
    {255, 173, 99},
    {1, 99, 198},
    {0, 0, 0}
  }

  local function isColorTable(t)
    if type(t) ~= "table" or #t ~= 4 then return false end
    for _, triplet in ipairs(t) do
      if type(triplet) ~= "table" or #triplet ~= 3 then return false end
      for _, v in ipairs(triplet) do
        if type(v) ~= "number" or v < 0 or v > 255 then return false end
      end
    end
    return true
  end

  -- Per-folder overworld, naming, and gender overrides
  -- Name choices, gender mode, the recolor palette, and the overworld
  -- sprites below all follow whichever folder is selected for FRONT
  -- SPRITE, falling back to Crystal's defaults when a folder doesn't
  -- define them. -Elvie
  -- --------------------------------------------------
  local DEFAULT_NAME_CHOICES = {"KRIS", "AMANDA", "JUANA", "JODI"}
  local DEFAULT_GENDER_MODE = "girl"
  local VALID_GENDER_MODES = { boy = true, girl = true, enby = true }

  local function isNonEmptyStringArray(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for k, v in pairs(t) do
      if type(k) ~= "number" or type(v) ~= "string" or v == "" then return false end
      count = count + 1
    end
    return count > 0
  end

  local overworldKey = mod.options:get("frontSprite")
  local overworldMeta = readMeta(overworldKey)

  local CRYSTAL_COLORS = isColorTable(overworldMeta.overworldColors)
    and overworldMeta.overworldColors or DEFAULT_CRYSTAL_COLORS

  local nameChoices = isNonEmptyStringArray(overworldMeta.nameChoices)
    and overworldMeta.nameChoices or DEFAULT_NAME_CHOICES

  local genderMode = (type(overworldMeta.genderMode) == "string" and VALID_GENDER_MODES[overworldMeta.genderMode])
    and overworldMeta.genderMode or DEFAULT_GENDER_MODE

  -- Overworld sprite files, resolved per file with fallback to
  -- Crystal's stock assets. -Elvie
  -- --------------------------------------------------
  local function overworldAsset(name, fallback)
    local variant = fileVariant(overworldKey, name, false)
    return variant and mod.assets:path(variant.path) or mod.assets:path(fallback)
  end

  local overworldWalk = overworldAsset("overworldWalk.png", "assets/overworld/crystalPlayer.png")
  local overworldBike = overworldAsset("overworldBike.png", "assets/overworld/crystalBike.png")
  local overworldFishSide = overworldAsset("overworldFishSide.png", "assets/overworld/crystalFishSide.png")
  local overworldFishFront = overworldAsset("overworldFishFront.png", "assets/overworld/crystalFishFront.png")
  local overworldFishBack = overworldAsset("overworldFishBack.png", "assets/overworld/crystalFishBack.png")

  -- Intercepts the sprite renderer if the sprite is assigned a matching palette source and applies the CRYSTAL_COLORS palette to the sprite. 
  -- Hands the request back to the original sprite renderer if any other sprite.
  PaletteFX.spriteObp = function(spriteDef, seed)
    if spriteDef and spriteDef.paletteSource == "PLAYER_PALETTE" then
      return CRYSTAL_COLORS, "crystalPlayer"
      end
    
    if originalSpriteObp then
      return originalSpriteObp(spriteDef, seed)
      end
  end

  -- Same rendering interception but for Gen 2. Gated on isGen2 because the
  -- engine unconditionally refuses to require any src.*.gen2.* module while
  -- a Gen 1 game is active (Loader.lua's crossGenerationDenial) -- this
  -- manifest also loads on plain Gen 1, and the previous unconditional
  -- require here crashed mod load on a Red/Blue/Yellow boot. Palettes has
  -- no game-instance dependency, so -- like PaletteFX above -- it's patched
  -- once here rather than deferred to game.ready; patching it inside
  -- game.ready instead re-wraps it every time that event fires, which can
  -- happen more than once per session under dev hot-reload
  -- (POKEPORT_DEV=1, F5), building up a growing chain of wrappers each
  -- time. -Elvie
  -- -----------------------------------------
  if isGen2 then
    local Palettes = require("src.world.gen2.Palettes")
    local originalSpritePalette = Palettes.spritePalette
    Palettes.spritePalette = function(data, daytime, spriteDef, objDef)
      if spriteDef and spriteDef.paletteSource == "PLAYER_PALETTE" then
        return CRYSTAL_COLORS
      end
      return originalSpritePalette(data, daytime, spriteDef, objDef)
    end
  end
  
    
  -- Sprite replacements
  -- RED
  -- image/path values now come from overworldAsset above instead of
  -- fixed paths, so a folder can override them. -Elvie
  -- --------------------------
  mod.content.sprites:patch("SPRITE_RED", {
    image = overworldWalk,
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  mod.content.sprites:patch("SPRITE_RED_BIKE", {
    image = overworldBike,
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  -- Gated on isGen2 (see the Palettes comment above): the field registry
  -- has no Gen 2 target, so these two patches never applied there anyway --
  -- this just makes that boundary explicit instead of a silent no-op. -Elvie
  if not isGen2 then
    mod.content.field:patch("playerPics", {
      front = mod.assets:path(SPRITES_DIR .. "/original/front.png")
    })

    mod.content.field:patch("overworldFx", {
      redFishSide  = { path = overworldFishSide },
      redFishFront = { path = overworldFishFront },
      redFishBack  = { path = overworldFishBack },
    })
  end

  -- Sprite replacements
  -- GOLD
  -- Same overworldWalk/overworldBike source as RED above. -Elvie
  -- -------------------------
  mod.content.sprites:patch("SPRITE_CHRIS", {
    image = overworldWalk,
    trueColor = false,
    paletteSource = "PLAYER_PALETTE",
  }) 

  mod.content.sprites:patch("SPRITE_CHRIS_BIKE", {
    image = overworldBike,
    trueColor = false,
    paletteSource = "PLAYER_PALETTE",
  })

  -- Gen 2 Trainer Card
  -- This can probably be simplified later when the field registry is available
  -- for gen 2.
  -- -----------------------------------------------
  mod.content.screens:register("Gen2TrainerCard", {
    new = function(game, opts)
      local TrainerCard = require("src.ui.gen2.TrainerCard")
      local base = (game.data.gen2MenuGfx or {}).trainerCard or {}

      local gfx = {}
      for k, v in pairs(base) do gfx[k] = v end
      gfx.card = mod.assets:path("assets/menus/card.png")

      local newOpts = {}
      for k, v in pairs(opts or {}) do newOpts[k] = v end
      newOpts.menuGfx = { trainerCard = gfx }

      local instance = TrainerCard.new(game, newOpts)
      if instance.card then
        instance.card.palette = nil 
        instance.card.paletteFor = nil
      end
      return instance
    end,
  })
   
  -- New game naming options
  -- Pulled from nameChoices above instead of a fixed list. Gated on isGen2
  -- for the same reason as playerPics/overworldFx above -- Gen 2's own
  -- naming presets are handled separately below via game.ready. -Elvie
  -- ---------------------------
  if not isGen2 then
    mod.content.field:override("boot", {
      namePresets = {
        player = nameChoices
      }
    })
  end
  
  -- Gen 2 Naming options and forcing true color of player sprite.
  -- This can likely be reduced when the field registry is
  -- hooked into gen 2 via the mod api.
  -- Also pulled from nameChoices above instead of a fixed list. -Elvie
  -- --------------------------------------------------
  mod.events:on("game.ready", function(ev)
    local game = ev.game
    local palettes = game.data.gen2Palettes
    game.data.field = game.data.field or {}
    game.data.field.boot = game.data.field.boot or {}
    game.data.field.boot.namePresets = {
      player = nameChoices
    }
    if palettes and palettes.trainers then
      palettes.trainers.CAL = nil
    end
  end)

  -- Crystal has a native gender-choice screen (Oak's Speech gets a
  -- "gender_select" step inserted whenever the sprite cache carries Kris
  -- data -- Gold/Silver never have that data, so they never get the step).
  -- Appearance here is meant to come entirely from the selected sprite
  -- folder, not a second, separate native choice, so this strips that step
  -- out unconditionally. It's a harmless no-op on Gen 1 and Gold/Silver,
  -- where the step never existed to begin with. With no choice made,
  -- gender defaults to "male" (Save.lua's own fallback), so SPRITE_CHRIS --
  -- already patched above -- is what actually displays either way. -Elvie
  -- --------------------------------------------------
  mod.hooks:wrap("intro.oak_speech.build", function(next, steps, speech)
    steps = next(steps, speech)
    return mod.ui.removeStep(steps, "gender_select")
  end)

  -- Title screen player. Gated on isGen2 for the same reason as the other
  -- field patches above. -Elvie
  -- ----------------------
  if not isGen2 then
    local titleVariant = frontSpriteVariants[mod.options:get("frontSprite")]
      and frontSpriteVariants[mod.options:get("frontSprite")]["dmg"]
    local titlePlayer = titleVariant and mod.assets:path(titleVariant.path)
      or mod.assets:path(SPRITES_DIR .. "/original/front.png")
    local krisEdition = mod.assets:path("assets/menus/krisEdition.png")
    mod.content.field:patch("boot", {
      title = {
        player = titlePlayer,
        versionRibbon = krisEdition,
      },
    })
  end

  -- Hands the resolved config back to main.lua so it can choose
  -- girlMode, nbMode, or neither. -Elvie
  -- --------------------------------------------------
  return {
    nameChoices = nameChoices,
    genderMode = genderMode,
  }

end

return kris
