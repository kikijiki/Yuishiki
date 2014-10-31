--- The plan class.
--
-- Dependencies: `middleclass`, `uti`, `log`, `Trigger`, `ManualTrigger`, `Event`
--
-- @classmod Plan

local Plan

return function(loader)
  if Plan then return Plan end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"
  local Event = loader.load "event"

  Plan = loader.class("Plan")
  local plan_class_prefix = "plan_"

  Plan.static.Status = uti.makeEnum("New", "Active", "Waiting", "Succeeded", "Failed", "Error")
  Plan.static.FailReason = uti.makeEnum("Dropped", "BodyFailed", "SubgoalFailed", "ConditionFailed", "Unknown")
  Plan.static.Condition = uti.makeEnum("Success", "Failure", "Context", "Completion")

  --- Create a new plan class from the definition data.
  -- The following can be specified:
  --
  -- - `body`: a function defining the main code of the plan.
  -- - `meta`: true if the plan is a metaplan (optional, default = false).
  -- - `confidence`: a function returning a value that represents how good this plan is in the current situation (optional).
  -- - `trigger`: definition of the creation trigger of the plan.
  -- - `conditions`: definition of a manual trigger for [completion, context, initial, failure, success].
  -- - `on`: definition of a manual trigger for [success, failure, yield, resume].
  -- - `manage\_subgoal\_failure`: if true, when a subgoal fails the plan must not fail automatically (optional, default = true).
  --
  -- All the functions are called with these arguments: `agent, plan, parameters, beliefs, actuator`.
  -- @param name the name of the plan
  -- @param data a table containing the definitions
  -- @return the new class.
  -- @usage this is used when including a module.
  -- @see Trigger
  function Plan.static.define(name, data)
    local P = loader.class(plan_class_prefix..name, Plan)

    P.static.default = data
    P.static.members = {
      "name", "body", "meta", "confidence", "triggers", "conditions",
      "on", "manage_subgoal_failure", "describe" }

    P.static.name = name
    P.static.body = data.body
    P.static.meta = data.meta or false
    P.static.confidence = data.confidence
    P.static.trigger = Trigger.fromData(data.trigger)
    P.static.conditions = ManualTrigger(data.conditions)
    P.static.on = ManualTrigger(data.on)
    P.static.manage_subgoal_failure = data.manage_subgoal_failure or false
    P.static.describe = data.describe

    P.initialize = function(self, agent, parameters)
      Plan.initialize(self, agent, parameters)
      for _,v in pairs(P.members) do self[v] = P[v] end
      self.thread = coroutine.create(self.body)
      self.step_count = 0
    end

    return P
  end

  function Plan.static.extend(name)
    return loader.class(plan_class_prefix..name, Plan)
  end

  function Plan:initialize(agent, parameters, goal) assert(agent)
    self.parameters = parameters or {}
    self.goal = goal
    self.agent = agent
    self.status = Plan.Status.New
    self.results = {history = {}, last = nil}
  end

  function Plan.getYsType()
    return "plan"
  end

  function Plan:bind(...)
    self.exported = {...}
    self.on.setDefaultArguments(...)
    self.conditions.setDefaultArguments(...)
  end

  function Plan:step()
    if self.status ~= Plan.Status.Active then return end

    self.on.step()
    self.step_count = self.step_count + 1

    local ret = {coroutine.resume(self.thread, table.unpack(self.exported))}

    local err = table.remove(ret, 1) == false
    table.insert(self.results.history, ret)
    self.results.last = ret

    if err then
      log.w("Error in plan body.", table.unpack(ret))
      self:fail(Plan.FailReason.BodyFailed)
    end

    if self:terminated() and self.status ~= Plan.Status.Failed then
      if self.conditions.default(true).completion() then
        self:succeed()
      else
        self:fail(Plan.FailReason.ConditionFailed)
      end
    end

    return ret
  end

  -- TODO: refactor
  function Plan:onEventTriggered(e)
    self.status = Plan.Status.Active
    self.wait.data = e
  end

  function Plan:waitForTrigger(trigger)
    if not trigger then
      return self:yield()
    else
      self.status = Plan.Status.Waiting
      self.wait = { trigger = trigger }
      self:yield()
      local result = self.wait.result
      self.wait = nil
      return result
    end
  end

  function Plan:waitForEvent(name, parameters)
    if not name then
      return self:yield()
    else
      local trigger = Trigger.Event(name, parameters)
      return self:waitForTrigger(trigger)
    end
  end

  function Plan:waitForBelief(...)
    return self:waitForTrigger(Trigger.Belief(...))
  end

  function Plan:waitForActuator(id)
    if not id then
      return self:yield()
    else
      local trigger = Trigger.Event(Event.EventType.Actuator, {id = id})
      return self:waitForTrigger(trigger)
    end
  end

  function Plan:pushSubGoal(goal, parameters)
    local goal_instance = self.agent.bdi:pushGoal(goal, parameters, self.intention)
    self:yield()
    return goal_instance.result
  end

  function Plan:fail(reason)
    if type(reason) == "string" then reason = Plan.FailReason[reason] end
    self.status = Plan.Status.Failed
    self.fail_reason = reason or Plan.FailReason.Unknown
    self.on.failure()
  end

  function Plan:succeed()
    self.status = Plan.Status.Succeeded
    self.on.success()
  end

  function Plan:terminated()
    return self.thread == nil or coroutine.status(self.thread) == "dead"
  end

  function Plan:yield(...) assert(self)
    self.on.yield()
    coroutine.yield(...)
    self.on.resume()
  end

  function Plan:__tostring()
    if self.describe then
      return "[P]("..self.status..") <"..self.name.."> {"..self:describe(self.parameters).."}"
    else
      return "[P]("..self.status..") <"..self.name..">"
    end
  end

  return Plan
end
