return function(loader)
  local class = loader.require "middleclass"
  local Event = loader.load "event"
  local uti = loader.load "uti"

  local Agent = class("Agent")

  local generateId = uti.makeIdGenerator("agent")

  function Agent:initialize()
    self.id = generateId()
    self.step_count = 0

    self.actuator = ys.mas.Actuator()
    self.sensors = {}

    self.modules = {}
    self.custom = {}

    self.bdi = ys.bdi.Model(self)

    self.interface = setmetatable({
      log = ys.log,
      bdi = self.bdi,
      internal = self,
      external = setmetatable({},{}),
      }, {
      __newindex = function(t, k)
        ys.log.w("Trying to modify an interface.")
        return ys.common.uti.null_interface
      end
    })
  end

  function Agent:dispatch(event)
    self.bdi:dispatch(event)
  end

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
      if sensor_event then self:dispatch(sensor_event) end
    end
  end

  function Agent:plug(mod)
    if type(mod) ~= "table" then return end

    if mod.g then
      for k,v in pairs(mod.g) do
        local goal_schema = ys.bdi.Goal.define(k, v)
        self.bdi.goal_base:register(goal_schema)
      end
    end

    if mod.p then
      for k,v in pairs(mod.p) do
        local plan_schema = ys.bdi.Plan.define(k, v)
        self.bdi.plan_base:register(plan_schema)
      end
    end

    if mod.b then
      for k,v in pairs(mod.b) do
        local belief = ys.bdi.Belief.fromData(k, v)
        self.bdi.belief_base:set(belief)
      end
    end

    if mod.f then
      for k,f in pairs(mod.f) do
        self.bdi.functions[k] = f
      end
    end

    return true
  end

  return Agent
end
