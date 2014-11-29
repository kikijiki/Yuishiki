local Stage

return function(loader)
  if Stage then return Stage end

  local vec             = loader.require "vector"
  local log             = loader.load "log"
  local sg              = loader.require "graphics"
  local fs              = loader.require "filesystem"
  local BattleInterface = loader.load "battle-interface"
  local EventDispatcher = loader.load "event-dispatcher"
  local World           = loader.load "world"
  local AssetLoader     = loader.load "asset-loader"
  local GM              = loader.load "gm"
  local Camera          = loader.load "camera"
  local MessageRenderer = loader.load "message-renderer"
  local SpriteBatch     = loader.load "spritebatch"
  local Gui             = loader.load "gui"

  Stage = loader.class("Stage", EventDispatcher)

  function Stage:initialize(data)
    EventDispatcher.initialize(self)

    local map = AssetLoader.load("map", data.map)
    self.world = World(map)
    self.gm = GM(self.world)
    self.camera = Camera()
    self.camera:zoom(2)
    self.interface = BattleInterface(self)
    self.mouse = vec()
    self.background = {0, 0, 0}
    self.messageRenderer =
      MessageRenderer("ipamp.ttf", 40, "ps2p.ttf", 30, self.camera)

    -- Minimal GUI
    self.buttons = {}
    self.buttons.play = Gui.PlayButton(0, 0, 40, function() self.gm:resume() end)
    self.buttons.zoom_in = Gui.RoundButton(0, 0, 40, "+", function() self.camera:zoomIn() end)
    self.buttons.zoom_out = Gui.RoundButton(0, 0, 40, "-", function() self.camera:zoomOut() end)

    -- Initialize GM
    self:listenToGM(self.gm)
    local path = AssetLoader.getAssetPath("ruleset").."/"..data.rules.."/"
    fs.getDirectoryItems(path,
      function(file)
        log.i("stage", "Loading ruleset "..file)
        local ruleset = fs.load(path..file)()
        self.gm:loadRuleset(ruleset)
      end)

    -- Load characters
    for id,char in pairs(data.characters) do
      log.fi("stage", "Loading character %s (%s)", id, char)
      self.gm:addCharacter(id, char)
    end

    -- Initialize stage
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
        c:listen(self, "dialog",
          function(character, message, duration, position)
            self.messageRenderer:dialog(
              character.sprite, message, duration, position)
          end)
        c:listen(self, "bubble",
          function(character, message, position, direction, color)
            self.messageRenderer:bubble(
              character.sprite, message, position, direction, color)
          end)
      end)
    self.gm:listen(self, "resume",
      function() self.buttons.play:stop() end)

    self.gm:listen(self, "pause",
      function() self.buttons.play:play() end)
  end

  function Stage:resize(w, h)
    self.width = w
    self.height = h
    self.camera:resize(w, h)
    self.canvas = sg.newCanvas(w, h)

    local btn = self.buttons
    local gui_size = 40 * w / 1000

    btn.play.size = gui_size
    btn.play.x = w - btn.play.size - 20
    btn.play.y = h - btn.play.size - 20

    btn.zoom_out:resize(gui_size)
    btn.zoom_out.x = w - btn.zoom_out.size - 20
    btn.zoom_out.y = btn.play.y - btn.zoom_out.size * 2 - 20

    btn.zoom_in:resize(gui_size)
    btn.zoom_in.x = w - btn.zoom_in.size - 20
    btn.zoom_in.y = btn.zoom_out.y - btn.zoom_in.size * 2 - 20

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

    self.messageRenderer:drawBubbles()
    self.interface:drawCursor()

    self.camera:finish()
    self.messageRenderer:drawDialogs()
    self.interface:draw()

    for _,btn in pairs(self.buttons) do btn:draw() end

    sg.setCanvas()
    sg.pop()
    sg.draw(self.canvas)
  end

  function Stage:update(dt)
    self.gm:update(dt)
    self.camera:update(dt, self.mouse)
    self.messageRenderer:update(dt)

    for _,btn in pairs(self.buttons) do btn:update(dt) end

    if self.gm.activeCharacter then
      self.interface:setCursor(self.gm.activeCharacter.sprite:getTag("head"))
    end

    self.interface:update(dt)
  end

  function Stage:keypressed(key)
    local ac = self.gm.activeCharacter
    if key == "x" and ac then
      ac.agent.bdi.belief_base:dump()
      ac.agent.bdi.goal_base:dump()
      ac.agent.bdi.plan_base:dump()
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
      self.camera:zoomIn()
    end

    if button == "wd" then
      self.camera:zoomOut()
    end

    self:dispatch("mousepressed", x, y, button)
  end

  function Stage:mousereleased(x, y, button)
    if button == "l" then self.camera:stopDrag() end
    for _,btn in pairs(self.buttons) do
      btn:mousereleased(x, y, button)
    end
    self:dispatch("mousereleased", x, y, button)
  end

  function Stage:export()
    local data = {}
    for id, char in pairs(self.world.characters) do
      data[id] = char.agent:save()
    end
    return data
  end

  function Stage:import(data)
    for id, agent_data in pairs(data) do
      if self.world.characters[id] then
        self.world.characters[id].agent:restore(agent_data)
      end
    end
  end

  return Stage
end
