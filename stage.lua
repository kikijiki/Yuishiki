local Stage = summon.class("Stage")

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
  self.messageRenderer = sg.MessageRenderer("ipamp.ttf", 40)

  self:listenToGM(self.gm)

  local path = summon.AssetLoader.getAssetPath("ruleset").."/"..data.rules.."/"
  summon.fs.getDirectoryItems(path, function(file)
    local ruleset = summon.fs.load(path..file)()
    self.gm:loadRuleset(ruleset)
  end)

  for _,char in pairs(data.characters) do
    self.gm:addCharacter(characters[char], char)
  end

  if data.init then data.init(self, self.world, self.world.characters) end
  self.gm:start()
  self.gm:nextTurn()
  self.gm:nextCharacter()
end

function Stage:dispatch(...) self.dispatcher:dispatch(...) end
function Stage:listen(...) self.dispatcher:listen(...) end

function Stage:listenToGM(gm)
  self.gm:listen(self, "next_character", function(c)
    self.camera:follow(c.sprite)
    self.interface:setCursor(c.sprite.position)
  end)
  self.gm:listen(self, "new_character",
    function(c)
      c:listen(self, "speak",
        function(character, message, duration, position)
          self.messageRenderer:speak(character.sprite, message, duration, position)
        end)
      c:listen(self, "bubble",
        function(character, message, position, color)
          self.messageRenderer:bubble(character.sprite, message, position, color)
        end)
    end)
end

function Stage:resize(w, h)
  self.width = w
  self.height = h
  self.camera:resize(w, h)
  self.canvas = sg.newCanvas(w, h)
  self:dispatch("resize", w, h)
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
  self.messageRenderer:draw()
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
  self.messageRenderer:update(dt)
  if self.gm.activeCharacter then
    self.interface:setCursor(
      self.gm.activeCharacter.sprite:getTag("head"))
  end
  self.interface:update(dt)
end

function Stage:keypressed(key)
  if key == "return" then
    self.gm:resume()
    --if char then
    -- self.camera:follow(char.sprite)
    -- end
  end

  if key == " " and self.gm.activeCharacter then
    self.gm.activeCharacter.agent.actuator.interface.attack(self.gm.world.characters["char2"])
  end

  if key == "z" and self.gm.activeCharacter then
    self.gm.activeCharacter.agent.bdi:pushGoal("be in location", {x = 4, y = 3})
  end

  if key == "x" and self.gm.activeCharacter then
    self.gm.activeCharacter.agent.bdi.intention_base:dump()
  end

  self:dispatch("keypressed", key)
end

function Stage:mousepressed(x, y, button)
  if button == "l" then
    self.camera:startDrag(vec(x, y))
  end

  if button == "r" then
    self.camera:follow(vec(0, 0))
  end

  if button == "wu" then
    local c = self.camera
    c:zoomIn()
  end

  if button == "wd" then
    local c = self.camera
    c:zoomOut()
  end

  self:dispatch("mousepressed", x, y, button)
end

function Stage:mousereleased(x, y, button)
  if button == "l" then self.camera:stopDrag() end
  self:dispatch("mousereleased", x, y, button)
end

return Stage
