local BDIModel

return function(loader)
  if BDIModel then return BDIModel end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Observable = loader.load "observable"
  local Event = loader.load "event"
  local Intention = loader.load "intention"
  local BeliefBase = loader.load "belief-base"
  local GoalBase = loader.load "goal-base"
  local PlanBase = loader.load "plan-base"
  local IntentionBase = loader.load "intention-base"

  BDIModel = loader.class("BDIModel", Observable)

  function BDIModel:initialize(agent)
    Observable.initialize(self)

    self.agent = agent
    self.log = log.tag("BDI")

    self.belief_base    = BeliefBase()
    self.goal_base      = GoalBase(self)
    self.plan_base      = PlanBase(self)
    self.intention_base = IntentionBase(self)
    self.actuator       = agent.actuator
    self.functions      = {}

    local dispatcher = function(...) return self:dispatch(...) end
    self.belief_base   :addObserver(self, dispatcher)
    self.goal_base     :addObserver(self, dispatcher)
    self.plan_base     :addObserver(self, dispatcher)
    self.intention_base:addObserver(self, dispatcher)

    self.export = {
      beliefs = self.belief_base.interface,
      actuator = self.actuator.interface
    }
  end

  function BDIModel:dispatch(event)
    self.goal_base:onEvent(event)
    self.plan_base:onEvent(event)
    self.intention_base:onEvent(event)
  end

  function BDIModel:selectIntention()
    if self.functions.selectIntention then
      return self.functions.selectIntention(self, self.intention_base)
    end

    -- Default
    -- Get the highest priority intention wich is not waiting.
    local sorted_intentions = {}
    for _,intention in pairs(self.intention_base.intentions) do
      table.insert(sorted_intentions, intention)
    end

    table.sort(sorted_intentions,
      function(a, b)
        return a:getPriority() > b:getPriority()
      end)

    for _,intention in ipairs(sorted_intentions) do
      intention:resume(self)
      if not intention:waiting() then return intention end
    end
  end

  function BDIModel:selectPlan(goal, options)
    if not options or #options == 0 then return end

    if self.functions.selectBestPlan then
      return self.functions.selectPlan(self, goal, options)
    end

    -- Default
    local best
    local best_efficiency = 0
    for _,schema in pairs(options) do
      local efficiency = self.plan_base:getEfficiency(schema, goal)
      if type(efficiency) ~= "number" then efficiency = 0 end
      if not best or efficiency > best_efficiency then
        best = schema
        best_efficiency = efficiency
      end
    end

    return best
  end

  function BDIModel:processGoal(goal, intention)
    local event = Event.goal(goal)
    local plans, metaplans = self.plan_base:filter(event)
    local plan_schema

    -- TODO: check retry flag and plan history
    if metaplans then plan_schema = self:selectPlan(goal, metaplans) end
    if not plan_schema then plan_schema = self:selectPlan(goal, plans) end

    if not plan_schema then
      self.log.i("No plans could be selected for the goal <"..goal.name..">.")
    else
      return self:pushPlan(plan_schema, goal.parameters, intention)
    end
  end

  function BDIModel:waiting()
    return self.intention_base:allWaiting()
  end

  function BDIModel:step()
    self.goal_base:update()
    self.intention_base:update()

    if self.intention_base:isEmpty() then
      self.log.i("No intentions to execute.")
      return false
    end

    local intention = self:selectIntention()

    if not intention then
      self.log.i("No active intentions.")
      self.intention_base:dump()
      return false
    end

    self.log.fi("Executing intention %s", intention)
    self.intention_base:execute(intention)
    self.intention_base:dump()
    return true
  end

  function BDIModel:pushGoal(name, parameters, intention) assert(name)
    local goal = self.goal_base:instance(name, parameters)
    if not goal then return end

    goal:bind(
      goal,
      parameters or {},
      self.belief_base.interface,
      self.actuator.interface)

    if intention then
      intention:push(goal)
    else
      intention = Intention(self)
      intention:push(goal)
      self.intention_base:add(intention)
    end

    return goal
  end

  function BDIModel:pushPlan(name, parameters, intention) assert(name)
    local plan = self.plan_base:instance(name, parameters)
    if not plan then return end

    plan:bind(
      plan,
      plan.parameters or {},
      self.belief_base.interface,
      self.actuator.interface)

    if intention then
      intention:push(plan)
    else
      intention = Intention(self)
      intention:push(plan)
      self.intention_base:add(intention)
    end

    plan.on.create()
    return plan
  end

  return BDIModel
end
