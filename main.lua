if os.time() > os.time({year = 2015, month = 2, day = 1}) then
  local x, y = 0, 0
  local w = love.graphics.getWidth()
  local c = love.graphics.newCanvas()
  local fs = 30
  local font = love.graphics.newFont(fs)
  love.graphics.setFont(font)
  local text = "EXPIRED "
  local tw = font:getWidth(text)
  love.draw = function()
    love.graphics.setCanvas(c)
    love.graphics.print(text, x, y)
    x = x + tw
    if x > w then
      x, y = 0, y + fs
    end
    love.graphics.setCanvas()
    love.graphics.draw(c)
  end
  return
end

local ys = require "yuishiki"()
local summon = require "summon"()

-- Setup logging and console
console = summon.Console(1, 1)

ys.log.showTime = false
ys.log.showInfo = false
ys.log.verbosity = ys.log.Verbosity.debug
ys.log.addOutput(
  function(data) console[data.severity](console, data.full) end)

summon.log.showTime = false
summon.log.showInfo = false
summon.log.verbosity = summon.log.Verbosity.debug
summon.log.addOutput(
  function(data) console[data.severity](console, data.full) end)

print = function(...) summon.log.d("PRN", ...) end

-- Load scenarios data
local scenarios_path = "assets/scenarios/"
local scenarios = {}
summon.fs.getDirectoryItems(scenarios_path, function(file)
  local scenario = summon.fs.load(scenarios_path..file)()
  table.insert(scenarios, scenario)
end)

local game = summon.Game()
game.locale = "ja"

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
  if console:keypressed(key) then return end

  if key == "escape" then
    love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
  end

  if key == "1" then
    if ys.log.verbosity == ys.log.Verbosity.debug then
      ys.log.verbosity = ys.log.Verbosity.all
      print("all")
    else
      ys.log.verbosity = ys.log.Verbosity.debug
      print("debug")
    end
  end

  if key == "f12" then
    local ss = love.graphics.newScreenshot()
    ss:encode("ss"..os.date("%Y%m%d%H%M%S")..".bmp", "bmp")
  end

  game.on.keypressed(key)
end

function love.keyreleased(key)
  game.on.keyreleased(key)

  if key == "delete" then
    console:clear()
  end
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
