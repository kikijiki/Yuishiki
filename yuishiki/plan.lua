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

  Plan.static.Status = uti.makeEnum("New", "Active", "Waiting", "Succeeded", "Failed", "Error")
  Plan.static.FailReason = uti.makeEnum("Dropped", "BodyFailed", "SubgoalFailed", "ConditionFailed", "Unknown")
  Plan.static.Condition = uti.makeEnum("Success", "Failure", "Context", "Completion")
  Plan.static.history_path = "history.plan"

  --- Create a new plan class from the definition data.
  -- The following can be specified:
  --
  -- - `body`: a function defining the main code of the plan.
  -- - `meta`: true if the plan is a metaplan (optional, default = false).
  -- - `efficiency`: a function returning a value that represents how good this plan is in the current situation (optional).
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
    local PlanClass = loader.class("plan_"..name, Plan)

    PlanClass.static.default = data
    PlanClass.static.name = name

    PlanClass.initialize = function(self, agent, parameters)
      Plan.initialize(self, agent, parameters)
      self.name = name
      self.thread = coroutine.create(self.body)
      self.step_count = 0
    end

    PlanClass.body = data.body
    PlanClass.meta = data.meta or false
    PlanClass.efficiency = data.efficiency
    PlanClass.trigger = Trigger.fromData(data.trigger)
    PlanClass.conditions = ManualTrigger(data.conditions)
    PlanClass.on = ManualTrigger(data.on)
    PlanClass.manage_subgoal_failure = data.manage_subgoal_failure or false
    PlanClass.describe = data.describe
    PlanClass.log = log.tag ("P "..name)
    PlanClass.history_path = Plan.history_path.."."..name

    return PlanClass
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

    local ok, ret = coroutine.resume(self.thread, table.unpack(self.exported))

    table.insert(self.results.history, ret)
    self.results.last = ret

    if err then
      self.log.w("Error in plan body.", table.unpack(ret))
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

  Plan.log = log

  function Plan:__tostring()
    if self.describe then
      return "[P]("..self.status..") <"..self.name.."> {"..self:describe(self.parameters).."}"
    else
      return "[P]("..self.status..") <"..self.name..">"
    end
  end

  function Plan:record(result, state, max)
    local bb = self.agent.bdi.belief_base
    local history = bb:get(self.history_path)

    if not history then
      history = {}
      bb:setLong(history, self.history_path)
    else
      history = history:get()
    end

    table.insert(history, {result = result, state = state})

    if max then
      while #history > max do table.remove(history, 1) end
    end
  end

  function Plan.static.matchHistory(plan, bb, state)
    local history = bb.get(plan.history_path)

    if not history or #history == 0 then return 0, 0 end

    local state_count = 0
    for _,_ in pairs(state) do state_count = state_count + 1 end
    local best = {matches = 0, records = {}}

    for _,record in pairs(history) do
      local matches = 0
      for k,v in pairs(state) do
        if record.state[k] == v then matches = matches + 1 end
      end
      if matches > 0 then
        if matches > best.matches then
          best.matches = matches
          best.records = {record}
        elseif matches == best.matches then
          table.insert(best.records, record)
        end
      end
    end

    if best.matches == 0 then return 0, 0 end

    local average = 0
    for _,record in pairs(best.records) do
      average = average + record.result
    end
    average = average / #best.records
    local matches = best.matches / state_count

    return matches, average
  end

  return Plan
end
