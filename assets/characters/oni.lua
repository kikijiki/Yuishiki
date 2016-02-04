return
{
  name = {
    en = "Oni",
    ja = "鬼",
    it = "Oni"
  },
  sprite = "oni.lua",
  modules = {
    {"race-oni"},
    {"class-fighter", 1}
  },
  equipment = {
    weapon = "oni-club",
    armor  = "oni-armor"
  },
  ai = {
    modules = {
      "basic-module.lua"
    },
    sensors = {
      ["position"]   = "position.lua",
      ["appearance"] = "appearance.lua",
      ["health"]     = "health.lua",
      ["hearing"]    = "hearing.lua",
      ["faction"]    = "faction.lua"
    }
  },
}
