assert(ys, "Yuishiki is not loaded.")

local Event = ys.common.class("Event")
Event.Source = ys.common.uti.makeEnum("Internal", "External")
Event.EventType = ys.common.uti.makeEnum("Goal", "Message", "System", "Belief", "Actuator", "Custom")

function Event:initialize(event_type, name, source, parameters) assert(event_type)
  self.event_type = event_type
  self.source = source
  self.parameters = parameters or {}
end

local GoalEvent = ys.class("GoalEvent", Event)
Event.Goal = GoalEvent

function GoalEvent:initialize(goal) assert(goal)
  Event.initialize(self,
    Event.EventType.Goal,
    goal.name,
    Event.Source.Internal,
    {
      goal = goal
    })
end

local MessageEvent = ys.class("MessageEvent", Event)
Event.Message = MessageEvent

function MessageEvent:initialize(message) assert(message)
  Event.initialize(self,
    Event.EventType.Message,
    nil,
    Event.Source.Internal,
    { message = message })
end

local BeliefEvent = ys.class("BeliefEvent", Event)
Event.Belief = BeliefEvent

function BeliefEvent:initialize(belief, old, ...) assert(belief)
  Event.initialize(self,
    Event.EventType.Belief,
    belief.name,
    Event.Source.Internal,
    {
      old_value = old,
      belief = belief,
      params = {...}
    })

  self.description = "[Event - internal] belief <"..belief.name..">"
end

local BeliefSetEvent = ys.class("BeliefSetEvent", Event)
Event.Belief = BeliefEvent

function BeliefSetEvent:initialize(beliefset, change, key, ...) assert(beliefset) assert(change)
  Event.initialize(self,
    Event.EventType.Belief,
    beliefset.name,
    Event.Source.Internal,
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
    Event.Source.Internal,
    {...})
end

local ActuatorEvent = ys.class("ActuatorEvent", Event)
Event.Actuator = ActuatorEvent

function ActuatorEvent:initialize(id, finished, data)
  return Event.initialize(self,
    Event.EventType.Actuator,
    nil,
    Event.Source.Internal,
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
