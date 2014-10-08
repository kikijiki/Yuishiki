assert(ys, "Yuishiki is not loaded.")

local GoalBase = ys.common.class("BDI_GoalBase")
local Goal, Plan, Trigger = ys.bdi.Goal, ys.bdi.Plan, ys.mas.Trigger
local Event = ys.mas.Event

function GoalBase:initialize(agent) assert(agent)
  self.agent = agent
  self.goal_schemas = {}
  self.inhibited = {}
  self.lookup = {trigger = {}}

  self.lookup = {}
  for _,v in pairs(Event.EventType) do
    self.lookup[v] = {}
  end
end

function GoalBase:register(schema) assert(schema)
  self.goal_schemas[schema.name] = schema
  if schema.trigger then
    table.insert(self.lookup[schema.trigger.event_type], schema)
  end
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

function GoalBase:checkDynamicTriggers()
  for _,schema in pairs(self.lookup.trigger.dynamic) do
    if schema.trigger:check() and self:canInstance(schema) then
      local goal = self:instance(schema)
      self.agent:addIntention(goal)
    end
  end
end

function GoalBase:onEvent(event)
  for _,schema in pairs(self.lookup.event) do
    if schema.trigger:check(event) and self:canInstance(schema) then
      local goal = self:instance(schema, event.parameters)
      self.agent.bgi:addIntention(goal)
    end
  end
end

return GoalBase
