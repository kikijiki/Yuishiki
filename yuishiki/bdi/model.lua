local Model = ys.common.class("BDI_Model")

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

-- Private

function Model:selectIntention()
  if self.functions.selectIntention then 
    return self.functions.selectIntention(self, self.intention_base)
  else
    for _,v in pairs(self.intention_base.intentions) do
      if not v:empty() then return v end
    end
  end
end

function Model:selectOption(options)
  if self.functions.selectOption then
    return self.functions.selectOption(self, options)
  else
    return options[1]
  end
end
    
function Model:processGoal(goal)
  local options = self.plan_base:filter(goal)

  if options == nil or #options == 0 then
    ys.log.i("No plans available for the goal <"..goal.name..">.")
    return nil
  end

  local plan_schema = self:selectOption(options)
  local plan = self.plan_base:instance(plan_schema, goal.parameters)
  return plan
end

-- Public

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