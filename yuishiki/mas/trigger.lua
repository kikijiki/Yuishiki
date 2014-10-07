local Trigger = ys.common.class("Trigger")
local Event = ys.mas.Event
local EventType = Event.EventType

function Trigger:initialize(event_type, parameters) assert(trigger_mode)
  self.event_type = event_type
  self.parameters = parameters
end

function Trigger:check()
  return true
end

local EventTrigger = ys.class("EventTrigger", Trigger)
Trigger.Event = EventTrigger

function EventTrigger:initialize(event_name, parameters)
  Trigger.initialize(self, nil, parameters)
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
  Trigger.initialize(self, nil, parameters)
  self.trigger_function = f
end

function CustomEventTrigger:check(event)
  return self.trigger_function(self, event)
end

local GoalTrigger = ys.class("GoalTrigger", Trigger)
Trigger.Goal = GoalTrigger

function GoalTrigger:initialize(goal_name)
  Trigger.initialize(self, EventType.Goal, {goal_name = goal_name})
end

local BeliefTrigger = ys.common.class("BeliefTrigger", Trigger)
Trigger.Belief = BeliefTrigger

function BeliefTrigger:initialize(name, condition, ...) assert(name) assert(BeliefTrigger.conditions[condition])
  Trigger.initialize(self, EventType.Belief, {
    belief_name = name,
    condition = condition,
    values = {...}
  })
end

BeliefTrigger.static.conditions = {
  equal         = function(old, new, p)      return new == p                end
  changed       = function(old, new)         return old ~= new              end,
  at_least      = function(old, new, p)      return new >= p                end,
  at_most       = function(old, new, p)      return new <= p                end,
  more_than     = function(old, new, p)      return new >  p                end,
  less_than     = function(old, new, p)      return new <  p                end,
  increased     = function(old, new)         return new >  old              end,
  decreased     = function(old, new)         return old >  new              end,
  not_increased = function(old, new)         return new <= old              end,
  not_decreased = function(old, new)         return old >= new              end,  
  in_range      = function(old, new, p1, p2) return new <= p2 and new >= p1 end
  in_range_ex   = function(old, new, p1, p2) return new <  p2 and new > p1  end
}

function BeliefTrigger:check(event)
  if not event then return false end
  if event.event_type ~= Event.EventType.Belief then return false end
  local old = event.parameters.old_value
  local new = event.parameters.belief:get()
  local condition = BeliefTrigger.conditions[self.parameters.condition]
  return condition(old, new, unpack(self.values))
end

function Trigger.static.fromData(data)
  if not data then return end
  local trigger_type = data[1]
  if trigger_type == "goal" then return Trigger.Goal(select(2, unpack(data))) end
  if trigger_type == "event" then return Trigger.Event(select(2, unpack(data))) end
  if trigger_type == "custom" then return Trigger.Custom(select(2, unpack(data))) end
end

return Trigger