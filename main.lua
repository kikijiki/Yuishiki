local ys = require "yuishiki"()
local summon = require "summon"()
local console = summon.Console()

-- Setup logging and console
ys.log.showTime = false
ys.log.showInfo = false
ys.log.verbosity = ys.log.Verbosity.verbose
ys.log.addOutput(function(data) console[data.severity](console, data.full) end)

summon.log.showTime = false
summon.log.showInfo = false
summon.log.verbosity = summon.log.Verbosity.verbose
summon.log.addOutput(
  function(data) console[data.severity](console, data.full) end)

-- Load scenarios data
local scenarios_path = "assets/scenarios/"
local scenarios = {}
summon.fs.getDirectoryItems(scenarios_path, function(file)
  local scenario = summon.fs.load(scenarios_path..file)()
  table.insert(scenarios, scenario)
end)
table.sort(scenarios, function(a, b) return a.name < b.name end)

local game = summon.Game()

function love.load()
  console:resize(summon.graphics.getDimensions())

  local menu = require "game.menu"(scenarios)
  game:push(menu)
end

function love.update(dt)
  game.on.update(dt)
end

function love.resize(w, h)
  console:resize(w, h)
  game.on.resize(w, h)
end

function love.keypressed(key)
  console:keypressed(key)

  if key == "escape" then love.event.quit() end

  if key == "f12" then
    local ss = love.graphics.newScreenshot()
    ss:encode("ss"..os.date("%Y%m%d%H%M%S")..".bmp", "bmp")
  end

  game.on.keypressed(key)
end

function love.keyreleased(key)
  game.on.keyreleased(key)
end

function love.mousepressed(x, y, button)
  if not console:mousepressed(x, y, button) then
    game.on.mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  game.on.mousereleased(x, y, button)
end

function love.draw()
  game.on.draw()
  console:draw()
end
