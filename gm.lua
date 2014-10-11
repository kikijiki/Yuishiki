local GM = summon.class("GM")

local Action = require "action"
local Item = require "item"
local Weapon = require "weapon"
local EventDispatcher = require "event-dispatcher"
local console = require "lib.console"

function GM:initialize(world)
  self.world = world
  self.rules = {}
  self.actions = {}
  self.items = {}

  self.turnCount = 0
  self.paused = true
  self.initiative = {results = {}, list = {}, current = 0}
  self.activeCharacter = nil
  self.dispatcher = EventDispatcher()
  self.logger = summon.log.i
end

function GM:dispatch(...) self.dispatcher:dispatch(...) end
function GM:listen(...) self.dispatcher:listen(...) end

function GM:loadRuleset(ruleset)
  if ruleset.rules then self:loadRules(ruleset.rules) end
  if ruleset.actions then self:loadActions(ruleset.actions) end
  if ruleset.items then self:loadItems(ruleset.items) end
end

function GM:loadRules(rules)
  for k,v in pairs(rules) do
    if self.rules[k] then summon.log.i("Overriding rule '"..k.."'.") end
    self.rules[k] = v
  end
end

function GM:loadActions(actions)
  for k,v in pairs(actions) do
    if self.actions[k] then summon.log.i("Overriding action '"..k.."'.") end
    self.actions[k] = Action(v)
  end
end

function GM:loadItems(items)
  for k,v in pairs(items) do
    if self.items[k] then summon.log.i("Overriding weapon '"..k.."'.") end
    self.items[k] = v
  end
end

function GM:applyRule(rule, ...)
  if self.rules[rule] then                                                      summon.log.i("RULE "..rule)
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
  self:applyRule("turn_start")
  self:dispatch("turn_start")
end

function GM:updateInitiative(character)
  local init = self.initiative

  if character then
    local i = self:applyRule("initiative", character)
    local flag = false

    for j = 1, #init.results do
      local entry = init.results[j]
      if entry[1] < i then
        flag = true
        table.insert(init.results, j, {i, character})
        table.insert(init.list, j, character)
        if init.current > 0 and j < init.current then init.current = init.current + 1 end
      end
    end

   if not flag then
      table.insert(init.results, {i, character})
      table.insert(init.list, character)
    end
  end

  --self.initiative.current = 0
  self.activeCharacter = nil
end

function GM:addCharacter(character, id) assert(character)
  if not character.gm then -- if not already initialized
    self:applyRule("initialize_character", character)

    if character.modules then
      for _,v in pairs(character.modules) do
        local times = v[2] or 1
        for i = 1, times do self:applyRule(v[1], character, character.status) end
      end
    end

    if character.items then
      for slot, name in pairs(character.data.items) do
        local item = self:instanceItem(name)
        if item then character:equip(item, slot) end
      end
    end
  end

  character:setGm(self)
  self.world:addCharacter(character, id)
  self:updateInitiative(character)
  self:dispatch("new_character", character)
end

function GM:instanceItem(name)
  local item_data = self.items[name]
  if not item_data then return end
  if item_data.item_type == "weapon" then return Weapon(item_data) end
end

function GM:nextCharacter()
  local init = self.initiative
  init.current = init.current + 1
  if init.current > #init.list then return false end

  self.activeCharacter = init.list[init.current]
  self:dispatch("next_character", self.activeCharacter)
  return self.activeCharacter
end

function GM:update(dt)
  self.world:update(dt)

  if self.paused then return end

  local char = self.activeCharacter
  if not char then return end
  if not char.commands:empty() then return end

  for i = 1, 10 do
    if not char.agent:step() or char.agent:waiting() then
      if not char.commands:empty() then return end
      if not self:nextCharacter() then
        self:nextTurn()
        self:nextCharacter()
      end
      self:pause()
      return
    end
  end
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

function GM:getCharacterDistance(c1, c2)
  local co1 = c1.status.position:get()
  local co2 = c2.status.position:get()
  return math.abs(co1.x - co2.x) + math.abs(co1.y - co2.y)
end

function GM:kill(character)
  character:kill()

  local init = self.initiative
  print(#init.list, #init.results)

  for i = 1, #init.list do
    local entry = init.list[i]
    if entry == character then print("removing "..entry.name)
      table.remove(init.list, i)
      table.remove(init.results, i)
      if init.current > i then init.current = init.current - 1 end
    end
  end

  self:dispatch("kill_character", character)
end

function GM:log(msg)
  self.logger(msg)
end

function GM:logc(c, msg)
  self.logger("["..c.name.."] "..msg)
end

function GM:logcc(c, target, msg)
  self.logger("["..c.name.."]->["..target.name.."] "..msg)
end

function GM:roll(v1, v2)
  if not v2 then
    ret = math.random(v1)
    self:log("Roll [1, "..v1.."] -> "..ret)
  else
    ret = math.random(v1, v2)
    self:log("Roll ["..v1..", "..v2.."] -> "..ret)
  end
  return ret
end

function GM:pause()
  self.paused = true
end

function GM:resume()
  self.paused = false
end

return GM
