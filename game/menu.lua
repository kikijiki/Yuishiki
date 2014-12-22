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
  self.fonts = {
    title = summon.AssetLoader.load("font", "ipamp.ttf@200"),
    ui    = summon.AssetLoader.load("font", "ipamp.ttf@60"),
    small = summon.AssetLoader.load("font", "ipamp.ttf@36"),
  }

  self.keys = {
    en = {
      "Esc -> toggle fullscreen",
      "Space -> next turn"
    },
    ja = {
      "Esc -> フルスクリーンの切り替え",
      "Space -> 次のターン"
    }
  }

  self.elapsed = 0
end

function Menu:onPush(game, prev)
  self.game = game
end

function Menu:onResume()
  self:resize(sg.getDimensions())
  gui.keyboard.clearFocus()
end

function Menu:draw()
  local locale = self.game.locale

  sg.setBackgroundColor(40, 40, 40)

  self.fonts.title:apply()
  sg.setColor(0, 200, 255)
  sg.printf("YS", 0, self.title_spacing, self.w, "center")

  self.fonts.small:apply()
  local margin = self.title_offset / 2 - self.fonts.ui_size
  margin = (margin - self.fonts.small_size) / 2
  sg.print(self.keys[locale][1], margin, margin)

  self:drawLogo()
  gui.core.draw()
end

function addScenario(menu, data, locale)
  if gui.Button{
      text = data.name[locale],
      size = {menu.w, menu.button_height}}
  then
    menu.game:push(Scenario(data))
  end
end

function Menu:update(dt)
  self.elapsed = self.elapsed + dt

  local locale = self.game.locale
  local margin = self.title_offset / 2 - self.fonts.ui_size

  self.fonts.ui:apply()
  if gui.Button{
      text = locale,
      pos = {margin, margin},
      size = {self.fonts.ui_size * 2, self.fonts.ui_size * 2}
    }
  then
    if love.system.vibrate then love.system.vibrate(0.2) end
    self.game.locale = (self.game.locale == "ja") and "en" or "ja"
    self:resize()
  end

  gui.group{
    grow = "down",
    pos = {0, self.title_offset},
    spacing = self.spacing,
    function()
      self.fonts.normal:apply()
      for _,data in pairs(self.scenarios) do addScenario(self, data, locale) end
    end
  }
end

function Menu:drawLogo()
  sg.setColor(255, 255, 255)
  local rot = math.pow((math.abs(math.sin(self.elapsed))), 0.4)
  local x = self.w - self.logo.w * self.logo.scale/2 - 10
  local y = self.title_offset / 2
  sg.draw(self.logo.texture.data, x, y, 0, self.logo.scale * rot, self.logo.scale, self.logo.w/2, self.logo.h/2)
 end

function Menu:keypressed(key)
  gui.keyboard.pressed(key)
end

function Menu:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end

  self.w = w
  self.h = h
  local title_size = math.min(320, h / 4)
  self.title_spacing = title_size / 8
  self.title_offset = title_size + self.title_spacing * 2
  self.logo.scale = title_size / self.logo.h / 2

  self.entry_height = (h - self.title_offset) / #self.scenarios
  self.button_height = self.entry_height / 4 * 3
  self.button_margin = self.entry_height / 10
  self.spacing = self.entry_height / 4
  local font_size = self.entry_height - self.spacing - self.button_margin * 2
  self.spacing = math.max(self.spacing, 1)
  font_size = math.max(font_size, 10)

  local fonts = {}
  fonts.normal_size = font_size
  fonts.normal = summon.AssetLoader.load("font", "ipamp.ttf@"..font_size)
  fonts.title_size = title_size
  fonts.title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size)
  fonts.ui_size = title_size / 3
  fonts.ui = summon.AssetLoader.load("font", "ipamp.ttf@"..fonts.ui_size)
  fonts.small_size = fonts.ui_size / 3
  fonts.small = summon.AssetLoader.load("font", "ipamp.ttf@"..fonts.small_size)
  self.fonts = fonts
end

return Menu
