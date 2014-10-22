local Sensor

return function(loader)
  if Sensor then return Sensor end

  local class = loader.require "middleclass"

  Sensor = class("Sensor")

  function Sensor:initialize(data)
    self.data = data
    if data.initialize then data.initialize(self) end
  end

  function Sensor:bind(agent)
    self.agent = agent
    self.belief_base = agent.bdi.belief_base
    self.beliefs = agent.bdi.belief_base.interface
  end

  function Sensor:onPlug(...)
    if self.data.onPlug then self.data.onPlug(self, ...) end
  end

  function Sensor:onEvent(...)
    if self.data.onEvent then return self.data.onEvent(self, ...) end
  end

  function Sensor:update()
    if self.data.update then return self.data.update(self) end
  end

  function Sensor.getYsType()
    return "sensor"
  end

  return Sensor
end
