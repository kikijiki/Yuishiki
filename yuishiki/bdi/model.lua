local Model = ys.common.class("BDI_Model")
local Event = ys.mas.Event

function Model:initialize(agent)
  self.agent = agent

  self.belief_base    = ys.bdi.BeliefBase(agent)
  self.goal_base      = ys.bdi.GoalBase(agent)
  self.plan_base      = ys.bdi.PlanBase(agent)
  self.intention_base = ys.bdi.IntentionBase(agent)
  self.functions = {}

  agent.dispatcher:register(self.plan_base, nil, -2)
  agent.dispatcher:register(self.goal_base, nil, -2)
  agent.dispatcher:register(self.intention_base, nil, -1)

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

function Model:selectIntention()
  if self.functions.selectIntention then
    return self.functions.selectIntention(self, self.intention_base)
  end
  --Default
  for _,intention in pairs(self.intention_base.intentions) do
    if not intention:waiting() then return intention end
  end
end

function Model:selectPlan(goal, options)
  if self.functions.selectBestPlan then
    return self.functions.selectPlan(self, goal, options)
  end

  -- Default
  local best, best_confidence = 0
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

function Model:processGoal(goal)
  local event = Event.Goal(goal)
  local plans, metaplans = self.plan_base:filter(event)

  if plans == nil or #plans == 0 then
    ys.log.i("No plans available for the goal <"..goal.name..">.")
    return nil
  end

  local plan_schema

  if metaplans then plan_schema = self:selectPlan(goal, metaplans) end
  if not plan_schema then plan_schema = self:selectPlan(goal, plans) end

  if not plan_schema then
    ys.log.i("No plans could be selected for the goal <"..goal.name..">.")
    return nil
  else
    local plan = self.plan_base:instance(plan_schema, goal.parameters, goal)
    table.insert(goal.plan_history, plan)
    return plan
  end
end

function Model:waiting()
  return self.intention_base:waiting()
end

function Model:step()
  self.agent:systemEvent("begin_step", self.agent.step_count)

  --[[Schedule intentions]]--
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

  self.agent:systemEvent("end_step", self.agent.step_count)
  return true
end

function Model:pushGoal(name, parameters, intention)
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

return Model
