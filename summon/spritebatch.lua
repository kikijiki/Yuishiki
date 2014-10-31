local SpriteBatch

local sprites = {}

return function(loader)
  if SpriteBatch then return SpriteBatch end
  local sg = loader.require "graphics"

  local SpriteBatch = {}

  local function zsort(a, b)
    return a.z > b.z
  end

  function SpriteBatch.clear()
    sprites = {}
    sg.setColor(255, 255, 255)
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
end
