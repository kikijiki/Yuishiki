local Font

return function(loader)
  if Font then return Font end

  local sg = loader.require "graphics"
  local Uti = loader.load "uti"

  Font = loader.class("Font")

  function Font:initialize(path, size)
    self.data = sg.newFont(path, size)
  end

  function Font.load(path)
    local s = Uti.split(path, "@")
    return Font(s[1], tonumber(s[2]))
  end

  function Font:getHeight()
    return self.data:getHeight()
  end

  function Font:apply()
    sg.setFont(self.data)
  end

  function Font:getWidth(s)
    return self.data:getWidth(s)
  end

  function Font:getWrap(s, w)
    return self.data:getWrap(s, w)
  end

  return Font
end
