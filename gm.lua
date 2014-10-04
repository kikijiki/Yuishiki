local GM = summon.class("GM")

local Action = require "action"

function GM:initialize(world)
  self.world = world
  self.rules = {}
  self.actions = {}
  
  self.turnCount = 0
  self.initiative = {results = {}, list = {}, current = 0}
  self.activeCharacter = nil
end

function GM:loadRules(ruleset)
  for k,v in pairs(ruleset.rules) do
    if self.rules[k] then summon.log.i("Overriding rule '"..k.."'.") end
    self.rules[k] = v
  end
  for k,v in pairs(ruleset.actions) do
    if self.actions[k] then summon.log.i("Overriding action '"..k.."'.") end
    self.actions[k] = Action(v)
  end
end

function GM:applyRule(rule, ...)
  if self.rules[rule] then
    return self.rules[rule](self, ...)
  else
    summon.log.w("Could not apply rule '"..rule.."'.")
  end
end

function GM:start()
  self:applyRule("start")
end

function GM:nextTurn()
  self.turnCount = self.turnCount + 1
  self.initiative.current = 0
  self.activeCharacter = nil
  self:applyRule("turnStart")
end

function GM:updateInitiative(character)
  local init = self.initiative
  local cur = init.current
  
  if character then
    local i = self:applyRule("initiative", character)
    local flag = false
    
    for j = 1, #init.results do
      local entry = init.results[j]
      if entry[1] < i then
        flag = true
        table.insert(init.results, j, {i, character})
        table.insert(init.list, j, character)
        if cur > 0 and j < cur then cur = cur + 1 end
      end 
    end
    
   if not flag then
      table.insert(init.results, {i, character})
      table.insert(init.list, character)
    end
  end

  self.initiative.current = 0
  self.activeCharacter = nil
end

function GM:addCharacter(character, id) assert(character)
  self:applyRule("initializeCharacter", character)
  if character.modules then 
    for _,v in pairs(character.modules) do 
      local times = v[2] or 1
      for i = 1, times do self:applyRule(v[1], character, character.status) end
    end
  end
  character:setGm(self)
  self.world:addCharacter(character, id)
  self:updateInitiative(character)
end

function GM:nextCharacter()
  local init = self.initiative
  
  init.current = init.current + 1
  if init.current > #init.list then return false end
  
  self.activeCharacter = init.list[init.current]
  return self.activeCharacter
end

function GM:update(dt)
  local char = self.activeCharacter
  if char then
    while char and char.commands:empty() and not char.agent:waiting() do
      char.agent:step()
    end
  end
  
  self.world:update(dt)
end

function GM:canPayCost(c, cost, ...)
  if type(cost) == "function" then
    cost = cost(self, c, ...)
  end
  if not cost then return true end
  
  if type(cost) == "number" then
    return not (c.status.ap:get() < cost)
  end
  
  for k,v in pairs(cost) do
    local stat = c.status[k]:get()
    if stat < v then return false end
  end
  
  return true
end

function GM:payCost(c, cost, ...)
  if type(cost) == "function" then
    cost = cost(self, c, ...)
  end
  if not cost then return true end
  
  if type(cost) == "number" then
    c.status.ap:sub(cost)
    return
  end
  
  for k,v in pairs(cost) do
    local stat = c.status[k]
    stat:sub(v)
  end
end

function GM:tryToPayCost(c, cost, ...)
  if self:canPayCost(c, cost, ...) then
    self:payCost(c, cost, ...)
    return true
  else
    return false
  end
end

function GM:executeAction(c, a, ...)
  if not c or not c.actions[a] or not self.actions[a] then return false end
  local action = self.actions[a]
  return action:execute(self, c, ...)
end

function GM:canExecuteAction(c, a, ...)
  if not c or not c.actions[a] or not self.actions[a] then return false end
  local action = self.actions[a]
  return action:canExecute(self, c, ...)
end

return GM