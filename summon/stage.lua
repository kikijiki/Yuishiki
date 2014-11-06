local Stage

return function(loader)
  if Stage then return Stage end

  local vec = loader.require "vector"
  local log = loader.load "log"
  local sg = loader.require "graphics"
  local fs = loader.require "filesystem"
  local BattleInterface = loader.load "battle-interface"
  local EventDispatcher = loader.load "event-dispatcher"
  local World = loader.load "world"
  local AssetLoader = loader.load "asset-loader"
  local GM = loader.load "gm"
  local Camera = loader.load "camera"
  local MessageRenderer = loader.load "message-renderer"
  local SpriteBatch = loader.load "spritebatch"

  Stage = loader.class("Stage", EventDispatcher)

  function Stage:initialize(data)
    EventDispatcher.initialize(self)

    local map = AssetLoader.load("map", data.map)
    self.world = World(map)
    self.gm = GM(self.world)
    self.camera = Camera()
    self.interface = BattleInterface(self)
    self.mouse = vec()
    self.background = {0, 0, 0}
    self.messageRenderer = MessageRenderer("ipamp.ttf", 40, "ps2p.ttf", 30,
      function(v) return self.camera:gameToScreen(v) end)

    self:listenToGM(self.gm)

    local path = AssetLoader.getAssetPath("ruleset").."/"..data.rules.."/"
    fs.getDirectoryItems(path, function(file)
      log.i("Loading ruleset "..file)
      local ruleset = fs.load(path..file)()
      self.gm:loadRuleset(ruleset)
    end)

    for id,char in pairs(data.characters) do
      self.gm:addCharacter(id, char)
    end

    if data.init then data.init(self, self.world, self.world.characters) end
    self.gm:start()
    self.gm:nextTurn()
    self.gm:nextCharacter()
  end

  function Stage:listenToGM(gm)
    self.gm:listen(self, "next character", function(c)
      self.camera:follow(c.sprite)
      self.interface:setCursor(c.sprite.position)
    end)
    self.gm:listen(self, "new character",
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
    sg.setBackgroundColor( self.background )
    sg.setCanvas(self.canvas)
    
    SpriteBatch.clear()
    self.world:draw()
    SpriteBatch.draw()

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
    local ac = self.gm.activeCharacter

    if key == " " then self.gm:resume() end
    if key == "return" then
      for _,c in pairs(self.gm.world.characters) do
        print(c.name, c.agent.bdi.goal_base)
        for k,v in pairs(c.agent.bdi.goal_base.goal_schemas) do print(k, v) end
      end
    end

    if key == "z" then
      local oni = self.gm.world.characters["oni"]
      for k,v in pairs(self.gm.world.characters) do
        if k ~= "oni" then
          v.agent.bdi:pushGoal("defeat character", {target = "oni"})
          oni.agent.bdi:pushGoal("defeat character", {target = k})
        end
      end
    end

    if key == "x" and ac then
      ac.agent.bdi.belief_base:dump()
      ac.agent.bdi.intention_base:dump()
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
end
