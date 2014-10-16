local class = require "lib.middleclass"
local Observable = require "observable"

local Stat = class("Stat", Observable)

function Stat:initialize(value)
  Observable.initialize(self)
  self.value = value or 0
end

function Stat:__tostring()
  return tostring(self.value)
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

local CompositeStat = class("CompositeStat", Stat)
Stat.Composite = CompositeStat

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

-- TODO table stat
-- TODO vector stat?

-- TODO
function Stat.fromData(stat_type, ...)
  if stat_type == "basic"     then return Stat(...)           end
  if stat_type == "composite" then return Stat.Composite(...) end
  if stat_type == "table"     then return Stat.Table(...)     end
end

return Stat
