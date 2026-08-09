local kris = {}

function kris.init(mod)


  local PaletteFX = require("src.render.PaletteFX")
  local originalSpriteObp = PaletteFX.spriteObp
  

  -- Define mod options
  -- ----------------------------------
  mod.options:define({
    {key = "battleSprite", type = "choice", label = "BATTLE SPRITE",
      choices = {{"ORIGINAL", "original"}, {"STADIUM - ARALE", "stadium"}}, default = "original"}
  })

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
  
  mod.content.field:patch("playerPics", {
    back = mod.assets:path("assets/crystalBack.png")
  })
  mod.content.battle_sprite_scales:register("hero_back", {
    path = mod.assets:path("assets/crystalBack.png"),
    scale = 1.0,
  })
  mod.content.battle_sprite_scales:register("hero_back_stadium", {
    path = mod.assets:path("assets/araleCrystalBack.png"),
    scale = 1.0,
  })

  -- Change sprite based on player's choice
  -- --------------------------------------
  mod.hooks:wrap("player.sprite", function(next, path, ctx)
    path = next(path, ctx)         
    if ctx.demo then return path end 
    if ctx.side ~= "back" then return path end

    local choice = mod.options:get("battleSprite")
    if choice == "stadium" then
      return mod.assets:path("assets/araleCrystalBack.png")
    end
    return path
  end)



  CRYSTAL_FISH_SIDE = mod.assets:path("assets/crystalFishSide.png")
  CRYSTAL_FISH_FRONT = mod.assets:path("assets/crystalFishFront.png")
  CRYSTAL_FISH_BACK = mod.assets:path("assets/crystalFishBack.png")

  mod.content.field:patch("overworldFx", {
  redFishSide  = { path = CRYSTAL_FISH_SIDE },
  redFishFront = { path = CRYSTAL_FISH_FRONT },
  redFishBack  = { path = CRYSTAL_FISH_BACK },
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
