local GM

return function(loader)
  if GM then return GM end

  local log             = loader.load "log"
  local random          = loader.require "random"
  local Value           = loader.load "value"
  local Character       = loader.load "character"
  local Action          = loader.load "action"
  local Item            = loader.load "item"
  local Weapon          = loader.load "weapon"
  local Armor           = loader.load "armor"
  local EventDispatcher = loader.load "event-dispatcher"
  local AssetLoader     = loader.load "asset-loader"

  GM = loader.class("GM", EventDispatcher)
  log = log.tag("GM")

  local max_steps_per_update = 1
  local max_steps_per_turn = 100

  function GM:initialize(world)
    EventDispatcher.initialize(self)

    self.world   = world
    self.rules   = {}
    self.actions = {}
    self.items   = {}

    local twister = random.twister()
    self.rng = function(...) return twister:random(...) end

    self.turn_count      = 0
    self.paused          = true
    self.initiative      = {list = {}, current = 0}
    self.activeCharacter = nil
    self.auto_pause      = true
    self.wait            = -1
  end

  function GM:loadRuleset(ruleset)
    if ruleset.rules then self:loadRules(ruleset.rules) end
    if ruleset.actions then self:loadActions(ruleset.actions) end
    if ruleset.items then self:loadItems(ruleset.items) end
  end

  function GM:loadRules(rules)
    for k,v in pairs(rules) do
      if self.rules[k] then log.w("Overriding rule '"..k.."'.") end
      self.rules[k] = v
    end
  end

  function GM:loadActions(actions)
    for k,v in pairs(actions) do
      if self.actions[k] then log.w("Overriding action '"..k.."'.") end
      self.actions[k] = Action(v)
    end
  end

  function GM:loadItems(items)
    for k,v in pairs(items) do
      if self.items[k] then log.w("Overriding item '"..k.."'.") end
      self.items[k] = v
    end
  end

  function GM:applyRule(rule, ...)
    if self.rules[rule] then
      log.i("RULE "..rule)
      return self.rules[rule](self, ...)
    else
      log.w("Could not apply rule '"..rule.."'.")
    end
  end

  function GM:start()
    self.world:start()
    self:applyRule("start")
  end

  function GM:nextTurn()
    self.turn_count = self.turn_count + 1
    self.initiative.current = 0
    self.activeCharacter = nil
    self:applyRule("turn-start")
    self:dispatch("turn-start")
  end

  function GM:updateInitiative(character)
    local init = self.initiative
    local result = self:applyRule("initiative", character)
    local index = 1

    for i = 1, #init.list do
      local entry = init.list[i]
      if entry.value < result then
        break
      end
      index = index + 1
    end

    table.insert(init.list, index, {value = result, character = character})
    if init.current > 0 and index < init.current then
      init.current = init.current + 1
    end
  end

  function GM:addCharacter(id, data) assert(id and data)
    local source = data[1]
    local character

    if source == "file" then
      local char_data = AssetLoader.load("character", data[2])
      character = Character(self, char_data)
      self:initializeCharacter(character)
    elseif source == "data" then
      character = Character(self, data[2])
      self:initializeCharacter(character)
    elseif source == "instance" then
      character = data[2]
    end

    self:importCharacter(character, id)
  end

  function GM:initializeCharacter(character)
    self:applyRule("initialize-character", character)

    if character.modules then
      for _,v in pairs(character.modules) do
        local times = v[2] or 1
        for i = 1, times do
          self:applyRule(v[1], character, character.status)
        end
      end
    end
  end

  function GM:importCharacter(character, id)
    self.world:addCharacter(character, id)
    self:updateInitiative(character)
    self:dispatch("new-character", character)

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
    local current = self.activeCharacter

    if not self.auto_pause then self.wait = 0.5 end

    local init = self.initiative
    init.current = init.current + 1
    if init.current > #init.list then return false end

    self.activeCharacter = init.list[init.current].character
    self:dispatch("next-character", self.activeCharacter, current)
    self.activeCharacter.agent:resetStepCounter(max_steps_per_turn)
    return self.activeCharacter
  end

  function GM:update(dt)
    self.world:update(dt)

    if self.wait and self.wait > 0 then
      self.wait = self.wait - dt
      if self.wait > 0 then return end
    end

    local char = self.activeCharacter
    if not char then return end

    if self.paused then return end
    if not char.commands:isEmpty() then return end

    for _ = 1, max_steps_per_update do
      local busy = char:updateAI(self.world)
      if not char.commands:isEmpty() then return end
      if not busy then
        char.agent:sendEvent("game", "turn-end")
        if self.auto_pause then self:pause() end
        if not self:nextCharacter() then
          self:nextTurn()
          self:nextCharacter()
        end
        return
      end
    end
  end

  function GM:getActionCost(c, a, ...)
    local cost = self.actions[a].cost
    if type(cost) == "function" then return cost(self, c, ...)
    else return cost end
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

  function GM:isActionAsync(a)
    return self.actions[a].async
  end

  function GM:executeAction(c, a, ...) assert(c and a)
    if not c.actions:isset(a) then
      log.fw("Character %s is trying to use the action [%s] which cannot use.",
        c.id, a)
      return false
    end
    if not self.actions[a] then
      log.fw("Character %s is trying to use the action [%s] which not defined.",
        c.id, a)
      return false
    end
    local action = self.actions[a]
    return action:execute(self, c, ...)
  end

  function GM:getActionMetadata(c, a, ...)
    if c.actions:isset(a) and self.actions[a] then
      return self.actions[a]:getMetadata(self, c, ...)
    end
  end

  function GM:canExecuteAction(c, a, ...)
    if not c or not c.actions[a] or not self.actions[a] then return false end
    local action = self.actions[a]
    return action:canExecute(self, c, ...)
  end

  function GM:getCharacter(id)
    return self.world.characters[id]
  end

  function GM:getCharacterDistance(c1, c2)
    local co1 = c1.status.position:get()
    local co2 = c2.status.position:get()
    return math.abs(co1.x - co2.x) + math.abs(co1.y - co2.y)
  end

  function GM:getDistance(c, target)
    local position = c.status.position:get()
    return math.abs(position.x - target.x) + math.abs(position.y - target.y)
  end

  function GM:removeCharacter(character)
    local init = self.initiative
    for i = 1, #init.list do
      local entry = init.list[i]
      if entry.character == character then
        table.remove(init.list, i)
        if init.current > i then init.current = init.current - 1 end
        break
      end
    end

    self.world:removeCharacter(character)
    self.world.map:setWalkable(character.status.position:get(), true)
    self:dispatch("character-removed", character)
  end

  function GM:killCharacter(character)
    local init = self.initiative
    for i = 1, #init.list do
      local entry = init.list[i]
      if entry.character == character then
        table.remove(init.list, i)
        if init.current > i then init.current = init.current - 1 end
        break
      end
    end

    character:popAll()
    character:push(function()
      self.world:removeCharacter(character)
      self.world.map:setWalkable(character.status.position:get(), true)
      self:dispatch("character-death", character)
    end)

    character:kill()
  end

  function GM.logc(c, ...)
    log.i("["..c.id.."] ", ...)
  end

  function GM.logcc(c, target, ...)
    log.i("["..c.id.."]->["..target.id.."] ", ...)
  end

  function GM:roll(v1, v2)
    local ret
    if not v2 then
      ret = self.rng(v1)
      log.i("Roll [1, "..v1.."] -> "..ret)
    else
      ret = self.rng(v1, v2)
      log.i("Roll ["..v1..", "..v2.."] -> "..ret)
    end
    return ret
  end

  function GM:pause()
    self.paused = true
    self:dispatch("pause")
  end

  function GM:resume()
    self.paused = false
    self:dispatch("resume")
  end

  function GM:newValue(...)
    return Value.fromData(...)
  end

  function GM:getAttackDirection(c, target)
    local dx = c.sprite.position.x - target.sprite.position.x
    if dx > 0 then return -1 else return 1 end
  end

  return GM
end
