local Class = require "lib.middleclass"
local Character = Class("Character")

local vec = summon.vec
local Command = summon.game.Command
local Stat = require "stat"

function Character:initialize(data)
  self.data = data
  self.name = data.name
  self.modules= data.modules
  
  self.sprite = summon.AssetLoader.load("sprite", data.sprite)
  self.commands = summon.common.Stack()
  self.autoIdle = false
  
  self.agent = ys.mas.Agent()

  self.status = {}
  self.actions = {}
  self.items = {}
  
  self:addStat("position", vec(1, 1))
end

function Character:setGm(gm)
  self.gm = gm
  self.agent.actuator:setCaller({
    execute = function(a, ...)
      self.gm:executeAction(self, a, ...)
    end,
    canExecute = function(a, ...)
      self.gm:canExecuteAction(self, a, ...)
    end
  })
end

function Character.static.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  return Character(data)
end

function Character:setEnvironment(env)
  self.environment = env
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
  
  if self.autoIdle and cmd:empty() and not self.dead then
    self:setAnimation("idle")
    return
  end

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

function Character:pushCommand(command, callback)
  command:bind(self, callback)
  self.commands:push(command)
end

function Character:appendCommand(command, callback)
  command:bind(self, callback)
  self.commands:insert(command, 1)
end

function Character:speak(message, duration)
  summon.speechrenderer.add(self, message, duration, function() return self:getTag("head") + vec(10, -10) * self.scale end)
end

function Character:addStat(name, ...)
  local stat = Stat(...) 
  self.status[name] = stat
  return stat
end

function Character:addCStat(name, ...)
  local stat = Stat.Composite(...) 
  self.status[name] = stat
  return stat
end

function Character:addAction(name)
  self.actions[name] = true
  self.agent.actuator:addAction(name)
end

function Character:kill()
  self.dead = true
  self.sprite:setAnimation("dead")
end

function Character:move(map, path)
  for _,v in pairs(path) do
    self:appendCommand(Command.StepCommand(v, map))
  end
end

function Character:equip(item, slot)
  if slot then
    self.items[slot] = item
  else
    table.insert(self.items, item)
  end
end

return Character