local Actuator = ys.class("Actuator")
local actuator_class_prefix = "actuator_"
Actuator.static._ys_component_type = "actuator"

local generateId =  ys.common.uti.makeIdGenerator("actuator")
local generateEventId = ys.common.uti.makeIdGenerator("actuator_action", true)

function Actuator.static.define(name, actions)
  local A = ys.class(actuator_class_prefix..name, ys.mas.Actuator)
  A.static.name = name
  A.actions = actions or {}
  
  A.initialize = function(self, agent)
    Actuator.initialize(self, agent)
    for _,action in pairs(A.actions) do self:add(action) end
  end
  
  A.register = function(action) assert(action and action.name and action.execute)
    A.actions[action.name] = action
  end
  
  return A
end

function Actuator:initialize(agent, actions) assert(agent)
  self.agent = agent
  self.id = generateId()
  self.actions = {}
  self.pending = {}
  
  if actions then
    for _,action in pairs(actions) do self:add(action) end
  end
  
  self.interface = setmetatable({}, {
    __index = function(t, k)
      return function(...) return self:execute(k, ...) end
    end,
    __newindex = function(t, k)
      log.w("Trying to modify an interface.")
      return ys.common.uti.null_interface
    end
  })
end

function Actuator:update()
  for _,data in pairs(self.pending) do self:updateThread(data) end
end

function Actuator:updateThread(data) assert(data)
  local thread = data.thread
  ----[5.2] local ret = {coroutine.resume(thread, self, table.unpack(data.parameters))}
  local ret = {coroutine.resume(thread, self, unpack(data.parameters))}
  local err = ret[1] == false
  table.remove(ret, 1)
  ----[5.2] if err == false then log.w("Actuator <"..self.class.name.."> raised an error:", table.unpack(ret)) end
  local finished = (coroutine.status(thread) == "dead")
  if not finished and err == false then
    log.w("Actuator <"..self.class.name.."> raised an error:", unpack(ret))
  end
  local event = ys.mas.Event.Actuator(data.id, finished, ret)
  self.agent:sendInternalEvent(event)
  if finished then self.pending[data.id] = nil end
end

function Actuator:execute(action, ...)
  if not self:isActive() then return end
  local a = self.actions[action]

  if a then
    if a.canExecute and not a.canExecute(self, ...) then
      log.w("Actuator <"..self.class.name.."> raised an error: execution condition of action <"..action.."> is not satisfied.")
      return
    end
  else
    log.w("Actuator <"..self.class.name.."> raised an error: action <"..action.."> does not exist.")
    return
  end
  
  local id = generateEventId()
  local thread = coroutine.create(a.execute)
  local thread_data = {id = id, thread = thread, parameters = {...}}
  
  self.pending[id] = thread_data
  self:updateThread(thread_data)
  
  return id
end

function Actuator:abort(id)
  self.pending[id] = nil
end

function Actuator:add(action) assert(action and action.name and action.execute)
  self.actions[action.name] = action
end

function Actuator:getYsType()
  return "actuator"
end

--[[Methods to override]]--

function Actuator:isActive() return true end
function Actuator:isBusy(action, parameters) return false end

return Actuator