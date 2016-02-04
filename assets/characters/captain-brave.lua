return
{
  name = {
    en = "Captain",
    ja = "隊長",
    it = "Capitano",
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
      "ninja.lua",
      "captain.lua",
      "captain-brave.lua"
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
