return function(mod)
  local kris = require("mods.crystal.kris")
  local girlMode = require("mods.crystal.girlMode")
  local credits = require("mods.crystal.credits")

  kris.init(mod)
  girlMode.init(mod)
  credits.init(mod)

end
