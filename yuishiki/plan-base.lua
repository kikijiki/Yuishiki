return function(loader)
  local class = loader.require "middleclass"
  local Plan = loader.load "plan"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"

  local PlanBase = class("PlanBase", Observable)

  function PlanBase:initialize(agent) assert(agent)
    Observable.initialize(self)
    
    self.agent = agent
    self.schemas = {}
  end

  function PlanBase:register(schema)
    assert(schema and schema.name and schema.body)
    self.schemas[schema.name] = schema
  end

  function PlanBase:instance(schema, parameters, goal) assert(schema)
    local plan = schema(self.agent, parameters, goal)
    plan.on.create(plan, agent)
    return plan
  end

  function PlanBase:canInstance(schema, parameters) assert(schema)
    if not schema.condition.default(true).initial() then
      return false, "The initial condition is not satisfied."
    else return true end
  end

  function PlanBase:filter(event)
    local plans = {}
    local metaplans = {}
    for _,schema in pairs(self.schemas) do
      if schema.trigger:check(event) and self:canInstance(schema) then
        if schema.meta then table.insert(metaplans, schema)
        else table.insert(plans, schema) end
      end
    end
    return plans, metaplans
  end

  function PlanBase:onEvent(event)
    for _,schema in pairs(self.schemas) do
      if schema.trigger:check(event) and self:canInstance(schema) then
        local plan = self:instance(schema, event.parameters)
        goal_base.agent.bdi:addIntention(plan)
      end
    end
  end

  return PlanBase
end
