return {
  spritesheet = "oni.lua",
  scale = 2.0,
  animations = {
    ["idle"] = {
      directions = true,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "idle NE 1", SW = "idle SW 1", dt = 300},
        {NE = "idle NE 2", SW = "idle SW 2", dt = 300},
        {NE = "idle NE 3", SW = "idle SW 3", dt = 300},
        {NE = "idle NE 2", SW = "idle SW 2", dt = 300}
      }
    },

    ["walk"] = {
      directions = true,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "walk NE 1", SW = "walk SW 1", dt = 300},
        {NE = "walk NE 2", SW = "walk SW 2", dt = 300},
        {NE = "walk NE 3", SW = "walk SW 3", dt = 300},
        {NE = "walk NE 2", SW = "walk SW 2", dt = 300},
      }
    },

    ["attack"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      tags = {hit = 4},
      frames = {
        {NE = "attack NE 1", SW = "attack SW 1", dt = 150},
        {NE = "attack NE 2", SW = "attack SW 2", dt = 150},
        {NE = "attack NE 3", SW = "attack SW 3", dt = 100},
        {NE = "attack NE 4", SW = "attack SW 4", dt = 100},
        {NE = "attack NE 5", SW = "attack SW 5", dt = 100},
        {NE = "attack NE 6", SW = "attack SW 6", dt = 200},
      }
    },

    ["hit"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "hit NE", SW = "hit SW", dt = 400},
      }
    },

    ["dead"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "hit NE", SW = "hit SW", dt = 400},
      }
    }
  }
}
