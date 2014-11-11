local gui = require "lib.quickie"
local summon = require "summon"()
local Scenario = require "game.scenario"
local Gamestate = require "lib.hump.gamestate"

local state = {}
local scenarios = nil

local sg = summon.graphics

local logo = summon.AssetLoader.load("texture", "yuishiki_logo.png")
local logo_scale = .5
local elapsed = 0

local fonts = {
  title = summon.AssetLoader.load("font", "ipamp.ttf@200")
}

function state:init()

end

function state:enter(previous, s)
  scenarios = s
  state:resize(sg.getWidth(), sg.getHeight())
  gui.keyboard.clearFocus()
end

function state:leave()
end

function state:draw()
  local width = sg.getWidth()

  sg.setBackgroundColor(40, 40, 40)
  fonts.title:apply()
  sg.setColor(0, 200, 255)
  sg.printf("YS", 0, state.title_spacing, width, "center")
  self:drawLogo()
  gui.core.draw()
end

function addScenario(data)
  if gui.Button{text = data.name, size = {state.btnw, fonts.normal_size}} then
    Gamestate.push(Scenario(data))
  end
end

function state:update(dt)
  elapsed = elapsed + dt

  gui.group{grow = "down", pos = {state.btnl, state.title_offset}, spacing = state.spacing, function()
    fonts.normal:apply()
    for _,data in pairs(scenarios) do addScenario(data) end
  end}
end

function state:drawLogo()
  sg.setColor(255, 255, 255)
  local w, h = logo.data:getWidth(), logo.data:getHeight()
  local rot = math.pow((math.abs(math.sin(elapsed))), 0.4)
  sg.draw(logo.data,
    sg.getWidth() - w * logo_scale/2 - 10,
    sg.getHeight() - h * logo_scale/2 - 10,
    0, logo_scale * rot, logo_scale, w/2, h/2)
 end

function state:keypressed(key)
  gui.keyboard.pressed(key)
end

function state:mousepressed(x, y, button)
end

function state:resize(w, h)
  local title_size = math.min(320, h / 4)
  state.title_spacing = title_size / 8
  state.title_offset = title_size + state.title_spacing * 2

  local entry_height = (h - state.title_offset) / #scenarios
  state.spacing = entry_height / 4
  local font_size = entry_height - state.spacing
  state.spacing = math.max(state.spacing, 1)
  font_size = math.max(font_size, 10)

  fonts.normal_size = font_size
  fonts.normal = summon.AssetLoader.load("font", "ipamp.ttf@"..font_size)
  fonts.title_size = title_size
  fonts.title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size)

  local maxw = 0
  for _,v in pairs(scenarios) do
    maxw = math.max(maxw, fonts.normal:getWidth(v.name))
  end

  state.btnw = math.min(w, maxw * 1.5)
  state.btnl =(w - state.btnw) /  2
end

return state;
