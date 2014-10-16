return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local Goal = loader.load "goal"
  local Plan = loader.load "plan"
  local Stack = loader.load "stack"

  local Intention = class("Intention")

  local generateId = uti.makeIdGenerator("intention")

  function Intention:initialize()
    self.stack = Stack()
    self.active_goals = {}
    self.goal_count = {}
    self.id = generateId()
  end

  function Intention.getYsType()
    return "intention"
  end

  function Intention:top()
    return self.stack:top()
  end

  function Intention:empty()
    return self.stack:empty()
  end

  function Intention:step()
    self:checkConditions()

    local top = self:top()
    if not top then return end
                                                                                  ys.log.d("Intention top is "..top.getYsType().." <"..top.name..">") if top.status then ys.log.d("status -> "..top.status) end
    if top.getYsType() == "goal" then self:stepGoal(top) end
    if top.getYsType() == "plan" then self:stepPlan(top) end
  end

  function Intention:stepPlan(plan)
    if plan.status == Plan.Status.Active then                                     ys.log.d("Stepping in plan <"..plan.name..">")
      local err, data = plan:step()

      if err then
        plan:fail(Plan.FailReason.BodyFailed)                                     ys.log.d("Plan failed", data)
      end
      if plan:terminated() and not plan.status == Plan.Status.Failed then
        if plan.condition.default(true).completion() then
          plan:succeed()                                                          ys.log.d("Plan completed (success)")
        else
          plan:fail(Plan.FailReason.ConditionFailed)                              ys.log.d("Plan completed (failure)")
        end
      end
    end

    if plan.status == Plan.Status.Succeeded then
      self:pop()                                                                  ys.log.d("Popping plan (success)")
      local goal = self:top()
      goal:succeed()
    elseif plan.status == Plan.Status.Failed then
      self:pop()                                                                  ys.log.d("Popping plan (failure)")
      local goal = self:top()

      if goal.retry then
        -- TODO ? or it is managed somewhere else, can't remember.
      else
        goal:fail(Goal.FailReason.PlanFailed)
        self:pop()
      end
    end
  end

  function Intention:stepGoal(goal)
    if goal.status == Goal.Status.Active then                                     ys.log.d("Stepping in goal <"..goal.name..">")
      local plan = self.agent.bdi:processGoal(goal)
      if plan then
        self:push(plan)                                                           ys.log.d("Pushing new plan <"..plan.name..">")
        table.insert(goal.past.history, plan)
        goal.past.plans[plan.name] = true
        goal.past.last = plan
      else
        goal:fail(Goal.FailReason.NoPlansAvailable)                               ys.log.d("Could not find any plan")
      end

    end

    if goal.status == Goal.Status.Succeeded then
      self:pop()                                                                  ys.log.d("Popping plan (success)")
    elseif goal.status == Goal.Status.Failed then
      self:pop()                                                                  ys.log.d("Popping plan (failure)")
    end
  end

  function Intention:checkConditions()
    for k,v in self.stack:iterator() do -- check all from the bottom
      if v.getYsType() == "goal" then
        if self:checkGoalConditions(k, v) then break end
      elseif v.getYsType() == "plan" then
        if self:checkPlanConditions(k, v) then break end
      end
    end
  end

  function Intention:checkPlanConditions(index, plan)
    -- context condition
    if not plan.condition.default(true).context() then
      self:popn(self.stack.size - index)
      plan:fail(Plan.FailReason.ConditionFailed)
      return true
    end

    -- drop condition
    if plan.condition.default(false).failure() then
      self:popn(self.stack.size - index)
      plan:fail(Plan.FailReason.ConditionFailed)
      return true
    end

    -- success condition
    if plan.condition.default(false).success() then
      self:popn(self.stack.size - index)
      plan:succeed()
      return true
    end

    return false
  end

  function Intention:checkGoalConditions(index, goal)
    -- context condition
    if not goal.condition.default(true).context() then
      self:popn(self.stack.size - index)
      goal:fail(Goal.FailReason.ConditionFailed)
      return true
    end

    -- drop condition
    if goal.condition.default(false).failure() then
      self:popn(self.stack.size - index)
      goal:fail(Goal.FailReason.ConditionFailed)
      return true
    end

    -- success condition
    if goal.condition.default(false).success() then
      self:popn(self.stack.size - index)
      goal:succeed()
      return true
    end

    return false
  end

  function Intention:push(e)
    if not e then
      ys.log.w("Intention:push ignored (element is nil).")
      return
    end
    if e.getYsType() == "goal" then self:pushGoal(e)
    elseif e.getYsType() == "plan" then self:pushPlan(e)
    else ys.log.w("Intention:push ignored (not a plan nor a goal).") end
  end

  function Intention:pop()
    local top = self:top()
    if top.getYsType() == "goal" then return self:popGoal()
    elseif top.getYsType() == "plan" then return self:popPlan(e) end
  end

  function Intention:pushGoal(goal)
    self.stack:push(goal)
    goal:activate()
    self.active_goals[goal] = goal
    self.goal_count[goal.name] = (self.goal_count[goal.name] or 0) + 1
  end

  function Intention:popGoal()
    local goal = self.stack:pop()
    goal.on.deactivation()
    self.active_goals[goal] = nil
    self.goal_count[goal.name] = self.goal_count[goal.name] - 1
  end

  function Intention:pushPlan(plan)
    plan.intention = self
    plan.status = Plan.Status.Active
    plan.on.activation()
    self.stack:push(plan)
  end

  function Intention:popPlan()
    local plan = self.stack:pop()
    plan.on.deactivation()
  end

  -- TODO: this will skip on failure/success callbacks.
  function Intention:popn(n)
    local ret = {}
    for i = 1, n do
      table.insert(ret, self:pop())
    end
    return ret
  end

  function Intention:waiting()
    local top = self.stack:top()
    if not top then return true end

    if top:getYsType() == "plan" then
      return
        top.condition.default(false).wait() or
        top.status == Plan.Status.WaitEvent
    else
      return false
    end
  end

  return Intention
end
