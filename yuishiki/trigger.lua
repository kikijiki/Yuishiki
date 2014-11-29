--- The trigger class.
--
-- Dependencies: `middleclass`, `uti`, `log`, `Event`
--
-- @classmod Trigger

local Trigger

return function(loader)
  if Trigger then return Trigger end

  local uti = loader.load "uti"

  Trigger = loader.class("Trigger")

  function Trigger:initialize(event) assert(event)
    self.event = event
  end

  function Trigger:check(event)
    if not event then return false end
    for k,v in ipairs(self.event) do
      if event.name[k] ~= v then return false end
    end
    return true
  end

  function Trigger.goal(goal) return Trigger({"goal", goal}) end
  function Trigger.actuator(id) return Trigger({"actuator", id}) end

  local BeliefTrigger = loader.class("BeliefTrigger", Trigger)
  Trigger.belief = BeliefTrigger

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
    Trigger.initialize(self, {"belief", path})
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
    local path = event.name[2]
    if self.path_start and not uti.startsWith(path, self.path_start) then return false end
    if self.path_end and not uti.endsWith(path, self.path_end) then return false end

    -- Check conditions
    if self.condition then
      local new = event.new
      local old = event.old
      return self.condition(event, new, old, table.unpack(self.parameters))
    else
      return true
    end
  end

  function Trigger.static.fromData(trigger_type, ...)
    if trigger_type == "event"    then return Trigger         (...) end
    if trigger_type == "goal"     then return Trigger.goal    (...) end
    if trigger_type == "actuator" then return Trigger.actuator(...) end
    if trigger_type == "belief"   then
      local args = {...}
      local trigger = Trigger.belief(args[1])
      if args["begins"] then trigger:begins(args["begins"]) end
      if args["ends"] then trigger:ends(args["ends"]) end
      if args["condition"] then
        trigger:condition(table.unpack(args["condition"]))
      end
      return trigger
    end
  end

  return Trigger
end
