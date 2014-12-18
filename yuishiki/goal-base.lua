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

  function GoalBase:initialize(bdi) assert(bdi)
    Observable.initialize(self)

    self.bdi = bdi
    self.schemas = {}
    self.inhibited = {}
    self.triggers = {}
    self.instances = {}
    self.log = log.tag("GB")
  end

  function GoalBase:register(schema) assert(schema and schema.name)
    self.schemas[schema.name] = schema
    if schema.trigger then table.insert(self.triggers, schema) end
    self.instances[schema.name] = {
      count = 0,
      list = setmetatable({}, {__mode="k"})
    }
  end

  function GoalBase:instance(name, parameters) assert(name)
    local schema = self.schemas[name]

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
    return true
  end

  function GoalBase:onEvent(event)
    for _,schema in pairs(self.triggers) do
      if schema.trigger:check(event) and self:canInstance(schema) then
        self.bdi:pushGoal(schema.name, event.parameters)
      end
    end
  end

  function GoalBase:reserve(goal, intention)
    -- goal has no constraints
    if not goal.limit then return goal:activate() end

    local inst = self.instances[goal.name]

    -- this intention has already reserved the goal, ok.
    if inst.list[intention] then return goal:activate() end

    -- if there is still room, reserve another one.
    if inst.count < goal.limit then
      inst.count = inst.count + 1
      inst.list[intention] = true
      goal:activate()
    else
      goal.status = Goal.Status.WaitingAvailability
    end
  end

  function GoalBase:release(goal_name, intention)
    local inst = self.instances[goal_name]
    if inst.list[intention] then
      inst.list[intention] = nil
      inst.count = inst.count - 1
    end
  end

  function GoalBase:update()
    local ib = self.bdi.intention_base
    for goal_name, instance_data in pairs(self.instances) do
      for intention,_ in pairs(instance_data.list) do
        if intention:getGoalCount(goal_name) == 0 then
          self:release(goal_name, intention)
        end
      end
    end
  end

  function GoalBase:dump(level)
    level = level or "i"
    if not next(self.schemas) then
      self.log[level]("--[[GOAL BASE EMPTY]]--")
      return
    end
    self.log[level]("--[[GOAL BASE DUMP START]]--")
    self.log[level]()
    for _,goal in pairs(self.schemas) do
      if goal.limit then
        self.log["f"..level]("%s (%d/%d)",
          goal.name, self.instances[goal.name].count, goal.limit)
      else
        self.log[level](goal.name)
      end
    end
    self.log[level]()
    self.log[level]("--[[GOAL BASE DUMP END]]--")
  end

  return GoalBase
end
