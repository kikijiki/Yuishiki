local gui = require "lib.quickie"
local summon = require "summon"()
local Scenario = require "game.scenario"
local sg = summon.graphics

local Menu = summon.class("Menu")

function Menu:initialize(scenarios)
  self.scenarios = scenarios
  self.logo = {}
  self.logo.texture = summon.AssetLoader.load("texture", "yuishiki_logo.png")
  self.logo.scale = .5
  self.logo.elapsed = 0
  self.logo.w = self.logo.texture.data:getWidth()
  self.logo.h = self.logo.texture.data:getHeight()
  self.fonts = {title = summon.AssetLoader.load("font", "ipamp.ttf@200")}
  self.elapsed = 0
end

function Menu:onResume()
  self:resize(sg.getDimensions())
  gui.keyboard.clearFocus()
end

function Menu:draw()
  sg.setBackgroundColor(40, 40, 40)
  fonts.title:apply()
  sg.setColor(0, 200, 255)
  sg.printf("YS", 0, self.title_spacing, self.w, "center")
  self:drawLogo()
  gui.core.draw()
end

function addScenario(menu, data)
  if gui.Button{
      text = data.name,
      size = {menu.btnw, menu.fonts.normal_size + menu.button_margin}}
  then
    menu.game:push(Scenario(data))
  end
end

function Menu:update(dt)
  self.elapsed = self.elapsed + dt

  gui.group{
    grow = "down",
    pos = {self.btnl, self.title_offset},
    spacing = self.spacing,
    function()
      self.fonts.normal:apply()
      for _,data in pairs(self.scenarios) do addScenario(self, data) end
    end
  }
end

function Menu:drawLogo()
  sg.setColor(255, 255, 255)
  local rot = math.pow((math.abs(math.sin(self.elapsed))), 0.4)
  sg.draw(self.logo.texture.data,
    self.w - self.logo.w * self.logo.scale/2 - 10,
    self.h - self.logo.h * self.logo.scale/2 - 10,
    0, self.logo.scale * rot, self.logo.scale, self.logo.w/2, self.logo.h/2)
 end

function Menu:keypressed(key)
  gui.keyboard.pressed(key)
end

function Menu:resize(w, h)
  self.w = w
  self.h = h
  local title_size = math.min(320, h / 4)
  self.title_spacing = title_size / 8
  self.title_offset = title_size + self.title_spacing * 2

  local entry_height = (h - self.title_offset) / #self.scenarios
  self.button_margin = entry_height / 10
  self.spacing = entry_height / 4
  local font_size = entry_height - self.spacing - self.button_margin * 2
  self.spacing = math.max(self.spacing, 1)
  font_size = math.max(font_size, 10)

  fonts = {}
  fonts.normal_size = font_size
  fonts.normal = summon.AssetLoader.load("font", "ipamp.ttf@"..font_size)
  fonts.title_size = title_size
  fonts.title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size)
  self.fonts = fonts

  local maxw = 0
  for _,v in pairs(self.scenarios) do
    maxw = math.max(maxw, fonts.normal:getWidth(v.name))
  end

  self.btnw = math.min(w, maxw * 1.5)
  self.btnl =(w - self.btnw) /  2
end

return Menu
