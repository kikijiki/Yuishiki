local DeviceBase = ys.common.class("DeviceBase")

function DeviceBase:initialize(agent) assert(agent)
  self.agent = agent
  self.sensors = {}
  self.actuators = {}
  
  self.interface = setmetatable({}, {
    s = setmetatable({}, {
      __index = function(t, k)
        local sensor = self.sensors[k]
        if sensor then return dev.interface
        else
          ys.log.w("Unknown sensor <"..k..">.")
          return ys.common.uti.null_interface
        end
      end,
      __newindex = function(t, k)
        ys.log.w("Trying to modify an interface.")
        return ys.common.uti.null_interface
      end
    }),
    a = setmetatable({}, {
      __index = function(t, k)
        local actuator = self.actuators[k]
        if actuator then return dev.interface
        else
          ys.log.w("Unknown actuator <"..k..">.")
          return ys.common.uti.null_interface
        end
      end,
      __newindex = function(t, k)
        ys.log.w("Trying to modify an interface.")
        return ys.common.uti.null_interface
      end
    })
  })
end

function DeviceBase:register(component, slot) assert(component) assert(slot)
  if component.getYsType() == "actuator" then self.actuators[slot] = component end
  if component.getYsType() == "sensor" then self.sensors[slot] = component end
end

function DeviceBase:onEvent(event)
  for _,sensor in pairs(self.sensors) do 
    local sensor_event = sensor:onEvent(event)
    if sensor_event then self.agent:dispatchEvent(sensor_event) end
  end
end

return DeviceBase