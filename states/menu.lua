local gui = require "lib.quickie"
local summon = require "summon"()
local Scenario = require "states.scenario"
local Gamestate = require "lib.hump.gamestate"

local state = {}
local scenarios = nil

local sg = summon.graphics

local logo = summon.AssetLoader.load("texture", "yuishiki_logo.png")
local logo_scale = .5
local elapsed = 0

local font = {
  normal = summon.AssetLoader.load("font", "ipamp.ttf@60"),
  title = summon.AssetLoader.load("font", "ipamp.ttf@200")
}

function state:init()
end

function state:enter(previous, s)
  scenarios = s
  gui.keyboard.clearFocus()
end

function state:leave()
end

function state:draw()
  local width = sg.getWidth()

  sg.setBackgroundColor(40, 40, 40)
  font.title:apply()
  sg.setColor(0, 200, 255)
  sg.printf("評価実験", 0, 60, width, "center")
  self:drawLogo()
  gui.core.draw()
end

function addScenario(data, width)
  if gui.Button{text = data.name, size = {width, 100}} then
    Gamestate.push(Scenario(data))
  end
end

function state:update(dt)
  elapsed = elapsed + dt

  local width, height = sg.getDimensions()
  gui.group{grow = "down", pos = {0, 320}, spacing = 20, function()
    font.normal:apply()
    for _,data in pairs(scenarios) do addScenario(data, width) end
  end}
end

function state:drawLogo()
  sg.setColor(255, 255, 255)
  local w, h = logo.data:getWidth(), logo.data:getHeight()
  local rot = math.pow((math.abs(math.sin(elapsed))), 0.4)
  sg.draw(logo.data,
    sg.getWidth() - w*logo_scale/2 - 10,
    sg.getHeight() - h*logo_scale/2 - 10,
    0, logo_scale * rot, logo_scale, w/2, h/2)
 end

function state:keypressed(key)
  gui.keyboard.pressed(key)
end

function state:mousepressed(x, y, button)
end

return state;
