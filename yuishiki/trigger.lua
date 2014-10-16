return function(loader)
local class = loader.require "middleclass"
local Event = loader.load "event"

  local Trigger = class("Trigger")
  local EventType = Event.EventType

  --[[ Trigger ]]--

  function Trigger:initialize(event_type, event_name) assert(event_type)
    self.event_type = event_type
    self.event_name = event_name
  end

  function Trigger:check(event)
    if not event then return false end
    if event.event_type ~= self.event_type then return false end
    if self.event_name then
      return self.event_name == event.name
    else
      return true
    end
  end

  --[[ Parametrized Trigger ]]--

  local ParametrizedTrigger = class("ParametrizedTrigger", Trigger)
  Trigger.Parametrized = ParametrizedTrigger

  function ParametrizedTrigger:initialize(event_type, event_name, parameters)
    Trigger.initialize(self, event_type, event_name)
    self.parameters = parameters
  end

  function ParametrizedTrigger:check(event)
    if not Trigger.check(self, event) then return false end

    local tp = self.parameters
    local ep = event.parameters

    -- Condition: non-nil trigger parameters must be equal.
    if tp == nil then return true end
    if ep == nil then return false end

    for k,v in pairs(tp) do
      if ep[k] ~= v then return false end
    end

    return true
  end

  --[[ Goal Trigger ]]--

  local GoalTrigger = class("GoalTrigger", ParametrizedTrigger)
  Trigger.Goal = GoalTrigger

  function GoalTrigger:initialize(goal_name, goal_parameters)
    ParametrizedTrigger.initialize(self, EventType.Goal, goal_name, goal_parameters)
  end

  --[[ Custom Trigger ]]--

  local CustomTrigger = class("CustomTrigger", Trigger)
  Trigger.Custom = CustomTrigger

  function CustomTrigger:initialize(event_type, event_name, f, parameters)
    assert(f)

    Trigger.initialize(self, event_type, event_name)
    self.parameters = parameters
    self.trigger_function = f
  end

  function CustomTrigger:check(event)
    if not Trigger.check(self, event) then return false end
    return self.trigger_function(self, event, self.parameters)
  end

  --[[ Belief Trigger ]]--

  local BeliefTrigger = class("BeliefTrigger", CustomTrigger)
  Trigger.Belief = BeliefTrigger

  BeliefTrigger.static.conditions = {
    equal         = function(old, new, p)      return new == p                end,
    changed       = function(old, new)         return old ~= new              end,
    at_least      = function(old, new, p)      return new >= p                end,
    at_most       = function(old, new, p)      return new <= p                end,
    more_than     = function(old, new, p)      return new >  p                end,
    less_than     = function(old, new, p)      return new <  p                end,
    increased     = function(old, new)         return new >  old              end,
    decreased     = function(old, new)         return old >  new              end,
    not_increased = function(old, new)         return new <= old              end,
    not_decreased = function(old, new)         return old >= new              end,
    in_range      = function(old, new, p1, p2) return new <= p2 and new >= p1 end,
    in_range_ex   = function(old, new, p1, p2) return new <  p2 and new > p1  end,
  }

  function BeliefTrigger:initialize(name, condition, ...)
    assert(name)
    assert(BeliefTrigger.conditions[condition])

    CustomTrigger.initialize(self, EventType.Belief, name,
      function(trigger, event, parameters)
        local old = event.parameters.old_value
        local new = event.parameters.belief:get()
        local f = BeliefTrigger.conditions[condition]
        return f(old, new, unpack(trigger.parameters))
      end,
      {...})
  end

  function Trigger.static.fromData(data)
    if not data then return end
    local trigger_type = data[1]
    local args = {select(2, unpack(data))}

    if trigger_type == "event"        then return Trigger             (unpack(args)) end
    if trigger_type == "goal"         then return Trigger.Goal        (unpack(args)) end
    if trigger_type == "parametrized" then return Trigger.Parametrized(unpack(args)) end
    if trigger_type == "custom"       then return Trigger.Custom      (unpack(args)) end
    if trigger_type == "belief"       then return Trigger.Belief      (unpack(args)) end
  end

  return Trigger
end
