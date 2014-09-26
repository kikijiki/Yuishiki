local Class = require "lib.middleclass"
local Stage = Class("Stage")

local BattleInterface = require "battle-interface"
local EventDispatcher = require "event-dispatcher"
local World = require "world"
local GM = require "gm"

local sg = summon.graphics
local vec = summon.vec

function Stage:initialize(data, characters)
  local map = summon.AssetLoader.load("map", data.map)
  self.world = World(map)
  self.gm = GM(self.world)
  self.camera = sg.Camera()
  self.interface = BattleInterface(self)
  self.dispatcher = EventDispatcher()
  self.mouse = vec()

  local path = summon.AssetLoader.getAssetPath("ruleset").."/"..data.rules.."/"
  summon.fs.getDirectoryItems(path, function(file)
    local ruleset = summon.fs.load(path..file)()
    self.gm:loadRules(ruleset)
  end)

  for _,char in pairs(data.characters) do
    self.gm:addCharacter(characters[char], char)
  end
  
  if data.init then data.init(self, self.world, self.world.characters) end
  self.gm:start()
  self.gm:nextTurn()
end

function Stage:resize(w, h)
  self.width = w
  self.height = h
  self.camera:resize(w, h)
  self.canvas = sg.newCanvas(w, h)
  self.dispatcher:dispatch("resize", w, h)
end

function Stage:draw()
  sg.push()
  sg.origin()
  self.camera:begin()
  self.canvas:clear()
  sg.setCanvas(self.canvas)
  sg.SpriteBatch.clear()

  self.world:draw()
  sg.SpriteBatch.draw()
  self.interface:drawCursor()

  self.camera:finish()
  self.interface:draw()
  sg.setCanvas()
  sg.pop()
  sg.draw(self.canvas)
end

function Stage:update(dt)
  self.gm:update(dt)
  self.camera:update(dt, self.mouse)
  if self.gm.activeCharacter then
    self.interface:setCursor(
      self.gm.activeCharacter.sprite:getTag("camera"))
  end
  self.interface:update(dt)
end

function Stage:keypressed(key)
  if key == "return" then
    local char = self.gm:nextCharacter()
    if not char then
      self.gm:nextTurn()
      char = self.gm:nextCharacter()
    end
    if char then 
      self.camera:follow(char.sprite)
    end
  end
  
  if key == " " and self.gm.activeCharacter then
    --self.gm.activeCharacter:moveTo(self.world.map, vec(1, 1))
    self.gm:applyRule("moveCharacter", self.gm.activeCharacter, vec(5, 5))
  end
  
  
  self.dispatcher:dispatch("keypressed", key)
  
  if self.gm.activeCharacter then
    if key == "up" then self.gm.activeCharacter:appendCommand(summon.game.Command.StepCommand("NE", self.world.map)) end
    if key == "down" then self.gm.activeCharacter:appendCommand(summon.game.Command.StepCommand("SW", self.world.map)) end
    if key == "left" then self.gm.activeCharacter:appendCommand(summon.game.Command.StepCommand("NW", self.world.map)) end
    if key == "right" then self.gm.activeCharacter:appendCommand(summon.game.Command.StepCommand("SE", self.world.map)) end
  end
end

function Stage:mousepressed(x, y, button)
  if button == "l" then
    self.camera:startDrag(vec(x, y))
  end
  
  if button == "wu" then
    local c = self.camera
    c:zoom(1.2)
  end
  
  if button == "wd" then
    local c = self.camera
    c:zoom(1/1.2)
  end
  
  self.dispatcher:dispatch("mousepressed", x, y, button)
end

function Stage:mousereleased(x, y, button)
  if button == "l" then self.camera:stopDrag() end
  self.dispatcher:dispatch("mousereleased", x, y, button)
end

return Stage