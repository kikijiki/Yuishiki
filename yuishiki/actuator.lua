local Actuator

return function(loader)
  if Actuator then return Actuator end

  Actuator = loader.class("Actuator")

  function Actuator:initialize()
    self.actions = {}

    self.interface = setmetatable({}, {
      __index = function(_, k)
        if k == "can" then
          return setmetatable({}, {
          __call = function(_, ...)
            return self:execute(k, ...)
          end
        })
        else
          return setmetatable({}, {
            __call = function(_, ...)
              return self:execute(k, ...)
            end
          })
        end
      end
    })
  end

  function Actuator:setCaller(caller)
    self.caller = caller
  end

  function Actuator:addAction(action)
    self.actions[action] = action
  end

  function Actuator:execute(action, ...)
    if self.caller and self.caller.execute then
      return self.caller.execute(action, ...)
    end
  end

  function Actuator:canExecute(action, ...)
    if caller and caller.canExecute then
      return caller.canExecute(action, ...)
    end
  end

  return Actuator
end
