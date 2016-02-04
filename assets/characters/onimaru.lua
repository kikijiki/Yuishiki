return
{
  name = {
    en = "Onimaru",
    ja = "オニマル",
    it = "Onimaru"
  },
  sprite = "onimaru.lua",
  modules = {
    {"race-human"},
    {"class-ninja", 5}
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
