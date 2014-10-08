assert(ys, "Yuishiki is not loaded.")

local GoalBase = ys.common.class("BDI_GoalBase")
local Goal, Plan, Trigger = ys.bdi.Goal, ys.bdi.Plan, ys.mas.Trigger
local Event = ys.mas.Event

function GoalBase:initialize(agent) assert(agent)
  self.agent = agent
  self.goal_schemas = {}
  self.inhibited = {}
  self.triggers = {goals = {}, creation = {}}
end

function watchTrigger(triggers, name, schema)
  if schema[name] then
    local et = schema[name].event_type
    if not triggers[name][et] then triggers[name][et] = {} end
    table.insert(triggers[name][et], schema)
  end
end

function GoalBase:register(schema) assert(schema and schema.name)
  self.goal_schemas[schema.name] = schema
  watchTrigger(self.triggers, creation, schema)
end

function GoalBase:instance(name, parameters) assert(name)
  local schema = self.goal_schemas[name]
  local goal = schema(self.agent, parameters)
  return goal
end

function GoalBase:canInstance(schema) assert(schema)
  if self.inhibited[schema.name] then
    return false, "The goal is inhibited."
  end

  if not schema.condition.default(true).initial() then
    return false, "The initial condition is not satisfied."
  end

  if schema.limit then
    local ib = self.agent.intentionBase
    local goal_count = 0
    for _, intention in pairs(ib) do
      goal_count = goal_count + intention.goalCount[schema.name] or 0
    end
    if goal_count > schema.limit then
      return false, "The limit condition ("..schema.limit..") is not satisfied."
    end
  end

  return true
end

function GoalBase:onEvent(event)
  local et = event.event_type
  local triggers = self.triggers

  if not triggers[et] then return end

  for _,schema in pairs(triggers[et]) do
    if schema.creation:check(event) and self:canInstance(schema) then
      local goal = self:instance(schema, event.parameters)
      self.agent.bdi:addIntention(goal)
    end
  end
end

return GoalBase
