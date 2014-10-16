local class = require "lib.middleclass"
local Goal = require "goal"
local Plan = require "plan"
local Event = require "event"
local Trigger = require "trigger"

local GoalBase = class("BDI.GoalBase")

function GoalBase:initialize(agent) assert(agent)
  self.agent = agent
  self.goal_schemas = {}
  self.inhibited = {}
  self.triggers = {}
end

function GoalBase:register(schema) assert(schema and schema.name)
  self.goal_schemas[schema.name] = schema
  if schema.creation then table.insert(self.triggers, schema) end
end

function GoalBase:instance(name, parameters) assert(name)
  local schema = self.goal_schemas[name]
  if schema then
    local goal = schema(self.agent, parameters)
    return goal
  else
    ys.log.w("Could not find the goal <"..name..">.")
  end
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

  for _,schema in pairs(self.triggers) do
    if schema.creation:check(event) and self:canInstance(schema) then
      local goal = self:instance(schema, event.parameters)
      self.agent.bdi:addIntention(goal)
    end
  end
end

return GoalBase
