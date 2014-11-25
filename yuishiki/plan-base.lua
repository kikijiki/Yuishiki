local PlanBase

return function(loader)
  if PlanBase then return PlanBase end

  local log = loader.load "log"
  local Plan = loader.load "plan"
  local Trigger = loader.load "trigger"
  local Observable = loader.load "observable"
  local Event = loader.load "event"

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

  function PlanBase:instance(schema, parameters, goal) assert(schema)
    local plan = schema(self.agent, parameters, goal)
    plan.on.create(plan, agent)
    return plan
  end

  function PlanBase:canInstance(schema, event) assert(schema)
    local parameters
    if event then
      if event.event_type == Event.Type.Goal then parameters = event.parameters.goal.parameters
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
        if schema.meta then table.insert(metaplans, schema)
        else table.insert(plans, schema) end
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
