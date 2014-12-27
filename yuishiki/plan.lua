--- The plan class.
--
-- Dependencies: `uti`, `log`, `Trigger`, `ManualTrigger`
--
-- @classmod Plan

local Plan

return function(loader)
  if Plan then return Plan end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"

  Plan = loader.class("Plan")

  Plan.static.Status = uti.makeEnum(
    "New", "Active", "Waiting", "Succeeded", "Failed", "Error")
  Plan.static.FailReason = uti.makeEnum(
    "Dropped", "BodyFailed", "SubgoalFailed", "ConditionFailed", "Unknown")
  Plan.static.history_path = "history.plan"

  local ResultHistory = loader.class("ResultHistory")
  Plan.ResultHistory = ResultHistory

  function ResultHistory:initialize(max)
    self.data = {}
    self.max = max
    self.skip = 1
  end

  function ResultHistory:record(result, state, max)
    table.insert(self.data, {result = result, state = state})
    self:trim(max)
  end

  function ResultHistory:trim(max)
    max = max or self.max
    if max then
      while #self.data > max do table.remove(self.data, 1) end
    end
  end

  function ResultHistory:match(state)
    if #self.data == 0 then return 0, 0 end

    local state_count = 0
    local sorted = {}
    for _,_ in pairs(state) do
      state_count = state_count + 1
      sorted[state_count] = {}
    end

    for _,record in pairs(self.data) do
      local matches = 0
      for k,v in pairs(state) do
        if record.state[k] == v then matches = matches + 1 end
      end
      table.insert(sorted[matches], record.result)
    end

    local skip = 0
    for i = state_count, 1, -1 do
      local entry = sorted[i]
      if #entry > 0 then
        if #entry <= self.skip then return 0, 0 end
        local average = 0
        table.sort(entry)
        for _,v in pairs(entry) do
          if skip < self.skip then skip = skip + 1
          else average = average + v end
        end
        average = average / #entry
        return i, average
      end
    end
    return 0, 0
  end

  function ResultHistory:__tostring()
    local ret = {"{\n"}
    for _,v in pairs(self.data) do
      table.insert(ret, " > "..v.result)
      table.insert(ret, " \t-> \t")
      local states = {}
      for k,s in pairs(v.state) do
        table.insert(states, k.."="..s)
      end
      table.insert(ret, table.concat(states, ",").."\n")
    end
    table.insert(ret, "}")
    return table.concat(ret)
  end

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
    local PlanClass = loader.class("P-"..name, Plan)

    PlanClass.static.data = data
    PlanClass.static.name = name

    PlanClass.initialize = function(self, bdi, parameters)
      Plan.initialize(self, bdi, parameters)
      self.name = name
      self.thread = coroutine.create(self.body)
      self.conditions = ManualTrigger(data.conditions)
      self.on = ManualTrigger(data.on)
    end

    PlanClass.body = data.body
    PlanClass.meta = data.meta or false
    PlanClass.efficiency = data.efficiency
    PlanClass.enabled = data.enabled
    if data.trigger then
      PlanClass.trigger = Trigger.fromData(table.unpack(data.trigger))
    end
    PlanClass.manage_subgoal_failure = data.manage_subgoal_failure or false
    PlanClass.describe = data.describe
    PlanClass.log = log.tag ("P-"..name)
    PlanClass.history_path = Plan.history_path.."."..name

    return PlanClass
  end

  function Plan:initialize(bdi, parameters)
    self.bdi = bdi
    self.parameters = parameters or {}
    self.status = Plan.Status.New
    self.step_count = 0
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

  function Plan:onEventTriggered(e)
    self.status = Plan.Status.Active
    self.wait.event = e
  end

  function Plan:waitForTrigger(trigger)
    if not trigger then
      return self:yield()
    else
      self.status = Plan.Status.Waiting
      self.wait = { trigger = trigger }
      self:yield()
      local event = self.wait.event
      self.wait = nil
      return event
    end
  end

  function Plan:waitForEvent(...)
    return self:waitForTrigger(Trigger(...))
  end

  function Plan:waitForBelief(...)
    return self:waitForTrigger(Trigger.belief(...))
  end

  function Plan:waitForActuator(id)
    if not id then
      return self:yield()
    else
      return self:waitForTrigger(Trigger.actuator(id))
    end
  end

  function Plan:pushSubGoal(goal, parameters)
    local goal_instance = self.bdi:pushGoal(goal, parameters, self.intention)
    self:yield()
    return goal_instance.result
  end

  function Plan:addGoal(goal, parameters)
    self.bdi:pushGoal(goal, parameters)
  end

  function Plan:pushSubPlan(plan, parameters)
    local plan_instance = self.bdi:pushPlan(plan, parameters, self.intention)
    self:yield()
    return plan_instance.results.last
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
      return string.format("[P](%s) <%s> {%s}",
        self.status, self.name, self:describe(self.parameters))
    else
      return string.format("[P](%s) <%s>", self.status, self.name)
    end
  end

  function Plan:record(...)
    local bb = self.bdi.belief_base
    local history = bb:get(self.history_path)

    if not history then
      history = ResultHistory()
      bb:setLT(history, self.history_path)
    else
      history = history:get()
    end

    history:record(...)
  end

  function Plan.static.match(plan, bb, ...)
    local history = bb.get(plan.history_path)
    if not history then
      return 0, 0
    else
      return history:match(...)
    end
  end

  return Plan
end
