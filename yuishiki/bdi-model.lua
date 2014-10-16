return function(loader)
  local class = loader.require "middleclass"
  local Event = loader.load "event"

  local BDIModel = class("BDIModel")

  function BDIModel:initialize(agent)
    self.agent = agent

    self.belief_base    = ys.bdi.BeliefBase(agent)
    self.goal_base      = ys.bdi.GoalBase(agent)
    self.plan_base      = ys.bdi.PlanBase(agent)
    self.intention_base = ys.bdi.IntentionBase(agent)
    self.functions = {}

    self.interface = setmetatable({}, {
      beliefs = self.belief_base.interface,
      actuator = agent.actuator.interface,
      internal = agent,
      external = setmetatable({},{}),
      __newindex = function(t, k)
        ys.log.w("Trying to modify an interface.")
        return ys.common.uti.null_interface
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
      ys.log.i("No plans available for the goal <"..goal.name..">.")
      return
    end

    local plan_schema

    if metaplans then plan_schema = self:selectPlan(goal, metaplans) end
    if not plan_schema then plan_schema = self:selectPlan(goal, plans) end

    if not plan_schema then
      ys.log.i("No plans could be selected for the goal <"..goal.name..">.")
      return nil
    else
      return self.plan_base:instance(plan_schema, goal.parameters, goal)
    end
  end

  function BDIModel:waiting()
    return self.intention_base:waiting()
  end

  function BDIModel:step()
    if self:waiting() then
      ys.log.i("No executable intentions.")
      return false
    end

    local intention = self:selectIntention()

    if intention then
      ys.log.i("Executing intention <"..intention.id..">.")
      self.intention_base:execute(intention)
    else
      ys.log.i("No active intentions.")
      return false
    end

    return true
  end

  function BDIModel:pushGoal(name, parameters, intention)
    local goal = self.goal_base:instance(name, parameters)

    if intention then
      intention:push(goal)
    else
      intention = ys.bdi.Intention()
      intention:push(goal)
      self.intention_base:add(intention)
    end

    return goal
  end

  return BDIModel
end
