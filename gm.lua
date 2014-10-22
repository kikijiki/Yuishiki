local class = require "lib.middleclass"
local Value = require "value"
local Character = require "character"
local Action = require "action"
local Item = require "item"
local Weapon = require "weapon"
local Armor = require "armor"
local EventDispatcher = require "event-dispatcher"

local GM = class("GM", EventDispatcher)
GM.uti = {}

local max_steps_per_update = 1

function GM:initialize(world)
  EventDispatcher.initialize(self)

  self.world = world
  self.rules = {}
  self.actions = {}
  self.items = {}

  self.turnCount = 0
  self.paused = true
  self.initiative = {results = {}, list = {}, current = 0}
  self.activeCharacter = nil
  self.logger = summon.log.i
end

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
    if self.items[k] then summon.log.i("Overriding item '"..k.."'.") end
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

function GM:addCharacter(name, id) assert(name)
  local char_data = summon.AssetLoader.load("character", name)
  local character = Character(self, char_data)

  self:applyRule("initialize_character", character)

  if character.modules then
    for _,v in pairs(character.modules) do
      local times = v[2] or 1
      for i = 1, times do self:applyRule(v[1], character, character.status) end
    end
  end

  self:importCharacter(character, id)
end

function GM:importCharacter(character, id)
  self.world:addCharacter(character, id)
  self:updateInitiative(character)
  self:dispatch("new_character", character)

  character.status.position:addObserver(self, function(new, old)
    self.world.map:setWalkable(new, false)
    self.world.map:setWalkable(old, true)
  end)
end

function GM:instanceItem(name)
  local item_data = self.items[name]
  if not item_data then return end
  if item_data.item_type == "weapon" then return Weapon(item_data) end
  if item_data.item_type == "armor" then return Armor(item_data) end
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

  --if not char.commands:empty() then return end

  for i = 1, max_steps_per_update do
    if not char.commands:empty() then return end
    if not char.agent:step() or char.agent:waiting() then
      if not char.commands:empty() then return end
                                                                                self:pause()
      if not self:nextCharacter() then
        self:nextTurn()
        self:nextCharacter()
      end
      return
    end
  end
                                                                                --self:pause()
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
  character:kill(function() print("FEWFEWFWEFEW")
      self.world:removeCharacter(character)
    end)

  local init = self.initiative

  for i = 1, #init.list do
    local entry = init.list[i]
    if entry == character then
      table.remove(init.list, i)
      table.remove(init.results, i)
      if init.current > i then init.current = init.current - 1 end
    end
  end

  self.world.map:setWalkable(character.status.position:get(), true)
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

function GM.uti.newValue(...)
  return Value.fromData(...)
end

return GM
