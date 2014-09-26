local Class = require "lib.middleclass"
local Stat = Class("Stat")
local CompositeStat = Class("CompositeStat", Stat)
Stat.Composite = CompositeStat

function Stat:initialize(value)
  self.value = value or 0
  self.listeners = setmetatable({},{__mode="k"})
end

function Stat:__tostring()
  return self.value
end

function Stat:update(v)
  local old = self.value
  self.value = v
  if old ~= v then self:notify(v, old) end
  return v
end

function Stat:set(v)
  return self:update(v)
end

function Stat:add(v)
  return self:update(self.value + v)
end

function Stat:sub(v)
  return self:update(self.value - v)
end

function Stat:get()
  return self.value
end

function Stat:listen(l, c)
  self.listeners[l] = c
end

function Stat:unlisten(l)
  self.listeners[l] = nil
end

function Stat:notify(v, old)
  for _,listener in pairs(self.listeners) do
    listener(self, v, old)
  end
end

function CompositeStat:initialize(value)
  Stat.initialize(self, value)
  self.base = self.value
  self.modifiers = {}
end

function CompositeStat:setMod(name, value)
  self.modifiers[name] = value
  return self:update()
end

function CompositeStat:addMod(name, value)
  local mod = self.modifiers[name] or 0
  mod = mod + value
  self.modifiers[name] = mod
  return self:update()
end

function CompositeStat:subMod(name, value)
  local mod = self.modifiers[name] or 0
  mod = mod - value
  self.modifiers[name] = mod
  return self:update()
end

function CompositeStat:unsetMod(name)
  self.modifiers[name] = nil
  return self:update()
end

function CompositeStat:update()
  local old = self.value
  local v = self.base
  for _,mod in pairs(self.modifiers) do
    v = v + mod
  end
  return Stat.update(self, v)
end

function CompositeStat:set(v)
  self.base = v
  return self:update()
end

function CompositeStat:add(v)
  self.base = self.base + v
  return self:update()
end

function CompositeStat:sub(v)
  self.base = self.base - v
  return self:update()
end

return Stat