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
      self.log.w("Cannot instance plan <"..schema_name..">")
      return
    end

    local plan = schema(self.agent, parameters)
    plan.on.create(plan, agent)
    return plan
  end

  function PlanBase:canInstance(schema_name, event) assert(schema_name)
    local schema = self.schemas[schema_name]
    if not schema then return false end

    local parameters
    if event then
      if event:getType() == "goal" then parameters = event.goal.parameters
      else parameters = event.parameters end
    end

    return schema.conditions.default(true).initial(
      schema,
      parameters,
      self.agent.bdi.belief_base.interface,
      self.agent.actuator.interface
    )
  end

  function PlanBase:filter(event)
    local plans = {}
    local metaplans = {}
    for _,schema in pairs(self.schemas) do
      if schema.trigger:check(event) and self:canInstance(schema, event) then
        if schema.meta then table.insert(metaplans, schema.name)
        else table.insert(plans, schema.name) end
      end
    end
    return plans, metaplans
  end

  function PlanBase:onEvent(event)
    for _,schema in pairs(self.schemas) do
      if schema.trigger:check(event) and self:canInstance(schema) then
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
      self.log.i(plan)
    end
    self.log.i()
    self.log.i("--[[PLAN BASE DUMP END]]--")
  end

  return PlanBase
end
