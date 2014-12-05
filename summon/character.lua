local Character

return function(loader)
  if Character then return Character end

  local ys              = require "yuishiki"()
  local vec             = loader.require "vector"
  local log             = loader.load "log"
  local Value           = loader.load "value"
  local Commands        = loader.load "commands"
  local EventDispatcher = loader.load "event-dispatcher"
  local AssetLoader     = loader.load "asset-loader"
  local Stack           = loader.load "stack"
  local SpriteBatch     = loader.load "spritebatch"

  Character = loader.class("Character", EventDispatcher)

  function Character:initialize(gm, data)
    EventDispatcher.initialize(self)

    self.gm = gm

    self.name    = data.name
    self.modules = data.modules
    self.aimod   = data.aimod

    self.log = log.tag("CHAR "..self.name)

    self.sprite   = AssetLoader.load("sprite", data.sprite)
    self.commands = Stack()

    self.agent   = ys.Agent()
    self.sensors = {}
    self.values  = {}

    self:addValue({"simple", vec(1, 1)},    "status", "position")
    self:addValue({"simple",      true},    "status",    "alive")
    self:addValue({ "table"           },   "actions"            )
    self:addValue({ "table"           }, "equipment"            )

    if data.ai then
      for _,v in pairs(data.ai.modules) do
        local module_data = AssetLoader.load("ai_module", v)
        self.agent:plugModule(module_data)
      end
      for slot,v in pairs(data.ai.sensors) do
        local sensor = AssetLoader.load("sensor", v)
        sensor:link(self, self.agent)
        table.insert(self.sensors, sensor)
      end
    end

    self.agent.actuator:setCaller({
      execute = function(a, ...)
        if self.gm:isActionAsync(a) then
          if not coroutine.running() then
            self.log.fe(
              "Cannot run an async action <%s> from outside a coroutine.", a)
            return
          end
          local data
          local args = {...}
          self:push(function()
            data = self.gm:executeAction(self, a, table.unpack(args))
          end)
          coroutine.yield()
          return data
        else
          return self.gm:executeAction(self, a, ...)
        end
      end,
      canExecute = function(a, ...)
        return self.gm:canExecuteAction(self, a, ...)
      end,
      getCost = function(a, ...)
        return self.gm:getActionCost(self, a, ...)
      end,
      getMetadata = function(a, ...)
        return self.gm:getActionMetadata(self, a, ...)
      end
    })

    if data.equipment then
      for slot, name in pairs(data.equipment) do
        local item = gm:instanceItem(name)
        if item then self:equip(item, slot) end
      end
    end
  end

  local function exposeValue(world, character, value, path)
    value:addObserver(world, function(...)
      local event = {"character", "value"}
      for _,v in ipairs(path) do table.insert(event, v) end
      world:propagateEvent(character, event, value, ...)
    end)
  end

  function Character:setWorld(world, id)
    self.world = world
    self.id = id

    self.agent:importBelief(id, "self.id")

    self.log = log.tag("CHAR "..self.id)

    for _,sensor in pairs(self.sensors) do
      sensor:register(world)
    end

    for path,value in pairs(self.values) do
      exposeValue(world, self, value, path)
    end
  end

  function Character:draw()
    SpriteBatch.add(self.sprite)
  end

  function Character:updateAI()
    for _,sensor in pairs(self.sensors) do sensor:update(self.world) end
    return self.agent:step()
  end

  function Character:update(dt)
    self.sprite:update(dt)

    while not self.commands:isEmpty() and type(dt) == "number" and dt > 0 do
      local cmd = self.commands:top()

      if coroutine.status(cmd) == "dead" then
        self:pop()
      else
        local ok
        ok, dt = coroutine.resume(cmd, dt, self)
        if not ok then
          log.e("Error in command:"..dt)
          self:pop()
        end
      end
    end
  end

  function Character:pop() return self.commands:pop() end
  function Character:popAll() return self.commands:popAll() end
  function Character:push(f, wait)
    self.commands:push(coroutine.create(f))
    if wait then coroutine.yield() end
  end
  function Character:append(f) self.commands:insert(coroutine.create(f)) end
  function Character:pushCommand(cmd, ...) self:push(Commands[cmd](...)) end
  function Character:appendCommand(cmd, ...) self:append(Commands[cmd](...)) end

  function Character:speak(message, duration)
    local position = function(s)
      return self.sprite:getTag("head") + vec(5, -5) * self.sprite.scale
    end
    self:dispatch("dialog", self, message, duration, position)
  end

  function Character:bubble(message, direction, color)
    self:dispatch("bubble",
      self, message, self.sprite:getTag("head"), direction, color)
  end

  function Character:addValue(data, ...) assert(data)
    local value = Value.fromData(table.unpack(data))
    if not value then return end

    local base = self
    local path = table.pack(...)
    for i = 1, path.n - 1 do
      local subpath = path[i]
      if not base[subpath] then base[subpath] = {} end
      base = base[subpath]
    end

    base[path[path.n]] = value

    local belief = self.agent:importBelief(value, "self", ...)

    value:addObserver(belief, function(new, old, ...)
      belief:notify(belief, new, old, ...)
    end)

    if self.world then exposeValue(self.world, self, value, path) end
    self.values[path] = value

    return value
  end

  function Character:addAction(name)
    self.actions:set(name, true)
    self.agent:addAction(name)
  end

  function Character:kill(callback)
    self.status["alive"]:set(false)
    self.sprite:setAnimation("dead")
    self.sprite:lock()
    self:bubble("DEAD", 0, {255, 0, 0})
    self:pushCommand("fade")
  end

  function Character:move(path)
    self:pushCommand("animation", "idle")
    for i = #path, 1, -1 do
      self:pushCommand("step", path[i])
    end
  end

  function Character:hit(damage, direction)
    if damage then
      local range = 0.2
      local cint = math.floor(120 * (1 - range + math.random() * range))
      self:bubble(damage, direction, {255, cint, 0})
      self:pushCommand("animation", "hit")
    end
  end

  function Character:equip(item, slot)
    if not slot then return end
    local old = self.equipment:get(slot)

    item:onEquip(self)
    self.equipment:set(slot, item)

    if item.mods then
      for mod, v in pairs(item.mods) do
        if self.status[mod] then
          self.status[mod]:setMod(v[1], v[2])
        end
      end
    end

    if self.world then
      self.world:propagateEvent(
        self, {"character", "equipment"}, slot, item, old)
    end
  end

  function Character:uneqip(slot)
    if not slot then return end
    local item = self.equipment:get(slot)
    self.equipment:set(slot, nil)
    item:onUnequip(self)

    if item.mods then
      for mod, v in pairs(item.mods) do
        self.status[mod]:unsetMod(v[1])
      end
    end
  end

  return Character
end
