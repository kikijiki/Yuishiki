local PlanBase

return function(loader)
  if PlanBase then return PlanBase end

  local log = loader.load "log"
  local Plan = loader.load "plan"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"

  PlanBase = loader.class("PlanBase", Observable)

  function PlanBase:initialize(agent) assert(agent)
    Observable.initialize(self)

    self.agent = agent
    self.schemas = {}
    self.log = log.tag("PB")
  end

  function PlanBase:register(schema)
    assert(schema and schema.name and schema.body)
    self.schemas[schema.name] = schema
  end

  function PlanBase:instance(schema_name, parameters) assert(schema_name)
    local schema = self.schemas[schema_name]

    if not schema then
      self.log.w("Cannot find plan <"..schema_name..">")
      return
    end

    if self:canInstance(schema, parameters) then
      return schema(self.agent, parameters)
    end
  end

  function PlanBase:canInstance(schema, parameters) assert(schema)
    if schema.enabled then
      return schema.enabled(
        schema,
        parameters,
        self.agent.bdi.belief_base.interface,
        self.agent.actuator.interface)
    else return true end
  end

  function PlanBase:getEfficiency(schema_name, goal)
    local schema = self.schemas[schema_name]
    if schema.efficiency then
      return schema.efficiency(
        schema,
        goal.parameters,
        self.agent.bdi.belief_base.interface,
        self.agent.actuator.interface)
    else return 0 end
  end

  function PlanBase:filter(event)
    local plans = {}
    local metaplans = {}
    for _,schema in pairs(self.schemas) do
      if schema.trigger
        and schema.trigger:check(event)
        and self:canInstance(schema, event.parameters) then

        if schema.meta then table.insert(metaplans, schema.name)
        else table.insert(plans, schema.name) end
      end
    end
    return plans, metaplans
  end

  function PlanBase:onEvent(event)
    for _,schema in pairs(self.schemas) do
      if schema.trigger
        and schema.trigger:check(event)
        and self:canInstance(schema) then

        local plan = self:instance(schema, event.parameters)
        goal_base.agent.bdi:addIntention(plan)
      end
    end
  end

  function PlanBase:dump()
    if not next(self.schemas) then
      self.log.i("--[[PLAN BASE EMPTY]]--")
      return
    end
    self.log.i("--[[PLAN BASE DUMP START]]--")
    self.log.i()
    for _,plan in pairs(self.schemas) do
      self.log.i(plan.name)
    end
    self.log.i()
    self.log.i("--[[PLAN BASE DUMP END]]--")
  end

  return PlanBase
end
