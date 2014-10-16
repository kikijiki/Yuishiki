return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"

  local Sensor = class("Sensor")
  local sensor_class_prefix = "sensor_"

  local generateId =  uti.makeIdGenerator("sensor")

  function Sensor.static.define(name)
    local S = class(sensor_class_prefix..name, Sensor)
    S.static.name = name

    S.initialize = function(self, agent)
      Sensor.initialize(self, agent)
    end

    return S
  end

  -- TODO mount sensors

  function Sensor:initialize(agent) assert(agent)
    self.agent = agent
    self.id = generateId()
  end

  function Sensor:onEvent(event)
    if self:detect(event, self.agent.belief_base.interface) then
      return self:process(event, self.agent.belief_base.interface)
    end
  end

  function Sensor:detect(event, beliefs)
    return true
  end

  function Sensor:process(event, beliefs)
    log.w("Virtual method not implemented.")
  end

  function Sensor.getYsType()
    return "sensor"
  end

  return Sensor
end
