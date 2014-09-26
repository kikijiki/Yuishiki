assert(ys, "Yuishiki is not loaded.")

local PlanBase = ys.common.class("BDI_PlanBase")
local Plan, Trigger = ys.bdi.Plan, ys.mas.Trigger

function PlanBase:initialize(agent) assert(agent)
  self.agent = agent
  self.plan_schemas = {}
  
  self.lookup = {}
  for _,v in pairs(Trigger.TriggerMode) do
    self.lookup[v] = {} 
  end
end

function PlanBase:register(schema)
  assert(
    schema and
    schema.name and 
    schema.body and 
    schema.trigger)
  
  self.plan_schemas[schema.name] = schema
  table.insert(self.lookup[schema.trigger.trigger_mode], schema)
end

function PlanBase:instance(schema, parameters) assert(schema)
  local plan = schema(self.agent, parameters)
  plan.on.create(schema, agent)
  return plan
end

function PlanBase:canInstance(schema, parameters) assert(schema)
  if not schema.condition.default(true).initial() then
    return false, "The initial condition is not satisfied."
  else return true end
end

function PlanBase:filter(goal)
  local options = {}
  for _,schema in pairs(self.lookup.goal) do
    if schema.trigger:check(goal) and
       self:canInstance(schema) and
       not goal.plans.history[schema.name] then
      table.insert(options, schema)
    end
  end
  return options
end

function PlanBase:onEvent(event)
  for _,schema in pairs(self.lookup.event) do
    if schema.trigger:check(event) and self:canInstance(schema) then
      local plan = self:instance(schema, event.parameters)
      self.agent.bdi:addIntention(plan)
    end
  end
end

return PlanBase