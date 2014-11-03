local Character

return function(loader)
  if Character then return Character end

  local ys = require "yuishiki"()
  local vec = loader.require "vector"
  local log = loader.load "log"
  local Value = loader.load "value"
  local Commands = loader.load "commands"
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
        if self.gm:isActionAsync(a) then
          if not coroutine.running() then
            log.e("Cannot run an async action <"..a.."> from outside a coroutine.")
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
      end
    })

    if data.equipment then
      for slot, name in pairs(data.equipment) do
        local item = gm:instanceItem(name)
        if item then self:equip(item, slot) end
      end
    end
  end

  function Character:setWorld(world, id)
    self.world = world
    self.id = id
    for _,sensor in pairs(self.sensors) do
      sensor:register(world)
    end
  end

  function Character:draw()
    SpriteBatch.add(self.sprite)
  end

  function Character:updateAI(world)
    for _,sensor in pairs(self.sensors) do
      sensor:update(world)
    end
    return self.agent:step()
  end

  function Character:update(dt)
    self.sprite:update(dt)

    while not self.commands:empty() and type(dt) == "number" and dt > 0 do
      local cmd = self.commands:top()

      if coroutine.status(cmd) == "dead" then
        self.commands:pop()
      else
        local ok
        ok, dt = coroutine.resume(cmd, dt, self)
        if not ok then
          log.e("Error in command:"..dt)
          self.commands:pop()
        end
      end
    end
  end

  function Character:pop() return self.commands:pop() end
  function Character:push(f) self.commands:push(coroutine.create(f)) end
  function Character:append(f) self.commands:insert(coroutine.create(f)) end
  function Character:pushCommand(cmd, ...) self:push(Commands[cmd](...)) end
  function Character:appendCommand(cmd, ...) self:append(Commands[cmd](...)) end

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
    self:pushCommand("fade")
    self:pushCommand("animation", "dead", {idle = false})
    self:bubble("DEAD", {255, 0, 0})
  end

  function Character:move(path)
    for i = #path, 1, -1 do
      self:pushCommand("step", path[i])
    end
  end

  function Character:hit(hit, damage)
    if damage then
      self:bubble(damage, {255, 127, 0})
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
