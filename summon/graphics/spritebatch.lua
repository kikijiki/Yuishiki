assert(summon, "SUMMON is not loaded.")

local SpriteBatch = {}
local sprites = {}

local function zsort(a, b)
  return a.z > b.z
end

function SpriteBatch.clear()
  sprites = {}
  summon.graphics.setColor(255, 255, 255)
end

function SpriteBatch.add(sprite)
  table.insert(sprites, sprite)
end

function SpriteBatch.draw()
  table.sort(sprites, zsort)
  for _,v in pairs(sprites) do 
    v:draw()
  end
end

return SpriteBatch