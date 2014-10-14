assert(ys, "Yuishiki is not loaded.")

local PlanBase = ys.common.class("BDI_PlanBase")
local Plan, Trigger = ys.bdi.Plan, ys.mas.Trigger

function PlanBase:initialize(agent) assert(agent)
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
