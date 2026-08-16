local kris = {}

function kris.init(mod)


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
  -- ------------------------------------------
  local CRYSTAL_COLORS = {
    {255, 255, 255},
    {255, 173, 99},
    {1, 99, 198},
    {0, 0, 0}
  }
  
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

  -- Same rendering interception but for Gen 2
  -- -----------------------------------------
  mod.events:on("game.ready", function(ev)
    local palettes = require("src.world.gen2.Palettes")
    local originalSpritePalette = palettes.spritePalette

    palettes.spritePalette = function(data, daytime, spriteDef, objDef)
      if spriteDef and spriteDef.paletteSource == "PLAYER_PALETTE" then
        return CRYSTAL_COLORS
      end
      return originalSpritePalette(data, daytime, spriteDef, objDef)
    end
  end)
  
    
  -- Sprite replacements
  -- RED
  -- --------------------------
  mod.content.sprites:patch("SPRITE_RED", {
    image = mod.assets:path("assets/overworld/crystalPlayer.png"),
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  mod.content.sprites:patch("SPRITE_RED_BIKE", {
    image = mod.assets:path("assets/overworld/crystalBike.png"),
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  mod.content.field:patch("playerPics", {
    front = mod.assets:path(SPRITES_DIR .. "/original/front.png")
  })


  local CRYSTAL_FISH_SIDE = mod.assets:path("assets/overworld/crystalFishSide.png")
  local CRYSTAL_FISH_FRONT = mod.assets:path("assets/overworld/crystalFishFront.png")
  local CRYSTAL_FISH_BACK = mod.assets:path("assets/overworld/crystalFishBack.png")

  mod.content.field:patch("overworldFx", {
    redFishSide  = { path = CRYSTAL_FISH_SIDE },
    redFishFront = { path = CRYSTAL_FISH_FRONT },
    redFishBack  = { path = CRYSTAL_FISH_BACK },
  })

  -- Sprite replacements
  -- GOLD
  -- -------------------------
  mod.content.sprites:patch("SPRITE_CHRIS", {
    image = mod.assets:path("assets/overworld/crystalPlayer.png"),
    trueColor = false,
    paletteSource = "PLAYER_PALETTE",
  }) 

  mod.content.sprites:patch("SPRITE_CHRIS_BIKE", {
    image = mod.assets:path("assets/overworld/crystalBike.png"),
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
  -- ---------------------------
  mod.content.field:override("boot", {
    namePresets = {
      player = {"KRIS", "AMANDA", "JUANA", "JODI" }
    }
  })
  
  -- Gen 2 Naming options and forcing true color of player sprite.
  -- This can likely be reduced when the field registry is
  -- hooked into gen 2 via the mod api.
  -- --------------------------------------------------
  mod.events:on("game.ready", function(ev)
    local game = ev.game
    local palettes = game.data.gen2Palettes
    game.data.field = game.data.field or {}
    game.data.field.boot = game.data.field.boot or {}
    game.data.field.boot.namePresets = {
      player = {"KRIS", "AMANDA", "JUANA", "JODI"}
    }
    if palettes and palettes.trainers then
      palettes.trainers.CAL = nil
    end
  end)

  -- Title screen player
  -- ----------------------
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

return kris
