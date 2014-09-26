assert(summon, "SUMMON is not loaded.")

local handlers = {}

local foreach = summon.common.uti.foreach

--[[parameter]]--
local parameter = {}
handlers.parameter = parameter

function parameter.onPre(world, entity, data, e)
  summon.log.p(e.depth, "[<  ] Parameter <"..data.name.."> Op <"..data.op..">")

  local p = world:getParameter(entity, data.name)
  e.name = "parameter change"
  e.old = p
  e.new = p:clone()
  e.args = {data.name}

  local ret = e.new[data.op](e.new, table.unpack(data.args))
  e.ret = ret
  e.newValue = e.new:get()
  e.oldValue = p:get()
  e.changed = e.new.changed
end
  
function parameter.onExecute(world, entity, data, e)
  summon.log.p(e.depth, "[ X ] Parameter <"..data.name.."> Op <"..data.op..">")
  world:setParameter(entity, data.name, e.new)
end
  
function parameter.onPost(world, entity, data, e)
  summon.log.p(e.depth, "[  >] Parameter <"..data.name.."> Op <"..data.op..">")
end

--[[rule]]--
local rule = {}
handlers.rule = rule

function rule.onPre(world, entity, data, e)
  summon.log.p(e.depth, "[<  ] Rule <"..data.name..">")
end
  
function rule.onExecute(world, entity, data, e)
  summon.log.p(e.depth, "[ X ] Rule <"..data.name..">")
  data.rule.body(world.interface, world.interface.entities[entity.id], e)
end
  
function rule.onPost(world, entity, data, e)
  summon.log.p(e.depth, "[  >] Rule <"..data.name..">")
end

--[[action]]--
local action = {}
handlers.action = action

action.conditions = {
  ["use"] = function(world, entity, p, v, apply)
    if p.mode == "simple" then
      if p:get() < v then return false end
      if apply then world:process(entity, "parameter", p.name, {op = "sub", args = {v}}) end
      return true
    elseif p.mode == "list" or p.mode == "map" then
      local index = p:contains(v)
      if not index then return false end
      if apply then world:process(entity, "parameter", p.name, {op = "remove", args = {index}}) end 
      return true
    else
      return false, "Cannot have a condition of type \"use\" with a <"..p.mode.."> parameter."
    end
  end,
  
  [">"] = function(world, entity, p, v, apply)
    if p.mode == "simple" or p.mode == "composite" then
      return p:get() <= v
    else
      return false, "Cannot have a condition of type \">\" with a <"..p.mode.."> parameter."
    end
  end,
  
  [">="] = function(world, entity, p, v, apply)
    if p.mode == "simple" or p.mode == "composite" then
      return p:get() < v
    else
      return false, "Cannot have a condition of type \">=\" with a <"..p.mode.."> parameter."
    end
  end,
  
  ["<"] = function(world, entity, p, v, apply)
    if p.mode == "simple" or p.mode == "composite" then
      return p:get() >= v
    else
      return false,"Cannot have a condition of type \"<\" with a <"..p.mode.."> parameter."
    end
  end,
  
  ["<="] = function(world, entity, p, v, apply)
    if p.mode == "simple" or p.mode == "composite" then
      return p:get() > v
    else
      return false,"Cannot have a condition of type \"<=\" with a <"..p.mode.."> parameter."
    end
  end,
  
  ["contains"] = function(world, entity, p, v, apply)
    if p.mode == "list" or p.mode == "map" then
      return p:contains(v)
    else
      return false,"Cannot have a condition of type \"<=\" with a <"..p.mode.."> parameter."
    end
  end
}

function action.checkConditions(world, entity, action, args)
  local static = action.conditions.static or {}
  local dynamic = action.conditions.dynamic
  
  for _,v in pairs(static) do
    local p = world:getParameter(entity, v[1])
    if not action.conditions[v[2]](world, entity, p, v[3], false) then
      return false, ("static condition \""..v[2].."\" on parameter <"..v[1]..">")
    end
  end
  
  if dynamic and dynamic.check then
    if not dynamic.check(world.interface, entity, args) then return false, "dynamic condition" end
  end
  
  return true
end

function action.applyConditions(world, entity, action, args)
  local static = action.conditions.static or {}
  local dynamic = action.conditions.dynamic
  
  for _,v in pairs(static) do
    local p = world:getParameter(entity, v[1])
    action.conditions[v[2]](world, entity, p, v[3], true)
  end
  
  if dynamic and dynamic.apply then
    dynamic.apply(world.interface, entity, args)
  end
end

function handlers.action.onPre(world, entity, data, e)
  local action
  local args = data.args
  
  summon.log.p(e.depth, "[<  ] Action <"..data.name.."> [PRE]")
    
  if entity then
    if not entity.actions[data.name] then 
      error("The action <"..data.name"> is not enabled for this entity.")
    end
    action = world.ruleset.actions[data.name]
  else
    action = world.ruleset.global.actions[data.name]
  end
  
  if not action then error("Action <"..data.name.."> not found.") end
  
  e.action = action
  data.action = action
  local check, err = action.checkConditions(world, entity, action, args)
  if not check then error(err) end
end
  
function handlers.action.onExecute(world, entity, data, e)
  summon.log.p(e.depth, "[ X ] Action <"..data.name.."> [EXE]")
  action.applyConditions(world, entity, action, args)
  data.action.body(world.interface, entity, data.args)
end
  
function handlers.action.onPost(world, entity, data, e)
  summon.log.p(e.depth, "[  >] Action <"..data.name.."> [PST]")
end

--[[entity]]--
local entity = {}
handlers.entity = entity

entity.commands = {}
entity.commands["addParameter"] = function(world, entity, data, e)
  foreach(table.unpack(data.args), function(v)
    entity.parameters[v] = world.ruleset:instanceParameter(v)
  end)
end

entity.commands["addRule"] = function(world, entity, data, e)
  foreach(table.unpack(data.args), function(v)
    entity.rules[v] = world.ruleset.rules[v]
  end)
end

function entity.onPre(world, entity, data, e)
  summon.log.p(e.depth, "[<  ] entity <"..data.name..">")
  e.name = "[on "..data.name.."]"
end
  
function entity.onExecute(world, entity, data, e)
  summon.log.p(e.depth, "[ X ] entity <"..data.name..">")
  handlers.entity.commands[data.name](world, entity, data, e)
end

function entity.onPost(world, entity, data, e)
  summon.log.p(e.depth, "[  >] entity <"..data.name..">")
end

return handlers