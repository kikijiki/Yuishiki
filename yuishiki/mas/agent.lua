local Agent = ys.common.class("Agent")
local Event, AgentModule = ys.mas.Event, ys.mas.AgentModule

local generateId = ys.common.uti.makeIdGenerator("agent")

function Agent:initialize()
  self.id = generateId()
  self.step_count = 0

  self.dispatcher  = ys.mas.EventDispatcher()
  self.actuator = ys.mas.Actuator()
  self.sensors = {}
  
  self.modules = {}
  self.custom = {}
  
  self.bdi = ys.bdi.Model(self)
  
  self.interface = setmetatable({}, {
    bdi = self.bdi,
    internal = self,
    external = setmetatable({},{}),
    __newindex = function(t, k)
      ys.log.w("Trying to modify an interface.")
      return ys.common.uti.null_interface
    end
  })
end

-- Private

function Agent:dispatchEvent(event)
  self.dispatcher:send(event)
end

function Agent:systemEvent(name, ...)
  self:dispatchEvent(Event.System(name, ...))
end

-- Public

function Agent:waiting()
  return self.bdi:waiting()
end

function Agent:step()
  self.step_count = self.step_count + 1
  ys.log.i("Step "..self.step_count)
  return self.bdi:step();
end

function Agent:onEvent(event)
  for _,sensor in pairs(self.sensors) do
    local sensor_event = sensor:onEvent(event)
    if sensor_event then self:dispatchEvent(sensor_event) end
  end
end

function Agent:plugComponent(module, source, loader)
  module.before[source]()
  if module.components[source] then
    for _,v in pairs(module.components[source]) do
      loader(v)
    end
  end
  module.after[source]()
end

function Agent:plug(module)
  module.before["plugging"]()

  self:plugComponent(module, "goal", function(x) self.bdi.goal_base:register(x) end)
  self:plugComponent(module, "plan", function(x) self.bdi.plan_base:register(x) end)
  self:plugComponent(module, "belief", function(x) self.bdi.belief_base:set(x) end)
  
  module.before["bdi_functions"]()
  for k,f in pairs(module.functions) do self.bdi.functions[k] = f end
  module.after["bdi_functions"]()

  module.after["plugging"]()
  return true
end

return Agent