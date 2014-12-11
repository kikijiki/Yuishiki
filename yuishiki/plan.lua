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
  Plan.static.Condition = uti.makeEnum(
    "Success", "Failure", "Context", "Completion")
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
    if data.trigger then
      PlanClass.trigger = Trigger.fromData(table.unpack(data.trigger))
    end
    PlanClass.manage_subgoal_failure = data.manage_subgoal_failure or false
    PlanClass.describe = data.describe
    PlanClass.log = log.tag ("P-"..name)
    PlanClass.history_path = Plan.history_path.."."..name

    return PlanClass
  end

  function Plan.static.extend(name)
    return loader.class(plan_class_prefix..name, Plan)
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

  function Plan:waitForEvent(name)
    if not name then
      return self:yield()
    else
      return self:waitForTrigger(Trigger(name))
    end
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

  function Plan:record(result, state, max)
    local bb = self.bdi.belief_base
    local history = bb:get(self.history_path)

    if not history then
      history = setmetatable({}, {
        __tostring = function(t)
          local ret = {"{\n"}
          for _,v in pairs(t) do
            table.insert(ret, " - "..v.result)
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
      })
      bb:setLT(history, self.history_path)
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
