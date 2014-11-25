--- The trigger class.
--
-- Dependencies: `middleclass`, `uti`, `log`, `Event`
--
-- @classmod Trigger

local Trigger

return function(loader)
  if Trigger then return Trigger end

  local uti = loader.load "uti"
  local Event = loader.load "event"

  Trigger = loader.class("Trigger")

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

  local ParametrizedTrigger = loader.class("ParametrizedTrigger", Trigger)
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

  local GoalTrigger = loader.class("GoalTrigger", ParametrizedTrigger)
  Trigger.Goal = GoalTrigger

  function GoalTrigger:initialize(goal_name, goal_parameters)
    ParametrizedTrigger.initialize(self, Event.Type.Goal, goal_name, goal_parameters)
  end

  --[[ Custom Trigger ]]--

  local CustomTrigger = loader.class("CustomTrigger", Trigger)
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

  local BeliefTrigger = loader.class("BeliefTrigger", Trigger)
  Trigger.Belief = BeliefTrigger

  BeliefTrigger.static.conditions = {
    ["equal"]         = function(e, new, old, p)      return new == p                end,
    ["changed"]       = function(e, new, old)         return new ~= old              end,
    ["at least"]      = function(e, new, old, p)      return new >= p                end,
    ["at most"]       = function(e, new, old, p)      return new <= p                end,
    ["more than"]     = function(e, new, old, p)      return new >  p                end,
    ["less than"]     = function(e, new, old, p)      return new <  p                end,
    ["increased"]     = function(e, new, old)         return new >  old              end,
    ["decreased"]     = function(e, new, old)         return old >  new              end,
    ["not increased"] = function(e, new, old)         return new <= old              end,
    ["not decreased"] = function(e, new, old)         return old >= new              end,
    ["range"]         = function(e, new, old, p1, p2) return new <= p2 and new >= p1 end,
    ["range ex"]      = function(e, new, old, p1, p2) return new <  p2 and new >  p1 end,
  }

  function BeliefTrigger:initialize(path, condition, ...)
    Trigger.initialize(self, Event.Type.Belief, path)
    self.path_start = path
    self.path_end = path
    self:condition(condition, ...)
  end

  function BeliefTrigger:starts(path)
    if path == "*" then path = nil end
    self.path_start = path
    return self
  end

  function BeliefTrigger:ends(path)
    if path == "*" then path = nil end
    self.path_end = path
    return self
  end

  function BeliefTrigger:condition(condition, ...)
    if not condition then return end
    if type(condition) == "function" then self.condition = condition end
    if type(condition) == "string" then self.condition = BeliefTrigger.conditions[condition] end
    self.parameters = {...}
    return self
  end

  function BeliefTrigger:check(event)
    -- Check path
    if self.path_start and not uti.startsWith(event.name, self.path_start) then return false end
    if self.path_end and not uti.endsWith(event.name, self.path_end) then return false end

    -- Check conditions

    if self.condition then
      local new = event.parameters.new
      local old = event.parameters.old
      return self.condition(event, new, old, table.unpack(self.parameters))
    else
      return true
    end
  end

  function Trigger.static.fromData(trigger_type, ...)
    if trigger_type == "event"        then return Trigger             (...) end
    if trigger_type == "goal"         then return Trigger.Goal        (...) end
    if trigger_type == "parametrized" then return Trigger.Parametrized(...) end
    if trigger_type == "custom"       then return Trigger.Custom      (...) end
    if trigger_type == "belief"       then
      local args = {...}
      local trigger = Trigger.Belief(args[1])
      if args["begins"] then trigger:begins(args["begins"]) end
      if args["ends"] then trigger:ends(args["ends"]) end
      if args["condition"] then trigger:condition(table.unpack(args["condition"])) end
      return trigger
    end
  end

  return Trigger
end
