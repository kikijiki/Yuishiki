local Character

return function(loader)
  if Character then return Character end

  local ys = require "yuishiki"()
  local vec = loader.require "vector"
  local Value = loader.load "value"
  local Command = loader.load "command"
  local EventDispatcher = loader.load "event-dispatcher"
  local AssetLoader = loader.load "asset-loader"
  local Stack = loader.load "stack"
  local SpriteBatch = loader.load "spritebatch"

  Character = loader.class("Character", EventDispatcher)

  function Character:initialize(gm, data)
    EventDispatcher.initialize(self)

    self.gm = gm

    self.name = data.name
    self.modules = data.modules
    self.aimod = data.aimod

    self.sprite = AssetLoader.load("sprite", data.sprite)
    self.commands = Stack()

    self.agent = ys.Agent()
    self.sensors = {}

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
        return self.gm:executeAction(self, a, ...)
      end,
      canExecute = function(a, ...)
        return self.gm:canExecuteAction(self, a, ...)
      end
    })

    if data.equipment then
      for slot, name in pairs(data.equipment) do
        local item = gm:instanceItem(name)
        if item then self:equip(item, slot) end
      end
    end
  end

  function Character:setEnvironment(env, id)
    self.environment = env
    self.id = id
    for _,sensor in pairs(self.sensors) do
      sensor:register(env)
    end
  end

  function Character:draw()
    SpriteBatch.add(self.sprite)
  end

  function Character:update(dt)
    self:updateCommands(dt)
    self.sprite:update(dt)
  end

  function Character:updateAI(world)
    for _,sensor in pairs(self.sensors) do
      sensor:update(world)
    end
    return self.agent:step()
  end

  function Character:updateCommands(dt)
    local cmd = self.commands

    while not cmd:empty() do
      local c = self.commands:top()

      if c.status == "inactive" then c:execute()
      elseif c.status == "finished" then
        c:onPop()
        cmd:pop()
      else
        dt = c:update(dt) or 0
        if c.status == "executing" then return end
      end
    end
  end

  function Character:popCommand()
    return self.commands:pop()
  end

  function Character:pushCommand(command, args, callback)
    command = Command[command](table.unpack(args))
    command:bind(self, callback)
    self.commands:push(command)
  end

  function Character:appendCommand(command, args, callback)
    command = Command[command](table.unpack(args))
    command:bind(self, callback)
    self.commands:insert(command, 1)
  end

  function Character:speak(message, duration)
    local position = function(s)
      return self.sprite:getTag("head") + vec(5, -5) * self.sprite.scale
    end
    self:dispatch("speak", self, message, duration, position)
  end

  function Character:bubble(message, color)
    self:dispatch("bubble", self, message, self.sprite:getTag("head"), color)
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

    table.insert(path, 1, "character")
    path.n = path.n + 1
    value:addObserver(self.gm.world, function(...)
      self.gm.world:propagateEvent(self, path, value, ...)
    end)

    return value
  end

  function Character:addAction(name)
    self.actions:set(name, true)
    self.agent:addAction(name)
  end

  function Character:kill(callback)
    self.status["alive"]:set(false)
    self:appendCommand("animation", {"dead", {idle = false}})
    self:appendCommand("fade", {}, callback)
    self:bubble("DEAD", {255, 0, 0})
  end

  function Character:move(map, path, callback)
    for _,v in pairs(path) do
      self:appendCommand("step", {v, map}, callback)
    end
  end

  function Character:attack(map, target, hit, damage, callback)
    self:appendCommand("lookAt", {map, target})
    target:appendCommand("lookAt", {map, self})
    self:appendCommand("animation", {"attack", {tag = {"hit",
      function()
        if not hit then self:bubble("Miss") end
        target:hit(hit, damage)
      end}
    }}, callback)
  end

  function Character:hit(hit, damage, callback)
    if damage then
      self:bubble(damage, {255, 127, 0})
      self:appendCommand("animation", {"hit"}, callback)
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

    self.gm.world:propagateEvent(
        self, "character equipment changed", self, slot, item, old)
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

  function Character.log(...) print("CHAR", ...) end

  return Character
end
