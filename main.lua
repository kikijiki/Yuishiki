local gamestate = require "lib.hump.gamestate"
local timer = require "lib.hump.timer"
local console = require "lib.console"

require "yuishiki"
require "summon"

local sg = summon.graphics

ys.log.showTime = false
ys.log.showInfo = false
ys.log.verbosity = ys.log.Verbosity.verbose
-- ys.log.addRawOutput(console.i, false)

summon.log = ys.log

local scenarios_path = "assets/scenarios/"
local scenarios = {}

function love.load()
  summon.AssetLoader.register("character", "characters", require("character").load, false)
  summon.AssetLoader.register("aimod", "aimods", require("character").loadAiMod, false)
  gamestate.registerEvents({'keypressed', 'keyreleased', 'mousepressed', 'mousereleased', 'quit', 'resize', 'textinput', 'update' })

  summon.fs.getDirectoryItems(scenarios_path, function(file)
    local scenario = summon.fs.load(scenarios_path..file)()
    table.insert(scenarios, scenario)
  end)

  table.sort(scenarios, function(a, b) return a.name < b.title end)
  gamestate.switch(require "states.menu", scenarios)

  -- execute lua in the console
  --console.load(nil, nil, nil, function(t)
  --  local f = loadstring(t)
  --  print(pcall(f))
  --end)
  local luaprint = print
  print = function(...)
    local out = ""
    for _,v in pairs({...}) do out = out.."  "..tostring(v) end
    console.i(out)
    luaprint(...)
  end
end

function love.update(dt)
  timer.update(dt)
  console.update(dt)
end

function love.keypressed(key)
  if key == '`' then console.visible = not console.visible end

  if key == "escape" then
    love.event.quit()
  end

  if key == "f12" then
    local ss = love.graphics.newScreenshot()
    ss:encode("ss"..os.date("%Y%m%d%H%M%S")..".bmp", "bmp")
  end
end

function love.textinput(t)
    --if t ~= '`' then console.input = console.input .. t end
end

function love.mousepressed(x, y, button)
  if console.mousepressed(x, y, button) then
    return false
  end
  gamestate.mousepressed(x, y, button)
end

function love.draw()
  gamestate.draw()
  console.draw()
end
