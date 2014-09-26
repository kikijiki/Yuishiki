assert(summon, "SUMMON is not loaded.")

local World = summon.class("World")

function World:initialize(ruleset)
  self.ruleset = summon.AssetLoader.load("ruleset", ruleset)
  self.interface = summon.game.WorldInterface.make(self)
  self.entities = {}
  
  self.map = nil
  self.units = {}
end

function World:addEntity(...)
  for _,e in pairs{...} do
    self.entities[e.id] = e
    self:dispatchEvent(e, {name = "new entity", when = "post"})
  end
end

function World:addUnit(...)
  for _,u in pairs{...} do
    self.units[u.id] = u
    self.entities[u.id] = u

    self:dispatchEvent(u, {name = "new character", when = "post"})
    
    if self.map then self.map:place(u.sprite) end
  end
end

function World:setMap(mapName)
  local map = summon.AssetLoader.load("map", mapName)
  self.map = map
  return map
end

function World:update(dt)
  self.map:update(dt)
  for _,u in pairs(self.units) do u:update(dt) end
end

function World:draw()
  self.map:draw()
  for _,u in pairs(self.units) do u:draw() end
end

function World:try(entity, target, args)
  if type(entity) == "string" then entity = self.entities[entity] end
  
  original_state = entity:cloneState()
  local ok, ret = pcall(self.execute, self, entity, target, args)

  if ok then
    return ret
  else
    entity:swapState(original_state)
    summon.log.d("Original state restored. Error: "..ret)
    return false
  end
end

function World:execute(entity, target, args, parent)
  local handler = summon.game.RuleHandler[target]

  if type(entity) == "string" then entity = self.entities[entity] end

  local e = {
    target = target,
    args = args,
    data = {},
    parent = parent
  }

  if parent and parent.depth then
    e.depth = parent.depth + 1
  else e.depth = 0 end

  e.when = "pre"
  handler.onPre(self, entity, args, e)
  if not e.skip then self:dispatchEvent(entity, e) end
  e.skip = false
  
  e.when = nil
  handler.onExecute(self, entity, args, e)
  
  e.when = "post"
  handler.onPost(self, entity, args, e)
  if not e.skip then self:dispatchEvent(entity, e) end
end

local function unifies(rule, event)
  local tr = rule.trigger
  
  --[[
    rule/event 
         pre | nil | post
    pre   O     X     X
    nil   O     O     O
    post  X     O     O
  ]]

  if tr.when == "pre" and event.when ~= "pre" then return false end
  if tr.when == "post" and event.when == "pre" then return false end
  if tr.event ~= event.name then return false end
  
  if tr.args then
    for k,v in pairs(tr.args) do
      if v and event.args[k] ~= v then return false end
    end
  end
  
  return true
end

function World:dispatchEvent(entity, event)
  if entity then 
    for rulename,rule in pairs(entity.rules) do
      if unifies(rule, event) then
        summon.log.i("Firing(local) rule <"..rulename.."> in response to event <"..event.name.." ["..(event.when or "").."]>")
        self:execute(entity, "rule", {rule = rule, name = rulename}, event)
      end
    end
  end
  for rulename,rule in pairs(self.ruleset.globals.rules) do
    if unifies(rule, event) then
      summon.log.i("Firing (global) rule <"..rulename.."> in response to event <"..event.name.." ["..(event.when or "").."]>")
      self:execute(entity, "rule", {rule = rule, name = rulename}, event)
    end
  end
end

function World:getParameter(entity, name)
  return entity.parameters[name]
end

function World:setParameter(entity, name, p)
  entity.parameters[name] = p
end

return World