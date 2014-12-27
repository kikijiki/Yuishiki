local PlanBase

return function(loader)
  if PlanBase then return PlanBase end

  local log = loader.load "log"
  local Plan = loader.load "plan"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"

  PlanBase = loader.class("PlanBase", Observable)

  function PlanBase:initialize(bdi) assert(bdi)
    Observable.initialize(self)

    self.bdi = bdi
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
      return schema(self.bdi, parameters)
    end
  end

  function PlanBase:canInstance(schema, parameters) assert(schema)
    if schema.enabled then
      return schema.enabled(
        schema,
        parameters,
        self.bdi.belief_base.interface,
        self.bdi.actuator.interface)
    else return true end
  end

  function PlanBase:getEfficiency(schema_name, goal)
    local schema = self.schemas[schema_name]
    if schema.efficiency then
      return schema.efficiency(
        schema,
        goal.parameters,
        self.bdi.belief_base.interface,
        self.bdi.actuator.interface)
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
        self.bdi:pushPlan(schema.name, event.parameters)
      end
    end
  end

  function PlanBase:dump(level)
    level = level or "i"
    if not next(self.schemas) then
      self.log[level]("--[[PLAN BASE EMPTY]]--")
      return
    end
    self.log[level]("--[[PLAN BASE DUMP START]]--")
    self.log[level]()
    for _,plan in pairs(self.schemas) do
      self.log[level](plan.name)
    end
    self.log[level]()
    self.log[level]("--[[PLAN BASE DUMP END]]--")
  end

  return PlanBase
end
