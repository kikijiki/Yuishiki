local Character = summon.class("Character")

local vec = summon.vec
local Command = summon.game.Command
local Stat = require "stat"
local EventDispatcher = require "event-dispatcher"

function Character:initialize(data)
  self.data = data
  self.name = data.name
  self.modules = data.modules
  self.aimod = data.aimod

  self.sprite = summon.AssetLoader.load("sprite", data.sprite)
  self.commands = summon.common.Stack()

  self.agent = ys.mas.Agent()

  for _,v in pairs(self.aimod) do
    local aimod = summon.AssetLoader.load("aimod", v)
    self.agent:plug(aimod)
  end

  self.status = {}
  self.actions = {}
  self.items = {}

  self:addStat("position", vec(1, 1))

  self.dispatcher = EventDispatcher()
end

function Character:dispatch(...) self.dispatcher:dispatch(...) end
function Character:listen(...) self.dispatcher:listen(...) end

function Character:setGm(gm)
  self.gm = gm
  self.agent.actuator:setCaller({
    execute = function(a, ...)
      return self.gm:executeAction(self, a, ...)
    end,
    canExecute = function(a, ...)
      return self.gm:canExecuteAction(self, a, ...)
    end
  })
end

function Character.static.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  return Character(data)
end

function Character.static.loadAiMod(path)
  return summon.AssetLoader.loadRaw(path)
end

function Character:setEnvironment(env, id)
  self.environment = env
  self.id = id
end

function Character:draw()
  summon.graphics.SpriteBatch.add(self.sprite)
end

function Character:update(dt)
  self:updateCommands(dt)
  self.sprite:update(dt)
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
  command = Command[command](unpack(args))
  command:bind(self, callback)
  self.commands:push(command)
end

function Character:appendCommand(command, args, callback)
  command = Command[command](unpack(args))
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

function Character:bindStat(name, stat)
  local belief = self.agent:bindBelief(name, function() return stat:get() end)
  stat:listen(belief, function(stat, new, old)
    belief:onChange(old)
  end)
end

function Character:addStat(name, ...)
  local stat = Stat(...)
  self.status[name] = stat
  self:bindStat(name, stat)
  return stat
end

function Character:addCStat(name, ...)
  local stat = Stat.Composite(...)
  self.status[name] = stat
  self:bindStat(name, stat)
  return stat
end

function Character:addAction(name)
  self.actions[name] = true
  self.agent.actuator:addAction(name)
end

function Character:kill(callback)
  self.dead = true
  self.sprite:setAnimation("dead")
  self:appendCommand("animation", {"dead"})
  self:appendCommand("fade", {}, callback)
  self:bubble("DEAD", {255, 0, 0})
end

function Character:move(map, path, callback)
  for _,v in pairs(path) do
    self:appendCommand("step", {v, map}, callback)
  end
end

function Character:attack(map, target, callback)
  self:appendCommand("lookAt", {map, target})
  target:appendCommand("lookAt", {map, self})
  self:appendCommand("animation", {"attack"}, callback)
  --self:speak("!", 1)
end

function Character:hit(dmg, callback)
  self:bubble(dmg, {255, 127, 0})
  self:appendCommand("animation", {"hit"}, callback)
end

function Character:equip(item, slot)
  if slot then
    self.items[slot] = item
  else
    table.insert(self.items, item)
  end
end

return Character
