local Event

return function(loader)
  if Event then return Event end

  local uti = loader.load "uti"

  --[[ Base ]]--

  Event = loader.class("Event")
  Event.static.Type = uti.makeEnum("Goal", "Message", "System", "Belief", "Actuator", "Custom")

  function Event:initialize(event_type, name, parameters) assert(event_type)
    self.event_type = event_type
    self.name = name
    self.parameters = parameters or {}
  end

  --[[ Goal ]]--

  local GoalEvent = loader.class("GoalEvent", Event)
  Event.Goal = GoalEvent

  function GoalEvent:initialize(goal) assert(goal)
    Event.initialize(self,
      Event.Type.Goal,
      goal.name,
      { goal = goal })
  end

  --[[ Message ]]--

  local MessageEvent = loader.class("MessageEvent", Event)
  Event.Message = MessageEvent

  function MessageEvent:initialize(sender, target, performative, message) assert(message)
    Event.initialize(self,
      Event.Type.Message,
      sender,
      {
        sender = sender,
        target = target,
        performative = performative,
        message = message
      })
  end

  --[[ Belief ]]--

  local BeliefEvent = loader.class("BeliefEvent", Event)
  Event.Belief = BeliefEvent

  function BeliefEvent:initialize(belief, status, new, old, ...) assert(belief)
    Event.initialize(self,
      Event.Type.Belief,
      belief.path,
      {
        belief = belief,
        status = status,
        new = new,
        old = old,
        args = {...}
      })
  end

  --[[ System ]]--

  local SystemEvent = loader.class("SystemEvent", Event)
  Event.System = SystemEvent

  function SystemEvent:initialize(name, ...) assert(name)
    return Event.initialize(self,
      Event.Type.System,
      name,
      {...})
  end

  function Event.static.fromData(event_type, ...)
    if not data then return end

    if event_type == "base"    then return Event        (...) end
    if event_type == "goal"    then return Event.Goal   (...) end
    if event_type == "belief"  then return Event.Belief (...) end
    if event_type == "message" then return Event.Message(...) end
    if event_type == "System"  then return Event.System (...) end
  end

  return Event
end
