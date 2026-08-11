local kris = {}

function kris.init(mod)


  local PaletteFX = require("src.render.PaletteFX")
  local originalSpriteObp = PaletteFX.spriteObp
  local advancedPack = assert(PaletteFX.gbcPack())
  

  -- Define mod options
  -- ----------------------------------
  mod.options:define({
    {
      key = "battleSprite", type = "choice", label = "BATTLE SPRITE",
        choices = {
      	  {"ORIGINAL", "original"},
	  {"STADIUM", "stadium"},
	  {"SYGNA", "sygna"},
	  {"SYGNA ZOOM", "sygnaZoom"},
	}, default = "original"
    },
    {
     key = "colorMode", type = "choice", label = "COLOR PALETTE",
       choices = {
         {"SGB COMPATIBLE", "sgb"},
	 {"FULL COLOR", "fullColor"}},
	 default = "sgb"}
  })

  local spriteVariants = {
    stadium = {
      sgb = { path = "assets/stadiumBack.png", trueColor = false},
      fullColor = { path = "assets/stadiumBackColor.png", trueColor = true,},
    },
    original = {
      sgb = {path = "assets/originalBack.png", trueColor = false},
      fullColor = {path = "assets/originalBackColor.png", trueColor = true},
    },
    sygna = {
      sgb = {path = "assets/sygnaBack.png", trueColor = false},
      fullColor = {path = "assets/sygnaBackColor.png", trueColor = true},
    },
    sygnaZoom = {
      sgb = {path = "assets/sygnaZoom.png", trueColor = false},
      fullColor = {path = "assets/sygnaZoomColor.png", trueColor = true},
    },
  }

  -- Assign player sprite based on mod options
  -- -----------------------------------------
  mod.hooks:wrap("player.sprite", function(next, path, ctx)
    path = next(path,ctx)
    if ctx.demo then return path end
    if ctx.side ~= "back" then return path end

    local battleSprite = mod.options:get("battleSprite")
    local colorMode = mod.options:get("colorMode")
    local variant = spriteVariants[battleSprite] and spriteVariants[battleSprite][colorMode]
    
    if variant then
      ctx.trueColor = variant.trueColor
      return mod.assets:path(variant.path)

    end
    return path
  end)

  -- Scale sprite
  -- ---------------------------------------------------
  for label, colorModes in pairs(spriteVariants) do
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
  
    
  -- Sprite replacements
  -- RED
  -- --------------------------
  mod.content.sprites:patch("SPRITE_RED", {
    image = mod.assets:path("assets/crystalPlayer.png"),
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  mod.content.sprites:patch("SPRITE_RED_BIKE", {
    image = mod.assets:path("assets/crystalBike.png"),
    trueColor = false,
    paletteSource = "PLAYER_PALETTE"
  })
  
  mod.content.field:patch("playerPics", {
    front = mod.assets:path("assets/crystalFront.png")
  })
  
  local CRYSTAL_FISH_SIDE = mod.assets:path("assets/crystalFishSide.png")
  local CRYSTAL_FISH_FRONT = mod.assets:path("assets/crystalFishFront.png")
  local CRYSTAL_FISH_BACK = mod.assets:path("assets/crystalFishBack.png")

  mod.content.field:patch("overworldFx", {
  redFishSide  = { path = CRYSTAL_FISH_SIDE },
  redFishFront = { path = CRYSTAL_FISH_FRONT },
  redFishBack  = { path = CRYSTAL_FISH_BACK },
})

  -- Sprite replacements
  -- GOLD
  -- -------------------------
  mod.content.sprites:patch("SPRITE_CHRIS", {
    image = mod.assets:path("assets/crystalPlayerColor.png"),
    trueColor = true,
  }) 

  mod.content.sprites:patch("SPRITE_CHRIS_BIKE", {
    image = mod.assets:path("assets/crystalBikeColor.png"),
    trueColor = true,
  })
  
  -- New game naming options
  -- ---------------------------
  mod.content.field:override("boot", {
    namePresets = {
      player = {"KRIS", "AMANDA", "JUANA", "JODI" }
    }
  })

  -- Title screen player
  -- ----------------------
  local titlePlayer = mod.assets:path("assets/crystalTitlePlayer.png")
  mod.content.field:patch("boot", {
    title = {player = titlePlayer},
  })


end

return kris
