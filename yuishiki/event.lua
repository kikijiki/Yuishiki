return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"

  --[[ Base ]]--

  local Event = class("Event")
  Event.static.Type = uti.makeEnum("Goal", "Message", "System", "Belief", "Actuator", "Custom")

  function Event:initialize(event_type, name, parameters) assert(event_type)
    self.event_type = event_type
    self.name = name
    self.parameters = parameters or {}
  end

  --[[ Goal ]]--

  local GoalEvent = class("GoalEvent", Event)
  Event.Goal = GoalEvent

  function GoalEvent:initialize(goal) assert(goal)
    Event.initialize(self,
      Event.Type.Goal,
      goal.name,
      { goal = goal })
  end

  --[[ Message ]]--

  local MessageEvent = class("MessageEvent", Event)
  Event.Message = MessageEvent

  function MessageEvent:initialize(message) assert(message)
    Event.initialize(self,
      Event.Type.Message,
      nil,
      { message = message })
  end

  --[[ Belief ]]--

  local BeliefEvent = class("BeliefEvent", Event)
  Event.Belief = BeliefEvent

  function BeliefEvent:initialize(belief, status, new, old) assert(belief)
    Event.initialize(self,
      Event.Type.Belief,
      belief.full_path,
      {
        belief = belief,
        status = status,
        new = new,
        old = old
      })
  end

  --[[ System ]]--

  local SystemEvent = class("SystemEvent", Event)
  Event.System = SystemEvent

  function SystemEvent:initialize(name, ...) assert(name)
    return Event.initialize(self,
      Event.Type.System,
      name,
      {...})
  end

  return Event
end
