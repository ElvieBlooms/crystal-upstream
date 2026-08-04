return function(mod)


  local PaletteFX = require("src.render.PaletteFX")
  local originalSpriteObp = PaletteFX.spriteObp
  
  
  local CRYSTAL_COLORS = {
    {255, 255, 255},
    {255, 173, 99},
    {1, 99, 198},
    {0, 0, 0}
  }
  
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
  
end
