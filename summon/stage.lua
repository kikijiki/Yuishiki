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

  function Stage:initialize(game, data)
    EventDispatcher.initialize(self)
    self.game = game

    local map = AssetLoader.load("map", data.map)
    self.world = World(map)
    self.gm = GM(self.world)
    self.gm.auto_pause = false
    self.status = "active"
    self.speed = 1
    self.camera = Camera()
    self.camera:zoom(2)
    self.mouse = {x = 0, y = 0}
    self.interface = BattleInterface(self)
    self.background = {0, 0, 0}
    self.messageRenderer =
      MessageRenderer(game, "ipamp.ttf", 40, "ps2p.ttf", 30, self.camera)

    -- Minimal GUI
    self.gui = {elements = {}}
    self.gui.elements.play = Gui.PlayButton(0, 0, 40, function()
      if self.gm.paused then
        self.gm:resume()
      else
        self.gm:pause()
      end
    end)

    local max_speed = 4
    local speed_label = {
      en = "Speed",
      ja = "再生スピード",
      it = "Velocità"
    }
    self.gui.elements.zoom_in = Gui.RoundButton(0, 0, 40, "+", function()
      self.speed = self.speed * 2
      if self.speed > max_speed then
        self.speed = max_speed
      else
        self.gui.elements.chatlog:log(speed_label, "x"..self.speed)
      end
    end)
    self.gui.elements.zoom_out = Gui.RoundButton(0, 0, 40, "-", function()
      self.speed = self.speed / 2
      if self.speed < 1/max_speed then
        self.speed = 1/max_speed
      else
        self.gui.elements.chatlog:log(speed_label, "x"..self.speed)
      end
    end)
    self.gui.elements.chatlog = Gui.Chatlog(200, 4, 3)
    self.font = AssetLoader.load("font", "ipamp.ttf@60")

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
    for id, char in pairs(data.characters) do
      log.fi("stage", "Loading character %s", id)
      self.gm:addCharacter(id, char)
    end

    -- Initialize stage
    if data.init then data.init(self, self.world, self.world.characters) end
    self.gm:start()
    self.gm:nextTurn()
    self.gm:nextCharacter()
  end

  function Stage:listenToGM(gm)
    self.gm:listen(self, "next-character", function(c)
      self.camera:follow(c.sprite)
      self.interface:setCursor(c.sprite.position)
    end)
    self.gm:listen(self, "new-character",
      function(c)
        c:listen(self, "dialog",
          function(character, message, duration, position)
            self.gui.elements.chatlog:log(
              self.game:getLocalizedString(character.name, message))
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
      function() self.gui.elements.play:stop() end)

    self.gm:listen(self, "pause",
      function() self.gui.elements.play:play() end)

    self.gm:listen(self, "game-over",
      function() self.status = "over" end)
  end

  function Stage:resize(w, h)
    self.width = w
    self.height = h
    self.camera:resize(w, h)
    self.canvas = sg.newCanvas(w, h)

    local gui = self.gui
    local e = gui.elements
    local gui_size = 40 * w / 1000

    e.play.size = gui_size
    e.play.x = w - e.play.size - 20
    e.play.y = h - e.play.size - 20

    e.zoom_out:resize(gui_size)
    e.zoom_out.x = w - e.zoom_out.size - 20
    e.zoom_out.y = e.play.y - e.zoom_out.size * 2 - 20

    e.zoom_in:resize(gui_size)
    e.zoom_in.x = w - e.zoom_in.size - 20
    e.zoom_in.y = e.zoom_out.y - e.zoom_in.size * 2 - 20

    e.chatlog:resize(w, h)
    self.interface:resize(w, h)
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
    self.interface:draw(self.gm.activeCharacter)

    for _,element in pairs(self.gui.elements) do element:draw() end

    sg.setCanvas()
    sg.pop()
    sg.draw(self.canvas)

    if self.status == "over" then
      sg.setColor(0, 0, 0, 180)
      sg.rectangle("fill", 0, 0, self.width, self.height)
      sg.setColor(255, 255, 255, 255)
      self.font:apply()
      sg.printf("STAGE OVER",
        0, (self.height - self.font:getHeight()) / 2, self.width, "center")
    end
  end

  function Stage:update(dt)
    dt = dt * self.speed
    self.gm:update(dt)
    self.camera:update(dt, self.mouse)
    self.messageRenderer:update(dt)

    if self.status == "over" then return end
    for _,element in pairs(self.gui.elements) do
      if element.update then
        element:update(dt)
      end
    end

    if self.gm.activeCharacter then
      self.interface:setCursor(self.gm.activeCharacter.sprite:getTag("head"))
    end

    self.interface:update(dt)
  end

  function Stage:dumpActiveCharacter()
    local ac = self.gm.activeCharacter
    if ac then
      ac.agent.bdi.belief_base:dump("d")
      ac.agent.bdi.goal_base:dump("d")
      ac.agent.bdi.plan_base:dump("d")
      ac.agent.bdi.intention_base:dump("d")
    end
  end

  function Stage:keypressed(key)
    if self.status == "over" then return end

    if key == "x" then
      self:dumpActiveCharacter()
    end

    if key == " " then self.gm:resume() end
    if key == "kp+" then self.speed = self.speed * 2 end
    if key == "kp-" then self.speed = self.speed / 2 end
    if self.speed > 16 then self.speed = 16 end
    if self.speed < 1/16 then self.speed = 1/16 end

    self:dispatch("keypressed", key)
  end

  function Stage:mousepressed(x, y, button)
    if self.status == "over" then return end

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
    if self.status == "over" then return end

    if button == "l" then self.camera:stopDrag() end

    for _,element in pairs(self.gui.elements) do
      if element.mousereleased then
        element:mousereleased(x, y, button)
      end
    end

    self:dispatch("mousereleased", x, y, button)
  end

  function Stage:touchgestured(x, y, theta, distance, touchcount)
    self.camera:pinch(distance * 50)
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
