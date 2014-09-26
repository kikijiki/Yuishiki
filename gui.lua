local Class = require "lib.middleclass"
local gui = {}

local Label = Class("Gui.Label")
gui.Label = Label

local Group = Class("Gui.Group")
gui.Group = Group

local sg = summon.graphics
local vec = summon.vec

local font_name = "ipamp.ttf"
local fonts = {}

function Label:initialize(text, x, y, color, font_size)
  self.text = text
  self.x = x or 0
  self.y = y or 0
  self.color = color or {255, 255, 255, 255}
  self.font_size = font_size or 20
  if not fonts[self.font_size] then
    fonts[self.font_size] = summon.AssetLoader.load("font", font_name.."@"..self.font_size)
  end
end

function Label:draw()
  sg.setColor(self.color)
  fonts[self.font_size]:apply()
  sg.print(self.text, self.x, self.y)
end

function Group:initialize(x, y)
  self.x = x or 0
  self.y = y or 0
  self.visible = true
  self.components = {}
end

function Group:add(component, name)
  if name then
    self.components[name] = component
    return name
  else
    table.insert(self.components, component)
    return #self.components
  end
end

function Group:draw()
  if not self.visible then return end
  if type(self.visible) == "function" and not self.visible() then return end
  
  sg.push()
  sg.translate(self.x, self.y)
  for _,c in pairs(self.components) do
    c:draw()
  end
  sg.pop()
end

function Group:update(dt)
  for _,c in pairs(self.components) do
    c:update(dt)
  end  
end

return gui