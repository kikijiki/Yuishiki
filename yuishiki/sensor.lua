local Sensor

return function(loader)
  if Sensor then return Sensor end

  local class = loader.require "middleclass"

  Sensor = class("Sensor")

  function Sensor:initialize(data)
    self.data = data
    if data.initialize then data.initialize(self) end
  end

  function Sensor:onPlug(...)
    if self.data.onPlug then self.data.onPlug(self, ...) end
  end

  function Sensor:onEvent(event, beliefs)
    if self.data.onPlug then return self.data.onEvent(event, beliefs) end
  end

  function Sensor:update(beliefs)
    if self.data.update then return self.data.update(beliefs) end
  end

  function Sensor.getYsType()
    return "sensor"
  end

  return Sensor
end
