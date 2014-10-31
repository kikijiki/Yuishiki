local Texture

return function(loader)
  if Texture then return Texture end

  local sg = loader.require "graphics"
  local newImage = sg.newImage

  Texture = loader.class("Texture")

  function Texture:initialize(data)
    self.data = data
    self.filter = {min = "linear", mag = "nearest"}
  end

  function Texture.static.load(path)
    local tex = Texture(newImage(path))
    return tex
  end

  function Texture:reload(path)
    self.data = newImage(path)
    self:setFilter()
  end

  function Texture:getWidth()
    return self.data:getWidth()
  end

  function Texture:getHeight()
    return self.data:getHeight()
  end

  function Texture:setFilter(min, mag)
    self.filter.min = min or self.filter.min
    self.filter.mag = mag or self.filter.mag
    self.data:setFilter(self.filter.min, self.filter.mag)
  end

  return Texture
end
