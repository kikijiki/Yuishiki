local Trigger = ys.common.class("Trigger")
Trigger.static.TriggerMode = ys.common.uti.makeEnum("Event", "Goal")

local Event = ys.mas.Event

function Trigger:initialize(trigger_mode, parameters) assert(trigger_mode)
  self.trigger_mode = trigger_mode
  self.parameters = parameters
end

function Trigger:check()
  return true
end

local EventTrigger = ys.class("EventTrigger", Trigger)
Trigger.Event = EventTrigger

function EventTrigger:initialize(event_name, parameters)
  Trigger.initialize(self, Trigger.TriggerMode.Event, parameters)
  self.event_name = event_name
end

function EventTrigger:check(event)
  if not event then return false end

  -- TODO: class of events?
  if not self.event_name then return true end
  if event.event_type ~= self.event_name then return false end
  
  local tp = self.parameters
  local ep = event.parameters
  
  if tp == nil then return true end
  if ep == nil then return false end
  
  -- Condition: non-nil trigger parameters must be equal.
  for k,v in pairs(tp) do
    if ep[k] ~= v then return false end
  end
  
  return true
end

local CustomEventTrigger = ys.common.class("CustomEventTrigger", Trigger)
Trigger.CustomEvent = CustomEventTrigger

function CustomEventTrigger:initialize(f, parameters) assert(f)
  Trigger.initialize(self, Trigger.TriggerMode.Event, parameters)
  self.trigger_function = f
end

function CustomEventTrigger:check(event)
  return self.trigger_function(self, event)
end

local GoalTrigger = ys.class("GoalTrigger", Trigger)
Trigger.Goal = GoalTrigger

function GoalTrigger:initialize(goal_name)
  Trigger.initialize(self, Trigger.TriggerMode.Goal, {goal_name = goal_name})
end

function Trigger.static.fromData(data)
  if not data then return end
  local trigger_type = data[1]
  if trigger_type == "goal" then return Trigger.Goal(select(2, unpack(data))) end
  if trigger_type == "event" then return Trigger.Event(select(2, unpack(data))) end
  if trigger_type == "custom" then return Trigger.Custom(select(2, unpack(data))) end
end

return Trigger