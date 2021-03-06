local Intention

return function(loader)
  if Intention then return Intention end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Goal = loader.load "goal"
  local Plan = loader.load "plan"
  local Stack = loader.load "stack"

  local Intention = loader.class("Intention")

  local generateId = uti.makeIdGenerator("I")

  function Intention:initialize(bdi)
    self.bdi = bdi
    self.stack = Stack()
    self.id = generateId()
    self.log = log.tag(self.id)
    self.name = "empty"
  end

  function Intention.getYsType()
    return "intention"
  end

  function Intention:top()
    return self.stack:top()
  end

  function Intention:bottom()
    return self.stack:bottom()
  end

  function Intention:pairs(n)
    return self.stack:pairs(n)
  end

  function Intention:isEmpty()
    return self.stack:isEmpty()
  end

  function Intention:step()
    local top = self:top()
    if not top then return end

    if top.getYsType() == "goal" then self:stepGoal(top) end
    if top.getYsType() == "plan" then self:stepPlan(top) end
  end

  function Intention:stepPlan(plan)
    self.log.i("Stepping in plan", plan)
    if plan.status == Plan.Status.Succeeded then
      self:pop()
      local goal = self:top()
      if goal then goal:succeed(plan.results.last) end
    elseif plan.status == Plan.Status.Failed then
      self:pop()
      local goal = self:top()
      if not goal then return end
      if goal.retry then
        self.bdi.goal_base:release(goal.name, self)
        goal.status = Goal.Status.WaitingAvailability
      else
        goal:fail(Goal.FailReason.PlanFailed)
      end
    else
      plan:step()
    end
  end

  function Intention:stepGoal(goal)
    self.log.i("Stepping in goal", goal)
    if goal.status == Goal.Status.Active then
      local plan = self.bdi:processGoal(goal, self)
      if plan then
        table.insert(goal.past.history, plan)
        goal.past.plans[plan.name] = true
        goal.past.length = goal.past.length + 1
        goal.past.last = plan
      else
        self.log.i("Could not find any plan")
        goal:fail(Goal.FailReason.NoPlansAvailable)
      end
    end

    if goal.status == Goal.Status.Succeeded then
      self:pop()
    elseif goal.status == Goal.Status.Failed then
      self:pop()
      local plan = self:top()
      if plan then plan:fail(Plan.FailReason.SubgoalFailed) end
    end
  end

  function Intention:checkConditions()
    for k,v in self.stack:pairs() do -- check all from the bottom
      if v.getYsType() == "goal" then
        if self:checkGoalConditions(k, v) then break end
      elseif v.getYsType() == "plan" then
        if self:checkPlanConditions(k, v) then break end
      end
    end
  end

  function Intention:checkPlanConditions(index, plan)
    local sub_count = self.stack.size - index

    -- context condition
    if not plan.conditions.default(true).context() then
      self.log.fi("Plan [%s] context condition failed, popping %d elements",
        plan.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      plan:fail(Plan.FailReason.ConditionFailed)
      return true
    end

    -- failure condition
    if plan.conditions.default(false).failure() then
      self.log.fi("Plan [%s] failure condition, popping %d elements",
        plan.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      plan:fail(Plan.FailReason.ConditionFailed)
      return true
    end

    -- success condition
    if plan.conditions.default(false).success() then
      self.log.fi("Plan [%s] success condition, popping %d elements",
        plan.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      plan:succeed()
      return true
    end

    return false
  end

  function Intention:checkGoalConditions(index, goal)
    local sub_count = self.stack.size - index

    -- context condition
    if not goal.conditions.default(true).context() then
      self.log.fi("Goal [%s] context condition, popping %d elements",
        goal.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      goal:fail(Goal.FailReason.ConditionFailed)
      return true
    end

    -- failure condition
    if goal.conditions.default(false).failure() then
      self.log.fi("Goal [%s] failure condition, popping %d elements",
        goal.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      goal:fail(Goal.FailReason.ConditionFailed)
      return true
    end

    -- success condition
    if goal.conditions.default(false).success() then
      self.log.fi("Goal [%s] success condition, popping %d elements",
        goal.name, sub_count)
      self:popn(sub_count, true)
      self:dump()
      goal:succeed()
      return true
    end

    return false
  end

  function Intention:push(e)
    if not e then
      self.log.w("Intention:push ignored (element is nil).")
      return
    end

    e.intention = self
    if self.stack:isEmpty() then self.name = e.name end

    if e.getYsType() == "goal" then self:pushGoal(e)
    elseif e.getYsType() == "plan" then self:pushPlan(e)
    else self.log.w("Intention:push ignored (not a plan nor a goal).") end

    if self.stack.size > 1 then self:dump() end
  end

  function Intention:pop(nodump)
    local top = self:top()
    if top.getYsType() == "goal" then return self:popGoal(nodump)
    elseif top.getYsType() == "plan" then return self:popPlan(nodump) end
  end

  function Intention:pushGoal(goal)
    self.stack:push(goal)
    goal:prepare()
    self.log.i("Pushed new goal ", goal)
  end

  function Intention:popGoal(nodump)
    local goal = self.stack:pop()
    goal.on.deactivation()
    self.log.i("Popped goal ", goal)
    if not nodump then self:dump() end
  end

  function Intention:pushPlan(plan)
    plan.intention = self
    plan.status = Plan.Status.Active
    plan.on.activation()
    self.stack:push(plan)
    self.log.i("Pushed new plan ", plan)
  end

  function Intention:popPlan(nodump)
    local plan = self.stack:pop()
    plan.on.deactivation()
    self.log.i("Popped plan ", plan)
    if not nodump then self:dump() end
  end

  function Intention:popn(n, nodump)
    local ret = {}
    for i = 1, n do
      local e = self:pop(nodump)
      if e then table.insert(ret, e) end
    end
    return ret
  end

  function Intention:waiting()
    local top = self.stack:top()
    if not top then return false end

    if top:getYsType() == "plan" then
      return
        top.conditions.default(false).wait() or
        top.status == Plan.Status.Waiting
    elseif top:getYsType() == "goal" then
      return top.status == Goal.Status.WaitingAvailability
    end
  end

  function Intention:getGoalCount(goal_name)
    local count = 0
    for _,v in self.stack:pairs() do
      if v:getYsType() == "goal" and v.name == goal_name then
        count = count + 1
      end
    end
    return count
  end

  function Intention:__tostring()
    local top = self:top()
    if top then
      return string.format("[I](%s) <%s(%d)> priority: %05.2f",
        top.status, self.id, self.stack.size, self:getPriority())
    else
      return string.format("[I] <%s(empty)>", self.id)
    end
  end

  function Intention:getPriority()
    for k,v in self:pairs() do
      if v:getYsType() == "goal" then return v:getPriority() end
    end
    return 0
  end

  function Intention:resume(bdi)
    if self:isEmpty() then return end
    local top = self:top()
    if top:getYsType() == "goal" then
      if top.status == Goal.Status.WaitingAvailability then
        bdi.goal_base:reserve(top, self)
      end
    end
  end

  function Intention:dump()
    self.log.i(self)
    local i = 1
    for _,element in pairs(self.stack.elements) do
      local indent = string.rep("-", i)
      self.log.fi("%s %s", indent, tostring(element))
      i = i + 1
    end
  end

  return Intention
end
