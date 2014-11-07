local ys = require "yuishiki"()
local summon = require "summon"()

local gamestate = require "lib.hump.gamestate" --TODO: implement gamestate and remove hump.
local console = summon.Console()

-- Setup logging and console
ys.log.showTime = false
ys.log.showInfo = false
ys.log.verbosity = ys.log.Verbosity.verbose
ys.log.addOutput(function(data) console[data.severity](console, data.full) end)

summon.log.showTime = false
summon.log.showInfo = false
summon.log.verbosity = summon.log.Verbosity.verbose
summon.log.addOutput(function(data) console[data.severity](console, data.full) end)

-- Load scenarios data
local scenarios_path = "assets/scenarios/"
local scenarios = {}
summon.fs.getDirectoryItems(scenarios_path, function(file)
  local scenario = summon.fs.load(scenarios_path..file)()
  table.insert(scenarios, scenario)
end)
table.sort(scenarios, function(a, b) return a.name < b.name end)

function love.load()
  console:resize(summon.graphics.getDimensions())

  gamestate.registerEvents(
    {'keyreleased', 'mousereleased', 'quit', 'resize', 'update', 'textinput' })
  gamestate.switch(require "states.menu", scenarios)
end

function love.update(dt)
end

function love.resize(w, h)
  console:resize(w, h)
end

function love.keypressed(key)
  console:keypressed(key)

  if key == "escape" then love.event.quit() end

  if key == "f12" then
    local ss = love.graphics.newScreenshot()
    ss:encode("ss"..os.date("%Y%m%d%H%M%S")..".bmp", "bmp")
  end

  gamestate.keypressed(key)
end

function love.mousepressed(x, y, button)
  if not console:mousepressed(x, y, button) then
    gamestate.mousepressed(x, y, button)
  end
end

function love.draw()
  gamestate.draw()
  console:draw()
end
