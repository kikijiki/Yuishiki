assert(summon, "SUMMON is not loaded.")

local newFont = summon.graphics.newFont
local setFont = summon.graphics.setFont

local Font = summon.class("Font")

function Font:initialize(path, size)
  self.data = newFont(path, size)
end

function Font.load(path)
  local s = summon.uti.split(path, "@")
  return Font(s[1], tonumber(s[2]))
end

function Font:getHeight()
  return self.data:getHeight()
end

function Font:apply()
  setFont(self.data)
end

function Font:getWidth(s)
  return self.data:getWidth(s)
end

return Font