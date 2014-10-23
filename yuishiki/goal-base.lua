local GoalBase

return function(loader)
  if GoalBase then return GoalBase end

  local class = loader.require "middleclass"
  local log = loader.load "log"
  local Goal = loader.load "goal"
  local Plan = loader.load "plan"
  local Event = loader.load "event"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"

  GoalBase = class("GoalBase", Observable)

  function GoalBase:initialize(agent) assert(agent)
    Observable.initialize(self)

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
      log.w("Could not find the goal <"..name..">.")
    end
  end

  function GoalBase:canInstance(schema) assert(schema)
    if self.inhibited[schema.name] then return false end
    if not schema.conditions.default(true).initial() then return false end

    -- TODO refactor
    --[[
    if schema.limit then
      local ib = self.agent.bdi.intention_base
      local goal_count = 0
      for _, intention in pairs(ib) do
        goal_count = goal_count + intention.goalCount[schema.name] or 0
      end
      if goal_count > schema.limit then return false end
    end
    ]]

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
end
