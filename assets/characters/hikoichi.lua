return
{
  name = {
    en = "Hikoichi",
    ja = "ヒコイチ",
    it = "Hikoichi",
  },
  sprite = "hikoichi.lua",
  modules = {
    {"race-human"},
    {"class-ninja", 4}
  },
  equipment = {
    weapon = "katana",
    armor  = "ninja-armor"
  },
  ai = {
    modules = {
      "basic-module.lua",
      "communication.lua",
      "protect.lua",
      "ninja.lua"
    },
    sensors = {
      ["position"]   = "position.lua",
      ["appearance"] = "appearance.lua",
      ["health"]     = "health.lua",
      ["equipment"]  = "equipment.lua",
      ["hearing"]    = "hearing.lua",
      ["faction"]    = "faction.lua"
    }
  },
}
