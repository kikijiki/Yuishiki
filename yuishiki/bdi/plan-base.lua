assert(ys, "Yuishiki is not loaded.")

local PlanBase = ys.common.class("BDI_PlanBase")
local Plan, Trigger = ys.bdi.Plan, ys.mas.Trigger

function PlanBase:initialize(agent) assert(agent)
  self.agent = agent
  self.plan_schemas = {}
  self.triggers = {goals = {}, creation = {}}
end

function watchTrigger(triggers, name, schema)
  if schema[name] then
    local et = schema[name].event_type
    if not triggers[name][et] then triggers[name][et] = {} end
    table.insert(triggers[name][et], schema)
  end
end

function PlanBase:register(schema)
  assert(
    schema and
    schema.name and
    schema.body)

  self.plan_schemas[schema.name] = schema
  watchTrigger(self.triggers, creation, schema)
  watchTrigger(self.triggers, goal, schema)
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
  for _,schema in pairs(self.triggers.goal) do
    if schema.goal:check(goal) and self:canInstance(schema) then
      table.insert(options, schema)
    end
  end
  return options
end

function checkCreationTrigger(goal_base, event)
  local et = event.event_type
  local triggers = goal_base.triggers

  if not triggers[et] then return end

  for _,schema in pairs(triggers[et]) do
    if schema.creation:check(event) and goal_base:canInstance(schema) then
      local goal = goal_base:instance(schema, event.parameters)
      goal_base.agent.bdi:addIntention(goal)
    end
  end
end

function PlanBase:onEvent(event)
  local et = event.event_type
  local triggers = self.triggers

  if not triggers[et] then return end

  for _,schema in pairs(triggers[et]) do
    if schema.creation:check(event) and self:canInstance(schema) then
      local plan = self:instance(schema, event.parameters)
      goal_base.agent.bdi:addIntention(plan)
    end
  end
end

return PlanBase
