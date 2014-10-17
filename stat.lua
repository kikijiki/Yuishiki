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

local TableStat = class("TableStat", Stat)
Stat.Table = TableStat

function TableStat:initialize(v)
  if type(v) == "table" then
    Stat.initialize(self, v)
  else
    Stat.initialize(self, {})
  end
end

function TableStat:set(k, v)
  local old = self.value[k]
  self.value[k] = v
  if v ~= old then
    self:update(k, v, old)
  end
end

function TableStat:insert(v)
  local old = self.value
  table.insert(self.value, v)
  self:update(#self.value, v)
  return #self.value
end

function TableStat:get(k)
  if k then
    return self.value[k]
  else
    return self.value
  end
end

function TableStat:pairs()
  return pairs(self.value)
end

function TableStat:update(key, new_element, old_element)
  self:notify(self.value, nil, key, new_element, old_element)
end

function TableStat:__tostring()
  local out = {"{"}
  for k,v in pairs(self.value) do
    table.insert(out, "[")
    table.insert(out, tostring(k))
    table.insert(out, "] = ")
    table.insert(out, tostring(v))
    table.insert(out, ", ")
  end
  table.remove(out)
  return table.concat(out)
end

-- TODO
function Stat.fromData(stat_type, ...)
  if stat_type == "basic"     then return Stat(...)           end
  if stat_type == "composite" then return Stat.Composite(...) end
  if stat_type == "table"     then return Stat.Table(...)     end
end

return Stat
