return function(mod)


  local PaletteFX = require("src.render.PaletteFX")
  local originalSpriteObp = PaletteFX.spriteObp
  local field = require("data.generated.field")

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
    front = mod.assets:path("assets/crystalFront.png"),
    back = mod.assets:path("assets/crystalBack.png")
  })

  mod.content.battle_sprite_scales:register("hero_back", {
    path = mod.assets:path("assets/crystalBack.png"),
    scale = 1.0,
  })

  CRYSTAL_FISH_SIDE = mod.assets:path("assets/crystalFishSide.png")
  CRYSTAL_FISH_FRONT = mod.assets:path("assets/crystalFishFront.png")
  CRYSTAL_FISH_BACK = mod.assets:path("assets/crystalFishBack.png")
  
  if field.overworldFx.redFishSide then
    field.overworldFx.redFishSide.path = CRYSTAL_FISH_SIDE
  end

  if field.overworldFx.redFishFront then
    field.overworldFx.redFishFront.path = CRYSTAL_FISH_FRONT
  end

  if field.overworldFx.redFishBack then
    field.overworldFx.redFishBack.path = CRYSTAL_FISH_BACK
  end

  return field

end
