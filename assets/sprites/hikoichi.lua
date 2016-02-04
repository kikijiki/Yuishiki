return {
  spritesheet = "hikoichi.lua",
  scale = 2.0,
  animations = {
    ["idle"] = {
      directions = true,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "idle NE 1", SW = "idle SW 1", dt = 500},
        {NE = "idle NE 2", SW = "idle SW 2", dt = 500},
        {NE = "idle NE 3", SW = "idle SW 3", dt = 500},
        {NE = "idle NE 2", SW = "idle SW 2", dt = 500}
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

    ["jump"] = {
      directions = true,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "skill NE 3", SW = "skill SW 3", dt = 0}
      }
    },

    ["skill"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "skill NE 1", SW = "skill SW 1", dt = 300},
        {NE = "skill NE 2", SW = "skill SW 2", dt = 300},
        {NE = "skill NE 3", SW = "skill SW 3", dt = 300},
      }
    },

    ["item"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      frames = {
        {NE = "skill NE 1", SW = "skill SW 1", dt = 300},
        {NE = "skill NE 2", SW = "skill SW 2", dt = 300},
        {NE = "skill NE 3", SW = "skill SW 3", dt = 300},
      }
    },

    ["attack"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      tags = { hit = 3 },
      frames = {
        {NE = "attack NE 1", SW = "attack SW 1", dt = 100},
        {NE = "attack NE 2", SW = "attack SW 2", dt = 100},
        {NE = "attack NE 3", SW = "attack SW 3", dt = 100},
        {NE = "attack NE 4", SW = "attack SW 4", dt = 100},
        {NE = "attack NE 5", SW = "attack SW 5", dt = 100},
        {NE = "attack NE 6", SW = "attack SW 6", dt = 100},
      }
    },

    ["rengiri"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      tags = { hit1 = 4, hit2 = 7, hit3 = 10, hit4 = 13 },
      frames = {
        {NE = "attack NE 1", SW = "attack SW 1", dt = 100}, -- 1
        {NE = "attack NE 2", SW = "attack SW 2", dt = 100}, -- 2
        {NE = "attack NE 3", SW = "attack SW 3", dt = 100}, -- 3
        {NE = "attack NE 4", SW = "attack SW 4", dt =  50}, -- 4
        {NE = "attack NE 5", SW = "attack SW 5", dt =  50}, -- 5
        {NE = "attack NE 6", SW = "attack SW 6", dt =  50}, -- 6
        {NE = "attack NE 4", SW = "attack SW 4", dt =  50}, -- 7
        {NE = "attack NE 5", SW = "attack SW 5", dt =  50}, -- 8
        {NE = "attack NE 6", SW = "attack SW 6", dt =  50}, -- 9
        {NE = "attack NE 4", SW = "attack SW 4", dt =  50}, --10
        {NE = "attack NE 5", SW = "attack SW 5", dt =  50}, --11
        {NE = "attack NE 6", SW = "attack SW 6", dt =  50}, --12
        {NE = "attack NE 4", SW = "attack SW 4", dt =  50}, --13
        {NE = "attack NE 5", SW = "attack SW 5", dt =  50}, --14
        {NE = "attack NE 6", SW = "attack SW 6", dt =  50}, --15
      }
    },

    ["daikyougeki"] = {
      directions = true,
      loops = 1,
      mirror = {["NW"] = "NE", ["SE"] = "SW"},
      tags = { hit = 4 },
      frames = {
        {NE =  "skill NE 2", SW =  "skill SW 2", dt = 300},
        {NE =  "skill NE 3", SW =  "skill SW 3", dt = 300},
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
