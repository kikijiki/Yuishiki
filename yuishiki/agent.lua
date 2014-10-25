local Agent

return function(loader)
  if Agent then return Agent end

  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local log = loader.load "log"
  local Event = loader.load "event"
  local BDIModel = loader.load "bdi-model"
  local Goal = loader.load "goal"
  local Plan = loader.load "plan"
  local Belief = loader.load "belief"
  local Actuator = loader.load "actuator"

  Agent = class("Agent")

  local generateId = uti.makeIdGenerator("agent")

  function Agent:initialize()
    self.id = generateId()
    self.step_count = 0
    self.step_limit = 0

    self.actuator = Actuator()

    self.modules = {}
    self.custom = {}

    self.bdi = BDIModel(self)

    self.interface = setmetatable({
      log = print,
      bdi = self.bdi,
      internal = self,
      external = setmetatable({},{}),
      }, {
      __newindex = function(t, k)
        log.w("Trying to modify an interface.")
        return uti.null_interface
      end
    })
  end

  function Agent:setBelief(...) return self.bdi.belief_base:set(...) end
  function Agent:unsetBelief(...) return self.bdi.belief_base:unset(...) end
  function Agent:addAction(...) return self.actuator:addAction(...) end

  function Agent:dispatch(event)
    self.bdi:dispatch(event)
  end

  function Agent:waiting()
    return self.bdi:waiting()
  end
  
  function Agent:resetStepCounter(step_limit)
    self.step_limit = step_limit
    self.step_count = 0
  end

  function Agent:step()
    self.step_count = self.step_count + 1
    if self.step_count > self.step_limit then return false end
    log.i("Step "..self.step_count)
    return self.bdi:step();
  end

  function Agent:onEvent(...)
    self.bdi:dispatch(Event(...))
  end

  function Agent:plugModule(mod)
    if type(mod) ~= "table" then return end

    if mod.g then
      for k,v in pairs(mod.g) do
        local goal_schema = Goal.define(k, v)
        self.bdi.goal_base:register(goal_schema)
      end
    end

    if mod.p then
      for k,v in pairs(mod.p) do
        local plan_schema = Plan.define(k, v)
        self.bdi.plan_base:register(plan_schema)
      end
    end

    if mod.b then
      for k,v in pairs(mod.b) do
        self.bdi.belief_base:set(v, k)
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
