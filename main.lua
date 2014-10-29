--require "CiderDebugger";

local gamestate = require "lib.hump.gamestate"
local timer = require "lib.hump.timer"
local console = require "console".new()

local ys = require "yuishiki"()
require "summon"

-- Setup logging and console
ys.log.showTime = false
ys.log.showInfo = false
ys.log.verbosity = ys.log.Verbosity.verbose
ys.log.addOutput(function(data) console[data.tag](console, data.msg) end)

summon.log = ys.log

-- Setup assets
local scenarios_path = "assets/scenarios/"
local scenarios = {}

summon.AssetLoader.register("character", "characters", summon.AssetLoader.loadRaw, false)
summon.AssetLoader.register("ai_module", "ai/modules", summon.AssetLoader.loadRaw, false)
summon.AssetLoader.register("sensor", "ai/sensors", require"sensor".load, false)

function love.load()
  gamestate.registerEvents({'keyreleased', 'mousereleased', 'quit', 'resize', 'update' })

  summon.fs.getDirectoryItems(scenarios_path, function(file)
    local scenario = summon.fs.load(scenarios_path..file)()
    table.insert(scenarios, scenario)
  end)

  table.sort(scenarios, function(a, b) return a.name < b.name end)
  gamestate.switch(require "states.menu", scenarios)
  console:resize(love.graphics.getDimensions())
end

function love.update(dt)
  timer.update(dt)
end

function love.resize(w, h)
  console:resize(w, h)
end

function love.keypressed(key)
  console:keypressed(key)

  if key == "escape" then
    love.event.quit()
  end

  if key == "f12" then
    local ss = love.graphics.newScreenshot()
    ss:encode("ss"..os.date("%Y%m%d%H%M%S")..".bmp", "bmp")
  end

  gamestate.keypressed(key)
end

function love.textinput(t)
  gamestate.textinput(t)
end

function love.mousepressed(x, y, button)
  if console:mousepressed(x, y, button) then return false end
  gamestate.mousepressed(x, y, button)
end

function love.draw()
  gamestate.draw()
  console:draw()
end
