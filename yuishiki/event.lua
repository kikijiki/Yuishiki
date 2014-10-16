local class = require "lib.middleclass"
local uti = require "uti"

local Event = class("Event")
Event.EventType = uti.makeEnum("Goal", "Message", "System", "Belief", "Actuator", "Custom")

function Event:initialize(event_type, name, parameters) assert(event_type)
  self.event_type = event_type
  self.name = name
  self.parameters = parameters or {}
end

local GoalEvent = ys.class("GoalEvent", Event)
Event.Goal = GoalEvent

function GoalEvent:initialize(goal) assert(goal)
  Event.initialize(self,
    Event.EventType.Goal,
    goal.name,
    { goal = goal })
end

local MessageEvent = ys.class("MessageEvent", Event)
Event.Message = MessageEvent

function MessageEvent:initialize(message) assert(message)
  Event.initialize(self,
    Event.EventType.Message,
    nil,
    { message = message })
end

local BeliefEvent = ys.class("BeliefEvent", Event)
Event.Belief = BeliefEvent

function BeliefEvent:initialize(belief, old, ...) assert(belief)
  Event.initialize(self,
    Event.EventType.Belief,
    belief.name,
    {
      old_value = old,
      belief = belief,
      params = {...}
    })

  self.description = "[Event - internal] belief <"..belief.name..">"
end

local BeliefsetEvent = ys.class("BeliefsetEvent", Event)
Event.Beliefset = BeliefsetEvent

function BeliefsetEvent:initialize(beliefset, change, key, ...) assert(beliefset) assert(change)
  Event.initialize(self,
    Event.EventType.Belief,
    beliefset.name,
    {
      change = change,
      key = key,
      params = {...}
    })

  self.description = "[Event - internal] beliefset <"..beliefset.name.."> -> "..change.." "..key or ""
end

local SystemEvent = ys.class("SystemEvent", Event)
Event.System = SystemEvent

function SystemEvent:initialize(name, ...) assert(name)
  return Event.initialize(self,
    Event.EventType.System,
    name,
    {...})
end

local ActuatorEvent = ys.class("ActuatorEvent", Event)
Event.Actuator = ActuatorEvent

function ActuatorEvent:initialize(id, finished, data)
  return Event.initialize(self,
    Event.EventType.Actuator,
    nil,
    { id = id,
      finished = finished,
      data = data
    })
end

function Event:__tostring()
  if self.description then
    return self.description
  else
    local buf = {
      "[Event - ", self.source or "source unknown", "] ",
      self.name or "unknown"
    }
    return table.concat(buf)
  end
end

return Event
