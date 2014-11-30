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
    self.goal_base      = GoalBase(agent)
    self.plan_base      = PlanBase(agent)
    self.intention_base = IntentionBase(agent)
    self.functions = {}

    local dispatcher = function(...) return self:dispatch(...) end
    self.belief_base   :addObserver(self, dispatcher)
    self.goal_base     :addObserver(self, dispatcher)
    self.plan_base     :addObserver(self, dispatcher)
    self.intention_base:addObserver(self, dispatcher)

    self.export = {
      beliefs = self.belief_base.interface,
      actuator = self.agent.actuator.interface
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

    --Default
    local highest
    local highest_priority
    for _,intention in pairs(self.intention_base.intentions) do
      if not intention:waiting() then
        local priority = intention:getPriority()
        if not highest_priority or priority > highest_priority then
          highest_priority = priority
          highest = intention
        end
      end
    end

    return highest
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
      local efficiency = 0
      if schema.efficiency then
        efficiency = schema.efficiency(
          schema,
          goal.parameters,
          self.belief_base.interface,
          self.agent.actuator.interface)
        if type(efficiency) ~= "number" then efficiency = 0 end
      end
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
    return self.intention_base:waiting()
  end

  function BDIModel:step()
    if self:waiting() then
      self.log.i("No executable intentions.")
      return false
    end

    local intention = self:selectIntention()

    if intention then
      self.log.i("Executing intention <"..intention.id.." - "..intention.name..">.")
      self.intention_base:execute(intention)
    else
      self.log.i("No active intentions.")
      return false
    end

    return true
  end

  function BDIModel:pushGoal(name, parameters, intention) assert(name)
    local goal = self.goal_base:instance(name, parameters)
    if not goal then return end

    goal:bind(
      goal,
      parameters,
      self.belief_base.interface,
      self.agent.actuator.interface)

    if intention then
      intention:push(goal)
    else
      intention = Intention()
      intention.name = goal.name
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
    plan.parameters,
    self.belief_base.interface,
    self.agent.actuator.interface)

    if intention then
      intention:push(plan)
    else
      intention = Intention()
      intention.name = plan.name
      intention:push(plan)
      self.intention_base:add(intention)
    end

    return plan
  end

  return BDIModel
end
