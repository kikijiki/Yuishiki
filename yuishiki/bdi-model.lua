local BDIModel

return function(loader)
  if BDIModel then return BDIModel end

  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local log = loader.load "log"
  local Observable = loader.load "observable"
  local Event = loader.load "event"
  local Intention = loader.load "intention"
  local BeliefBase = loader.load "belief-base"
  local GoalBase = loader.load "goal-base"
  local PlanBase = loader.load "plan-base"
  local IntentionBase = loader.load "intention-base"

  BDIModel = class("BDIModel", Observable)

  function BDIModel:initialize(agent)
    Observable.initialize(self)

    self.agent = agent

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

    self.interface = setmetatable({}, {
      beliefs = self.belief_base.interface,
      actuator = agent.actuator.interface,
      internal = agent,
      external = setmetatable({},{}),
      __newindex = function(t, k)
        log.w("Trying to modify an interface.")
        return uti.null_interface
      end
    })
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
    for _,intention in pairs(self.intention_base.intentions) do
      if not intention:waiting() then return intention end
    end
  end

  function BDIModel:selectPlan(goal, options)
    if self.functions.selectBestPlan then
      return self.functions.selectPlan(self, goal, options)
    end

    -- Default
    local best
    local best_confidence = 0
    for _,schema in pairs(options) do
      local confidence = 0
      if schema.confidence then
        confidence = schema.confidence(self.agent.interface, self.belief_base.interface, goal)
      end
      if not best or confidence > best_confidence then
        best = schema
        best_confidence = confidence
      end
    end

    return best
  end

  function BDIModel:processGoal(goal)
    local event = Event.Goal(goal)
    local plans, metaplans = self.plan_base:filter(event)

    if plans == nil or #plans == 0 then
      log.i("No plans available for the goal <"..goal.name..">.")
      return
    end

    local plan_schema

    if metaplans then plan_schema = self:selectPlan(goal, metaplans) end
    if not plan_schema then plan_schema = self:selectPlan(goal, plans) end

    if not plan_schema then
      log.i("No plans could be selected for the goal <"..goal.name..">.")
      return nil
    else
      local plan = self.plan_base:instance(plan_schema, goal.parameters, goal)
      plan:bind(
        self.agent.interface,
        plan,
        plan.parameters,
        self.belief_base.interface,
        self.agent.actuator.interface
      )
      return plan
    end
  end

  function BDIModel:waiting()
    return self.intention_base:waiting()
  end

  function BDIModel:step()
    if self:waiting() then
      log.i("No executable intentions.")
      return false
    end

    local intention = self:selectIntention()

    if intention then
      --log.i("Executing intention <"..intention.id.." - "..intention.name..">.")
      self.intention_base:execute(intention)
    else
      log.i("No active intentions.")
      return false
    end

    return true
  end

  function BDIModel:pushGoal(name, parameters, intention)
    local goal = self.goal_base:instance(name, parameters)
    if not goal then return end
    goal:bind(
      self.agent.interface,
      goal,
      parameters,
      self.belief_base.interface,
      self.agent.actuator.interface
    )

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

  return BDIModel
end