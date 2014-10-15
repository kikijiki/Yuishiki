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

function Agent:dispatchEvent(event)
  self.dispatcher:send(event)
end

function Agent:systemEvent(name, ...)
  self:dispatchEvent(Event.System(name, ...))
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
    if sensor_event then self:dispatchEvent(sensor_event) end
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

--[[ External beliefs manipulation ]]--

function Agent:addBelief(name, ...)
  local belief = ys.bdi.Belief.External(name, ...)
  self.bdi.belief_base:set(belief)
  return belief
end

function Agent:addBeliefset(name)
  local beliefset = ys.bdi.Belief.Set(name)
  self.bdi.belief_base:set(beliefset)
  return beliefset
end

function Agent:deleteBelief(name)
  self.bdi.belief_base:unset(name)
end

function Agent:setBelief(beliefset, key, belief, ...)
  belief = ys.bdi.Belief.External(belief, ...)
  beliefset = self.bdi.belief_base:get(beliefset)
  beliefset:set(key, belief)
  return belief
end

function Agent:unsetBelief(beliefset, key)
  self.bdi.belief_base:get(beliefset):unset(key)
end

function Agent:appendBelief(beliefset, belief, ...)
  belief = ys.bdi.Belief.External(belief, ...)
  beliefset = self.bdi.belief_base:get(beliefset)
  beliefset:append(belief)
  return belief
end

return Agent
