local Sensor = ys.class("Sensor")
local sensor_class_prefix = "sensor_"

local generateId =  ys.common.uti.makeIdGenerator("sensor")

function Sensor.static.define(name)
  local S = ys.class(sensor_class_prefix..name, ys.mas.Sensor)
  S.static.name = name
  
  S.initialize = function(self, agent)
    Sensor.initialize(self, agent)
  end
  
  return S
end

function Sensor:initialize(agent) assert(agent)
  self.agent = agent
  self.id = generateId()
end

function Sensor:isActive() return true end

function Sensor:onEvent(event)
  if self:detect(event, self.agent.interface, self.agent.belief_base.interface) then
    return self:process(event, self.agent.interface, self.agent.belief_base.interface) end
end

function Sensor:detect(event, agent, beliefs)
  if not self:isActive() then return false
  else return true end
end

function Sensor:process(event, agent, beliefs)
  ys.log.w("Virtual method not implemented.")
end

function Sensor:getYsType()
  return "sensor"
end

return Sensor