if os.time() > os.time({year = 2015, month = 4, day = 1}) then
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
local sg = summon.graphics

local signature_font = sg.newFont(20)

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
game:addLocale({"ja", "en", "it"})
game:setLocale("ja")

function love.load()
  console:resize(summon.graphics.getDimensions())

  local menu = require "game.menu"(scenarios)
  game:push(menu)

  if love.window.isTouchScreen and love.window.isTouchScreen() then
    local tid
    function love.touchpressed(id, x, y, pressure)
      if tid then return end
      tid = id
      local cx = x * love.graphics.getWidth()
      local cy = y * love.graphics.getHeight()
      if not console:mousepressed(cx, cy, "l") then
        game.on.mousepressed(cx, cy, "l")
      end
    end

    function love.touchreleased(id, x, y, pressure)
      if id ~= tid then return end
      tid = nil
      local cx = x * love.graphics.getWidth()
      local cy = y * love.graphics.getHeight()
      if not console:mousereleased(cx, cy, "l") then
        game.on.mousereleased(cx, cy, "l")
      end
    end

    function love.touchgestured(x, y, theta, distance, touchcount)
      local cx = x * love.graphics.getWidth()
      local cy = y * love.graphics.getHeight()
      game.on.touchgestured(cx, cy, theta, distance, touchcount)
    end

    function love.touchmoved(id, x, y)
      if id ~= tid then return end
      local cx = x * love.graphics.getWidth()
      local cy = y * love.graphics.getHeight()
      game.on.updateMouse(cx, cy)
    end

    function love.update(dt)
      game.on.update(dt)
    end
  else
    function love.mousepressed(x, y, button)
      if not console:mousepressed(x, y, button) then
        game.on.mousepressed(x, y, button)
      end
    end

    function love.mousereleased(x, y, button)
      if not console:mousereleased(x, y, button) then
        game.on.mousereleased(x, y, button)
      end
    end

    function love.update(dt)
      game.on.updateMouse(love.mouse.getPosition())
      game.on.update(dt)
    end
  end
end

function love.resize(w, h)
  console:resize(w, h)
  game.on.resize(w, h)
  local size = math.min(w, h)
  signature_font = sg.newFont(size / 50)
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
end

function love.draw()
  game.on.draw()
  console:draw()

  local w, h = sg.getDimensions()
  sg.setColor(0, 200, 200)
  sg.setFont(signature_font)
  local fh = signature_font:getHeight()
  summon.graphics.print("Bernacchia Matteo - 2015", fh/2, h - fh)
end
