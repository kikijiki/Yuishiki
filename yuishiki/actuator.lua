local Actuator

return function(loader)
  if Actuator then return Actuator end

  Actuator = loader.class("Actuator")

  function Actuator:initialize()
    self.actions = {}

    self.interface = setmetatable({}, {
      __index = function(_, k)
        return setmetatable(
        {
          available = function() return self:available(k) end,
          canExecute = function(...) return self:canExecute(k, ...) end,
          execute = function(...) return self:execute(k, ...) end,
          cost = function(...) return self:getCost(k, ...)end,
        },
        {
          __call = function(t, ...) return self:execute(k, ...) end
        })
      end
    })

  end

  function Actuator:setCaller(caller)
    self.caller = caller
  end

  function Actuator:addAction(action)
    self.actions[action] = action
  end

  function Actuator:available(action)
    return self.actions[action] ~= nil
  end

  function Actuator:execute(action, ...)
    if self.caller and self.caller.execute then
      return self.caller.execute(action, ...)
    end
  end

  function Actuator:canExecute(action, ...)
    if self.caller and self.caller.canExecute then
      return self.caller.canExecute(action, ...)
    end
  end

  function Actuator:getCost(action, ...)
    if self.caller and self.caller.getCost then
      return self.caller.getCost(action, ...)
    end
  end

  return Actuator
end
