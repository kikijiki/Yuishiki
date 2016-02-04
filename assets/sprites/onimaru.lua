return {
  spritesheet = "onimaru.lua",
  scale = 2.0,
  animations = {
    ["idle"] = {
      directions = true,
      frames = {
        {NE = "idle NE 1", NW = "idle NW 1", SE = "idle SE 1", SW = "idle SW 1", dt = 400},
        {NE = "idle NE 2", NW = "idle NW 2", SE = "idle SE 2", SW = "idle SW 2", dt = 400},
        {NE = "idle NE 3", NW = "idle NW 3", SE = "idle SE 3", SW = "idle SW 3", dt = 400},
        {NE = "idle NE 4", NW = "idle NW 4", SE = "idle SE 4", SW = "idle SW 4", dt = 400},
        {NE = "idle NE 5", NW = "idle NW 5", SE = "idle SE 5", SW = "idle SW 5", dt = 400},
      }
    },

    ["walk"] = {
      directions = true,
      frames = {
        {NE = "walk NE 1", NW = "walk NW 1", SE = "walk SE 1", SW = "walk SW 1", dt = 100},
        {NE = "walk NE 2", NW = "walk NW 2", SE = "walk SE 2", SW = "walk SW 2", dt = 200},
        {NE = "walk NE 3", NW = "walk NW 3", SE = "walk SE 3", SW = "walk SW 3", dt = 200},
        {NE = "walk NE 4", NW = "walk NW 4", SE = "walk SE 4", SW = "walk SW 4", dt = 200},
        {NE = "walk NE 5", NW = "walk NW 5", SE = "walk SE 5", SW = "walk SW 5", dt = 100},
      }
    },

    ["jump"] = {
      directions = true,
      frames = {
        {NE = "skill NE 2", NW = "skill NW 2", SE = "skill SE 2", SW = "skill SW 2", dt = 0}
      }
    },

    ["skill"] = {
      directions = true,
      loops = 1,
      frames = {
        {NE = "skill NE 1", NW = "skill NW 1", SE = "skill SE 1", SW = "skill SW 1", dt = 300},
        {NE = "skill NE 2", NW = "skill NW 2", SE = "skill SE 2", SW = "skill SW 2", dt = 300}
      }
    },

    ["item"] = {
      directions = true,
      loops = 1,
      frames = {
        {NE = "skill NE 1", NW = "skill NW 1", SE = "skill SE 1", SW = "skill SW 1", dt = 300},
        {NE = "skill NE 2", NW = "skill NW 2", SE = "skill SE 2", SW = "skill SW 2", dt = 300}
      }
    },

    ["attack"] = {
      directions = true,
      loops = 1,
      tags = { hit = 3 },
      frames = {
        {NE = "attack NE 1", NW = "attack NW 1", SE = "attack SE 1", SW = "attack SW 1", dt = 100},
        {NE = "attack NE 2", NW = "attack NW 2", SE = "attack SE 2", SW = "attack SW 2", dt = 100},
        {NE = "attack NE 3", NW = "attack NW 3", SE = "attack SE 3", SW = "attack SW 3", dt = 100},
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt = 100},
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt = 100},
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt = 100},
      }
    },

    ["rengiri"] = {
      directions = true,
      loops = 1,
      tags = { hit1 = 4, hit2 = 7, hit3 = 10, hit4 = 13 },
      frames = {
        {NE = "attack NE 1", NW = "attack NW 1", SE = "attack SE 1", SW = "attack SW 1", dt = 100}, -- 1
        {NE = "attack NE 2", NW = "attack NW 2", SE = "attack SE 2", SW = "attack SW 2", dt = 100}, -- 2
        {NE = "attack NE 3", NW = "attack NW 3", SE = "attack SE 3", SW = "attack SW 3", dt = 100}, -- 3
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt =  50}, -- 4
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt =  50}, -- 5
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt =  50}, -- 6
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt =  50}, -- 7
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt =  50}, -- 8
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt =  50}, -- 9
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt =  50}, --10
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt =  50}, --11
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt =  50}, --12
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt =  50}, --13
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt =  50}, --14
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt =  50}, --15
      }
    },

    ["daikyougeki"] = {
      directions = true,
      loops = 1,
      tags = { hit = 4 },
      frames = {
        {NE =  "skill NE 1", NW =  "skill NW 1", SE =  "skill SE 1", SW =  "skill SW 1", dt = 300},
        {NE =  "skill NE 2", NW =  "skill NW 2", SE =  "skill SE 2", SW =  "skill SW 2", dt = 300},
        {NE = "attack NE 3", NW = "attack NW 3", SE = "attack SE 3", SW = "attack SW 3", dt = 100},
        {NE = "attack NE 4", NW = "attack NW 4", SE = "attack SE 4", SW = "attack SW 4", dt = 100},
        {NE = "attack NE 5", NW = "attack NW 5", SE = "attack SE 5", SW = "attack SW 5", dt = 100},
        {NE = "attack NE 6", NW = "attack NW 6", SE = "attack SE 6", SW = "attack SW 6", dt = 200},
      }
    },

    ["hit"] = {
      directions = true,
      loops = 1,
      frames = {
        {NE = "hit NE", NW = "hit NW", SE = "hit SE", SW = "hit SW", dt = 400},
      }
    },

    ["dead"] = {
      directions = true,
      loops = 1,
      frames = {
        {NE = "hit NE", NW = "hit NW", SE = "hit SE", SW = "hit SW", dt = 400},
      }
    }
  }
}
