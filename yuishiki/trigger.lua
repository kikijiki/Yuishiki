return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local Event = loader.load "event"
  local Trigger = class("Trigger")

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

  local BeliefTrigger = class("BeliefTrigger", Trigger)
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

  function BeliefTrigger:initialize(path, condition, ...)
    Trigger.initialize(self, Event.Type.Belief, path)
    self.path_start = path
    self.path_end = path
    self.condition = condition
    self.parameters = {...}
  end

  function BeliefTrigger:starts(path)
    if path = "*" then path = nil end
    self.path_start = path
    return self
  end

  function BeliefTrigger:ends(path)
    if path = "*" then path = nil end
    self.path_end = path
    return self
  end

  function BeliefTrigger:condition(f, ...)
    self.condition = f
    self.parameters = {...}
    return self
  end

  function BeliefTrigger:check(event)
    -- Check path

    if self.path_start and not uti.startsWith(event.name, self.path_start) then return false end
    if self.path_end and not uti.endsWith(event.name, self.path_end) then return false end

    -- Check conditions

    local old = event.parameters.old_value
    local new = event.parameters.belief:get()

    if self.condition then
      local condition
      if type(self.condition) == "function" then
        return BeliefTrigger.conditions[self.condition](old, new, unpack(self.parameters))
      else
        return condition(old, new, unpack(self.parameters))
      end
    end

    return true
  end

  function Trigger.static.fromData(data)
    if not data then return end
    local trigger_type = data[1]
    local args = {select(2, unpack(data))}

    if trigger_type == "event"        then return Trigger             (unpack(args)) end
    if trigger_type == "goal"         then return Trigger.Goal        (unpack(args)) end
    if trigger_type == "parametrized" then return Trigger.Parametrized(unpack(args)) end
    if trigger_type == "custom"       then return Trigger.Custom      (unpack(args)) end
    if trigger_type == "belief"       then
      local trigger = Trigger.Belief(args[1])
      if args["begins"] then trigger:begins(args["begins"]) end
      if args["ends"] then trigger:ends(args["ends"]) end
      if args["condition"] then trigger:condition(unpack(args["condition"])) end
      return trigger
    end
  end

  return Trigger
end
