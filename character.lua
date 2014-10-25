local class = require "lib.middleclass"
local vec = summon.vec
local Value = require "value"
local Command = summon.game.Command
local EventDispatcher = require "event-dispatcher"
local ys = require "yuishiki"()

local Character = class("Character", EventDispatcher)

function Character:initialize(gm, data)
  EventDispatcher.initialize(self)

  self.gm = gm

  self.name = data.name
  self.modules = data.modules
  self.aimod = data.aimod

  self.sprite = summon.AssetLoader.load("sprite", data.sprite)
  self.commands = summon.common.Stack()

  self.agent = ys.Agent()
  self.sensors = {}

  self.status    = {}
  self.equipment = {}
  self.actions   = {}

  self:addStat("position", "simple", vec(1, 1))

  if data.ai then
    for _,v in pairs(data.ai.modules) do
      local module_data = summon.AssetLoader.load("ai_module", v)
      self.agent:plugModule(module_data)
    end
    for slot,v in pairs(data.ai.sensors) do
      local sensor = summon.AssetLoader.load("sensor", v)
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
  summon.graphics.SpriteBatch.add(self.sprite)
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
  local position = function(s) return self.sprite:getTag("head") + vec(5, -5) * self.sprite.scale end
  self:dispatch("speak", self, message, duration, position)
end

function Character:bubble(message, color)
  self:dispatch("bubble", self, message, self.sprite:getTag("head"), color)
end

function Character:addStat(name, ...)
  local stat = Value.fromData(...)
  if not stat then return end

  self.status[name] = stat
  local belief = self.agent:setBelief(stat, name, "status", true)
  stat:addObserver(belief, function(new, old, ...)
    belief:notify(belief, new, old, ...)
  end)
  stat:addObserver(self.gm.world, function(new, old, ...)
    self.gm.world:propagateEvent(self, "character status changed", self, name, new, old, ...)
  end)
  return stat
end

function Character:addAction(name)
  self.actions[name] = true
  self.agent:addAction(name)
end

function Character:kill(callback)
  self.dead = true
  self:appendCommand("animation", {"dead", {idle = false}})
  self:appendCommand("fade", {}, callback)
  self:bubble("DEAD", {255, 0, 0})
end

function Character:move(map, path, callback)
  for _,v in pairs(path) do
    self:appendCommand("step", {v, map}, callback)
  end
end

function Character:attack(map, target, damage, callback)
  self:appendCommand("lookAt", {map, target})
  target:appendCommand("lookAt", {map, self})
  self:appendCommand("animation", {"attack", {tag = {"hit",
    function() target:hit(damage) end}
  }}, callback)
end

function Character:hit(damage, callback)
  if not damage then return end
  self:bubble(damage, {255, 127, 0})
  self:appendCommand("animation", {"hit"}, callback)
end

function Character:equip(item, slot)
  if not slot then return end
  self.equipment[slot] = item
  item:onEquip(self)

  if item.mods then
    for mod, v in pairs(item.mods) do
      self.status[mod]:setMod(v[1], v[2])
    end
  end

  self.agent:setBelief(item, slot, "equipment")
end

function Character:uneqip(slot)
  if not slot then return end
  local item = self.equipment[slot]
  self.equipment[slot] = nil
  item:onUnequip(self)

  if item.mods then
    for mod, v in pairs(item.mods) do
      self.status[mod]:unsetMod(v[1])
    end
  end

  self.agent:unsetBelief(item, slot, "equipment")
end

return Character
