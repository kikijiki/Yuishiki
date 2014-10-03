local Actuator = ys.common.class("Actuator")

--[[
  Actuator data
   - actions
   - prepare (optional)
   - data (optional)
  Action data
   - body
   - condition (optional)
]]

local function setInterface(metamethod, i)
  return setmetatable({}, {
      ["__"..metamethod] = i,
      __newindex = function()
        ys.log.w("Trying to modify an interface.")
        return ys.common.uti.null_interface
      end
  })
end

function Actuator:initialize(data, actions)
  self.data = data or {}
  self.actions = actions or {}
  
  self.interface = setInterface("index", {
    ["do"] = setInterface("index", setInterface("call", function(t, ...) return self:execute(t, ...) end)),
    ["can"] = setInterface("index", setInterface("call", function(t, ...) return self:canExecute(t, ...) end))
  })
end

function Actuator:addAction(name, action)
  self.actions[name] = action
end

function Actuator:execute(action, ...)
  local a = self.actions[action]
  if a then
    local param = {...}
    if self.prepare then
      return a.body(self:prepare(...))
    else
      return a.body(...)
    end
  end
end

function Actuator:canExecute(action, ...)
  local a = self.actions[action]
  if a then
    if not a.condition then return true end
    local param = {...}
    if self.prepare then
      return a.condition(self:prepare(...))
    else
      return a.condition(...)
    end
  else
    return false
  end
end

return Actuator