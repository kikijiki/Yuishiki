local GoalBase

return function(loader)
  if GoalBase then return GoalBase end

  local log = loader.load "log"
  local Goal = loader.load "goal"
  local Plan = loader.load "plan"
  local Event = loader.load "event"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"

  GoalBase = loader.class("GoalBase", Observable)

  function GoalBase:initialize(agent) assert(agent)
    Observable.initialize(self)

    self.agent = agent
    self.goal_schemas = {}
    self.inhibited = {}
    self.triggers = {}
    self.log = log.tag("GB")
  end

  function GoalBase:register(schema) assert(schema and schema.name)
    self.goal_schemas[schema.name] = schema
    if schema.trigger then table.insert(self.triggers, schema) end
  end

  function GoalBase:instance(name, parameters) assert(name)
    local schema = self.goal_schemas[name]

    if not schema then
      self.log.w("Could not find the goal <"..name..">.")
      return
    end

    if self:canInstance(schema, parameters) then
      return schema(parameters)
    else
      self.log.i("Cannot instance goal <"..name..">.")
    end
  end

  function GoalBase:canInstance(schema) assert(schema)
    if self.inhibited[schema.name] then return false end
    if schema.enabled and not self.enabled() then return false end

    if schema.limit then
      local ib = self.agent.bdi.intention_base
      local goal_count = 0
      for _, intention in pairs(ib) do
        goal_count = goal_count + intention:getGoalCount(schema.name)
      end
      if goal_count > schema.limit then return false end
    end

    return true
  end

  function GoalBase:onEvent(event)
    for _,schema in pairs(self.triggers) do
      if schema.trigger:check(event) and self:canInstance(schema) then
        self.agent.bdi:pushGoal(schema.name, event.parameters)
      end
    end
  end

  function GoalBase:dump()
    if not next(self.goal_schemas) then
      self.log.i("--[[GOAL BASE EMPTY]]--")
      return
    end
    self.log.i("--[[GOAL BASE DUMP START]]--")
    self.log.i()
    for _,goal in pairs(self.goal_schemas) do
      self.log.i(goal.name)
    end
    self.log.i()
    self.log.i("--[[GOAL BASE DUMP END]]--")
  end

  return GoalBase
end
