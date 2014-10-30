local class = require "lib.middleclass"
local Observable = require "observable"

local Value = {}

local SimpleValue = class("SimpleValue", Observable)
Value.Simple = SimpleValue

function SimpleValue:initialize(value)
  Observable.initialize(self)
  self.value = value or 0
end

function SimpleValue:__tostring()
  return tostring(self.value)
end

function SimpleValue:update(v)
  local old = self.value
  self.value = v
  if old ~= v then self:notify(v, old) end
  return v
end

function SimpleValue:set(v)
  return self:update(v)
end

function SimpleValue:add(v)
  return self:update(self.value + v)
end

function SimpleValue:sub(v)
  return self:update(self.value - v)
end

function SimpleValue:get()
  return self.value
end

local CompositeValue = class("CompositeValue", SimpleValue)
Value.Composite = CompositeValue

function CompositeValue:initialize(value)
  self.modifiers = {}

  if type(value) == "table" then
    SimpleValue.initialize(self)
    self:setMods(value)
  else
    SimpleValue.initialize(self, value)
    self.base = self.value
  end
end

function CompositeValue:setMods(mods)
  for k,v in pairs(mods) do self:setMod(k,v) end
end

function CompositeValue:setMod(name, value)
  self.modifiers[name] = value
  return self:update()
end

function CompositeValue:addMod(name, value)
  local mod = self.modifiers[name] or 0
  mod = mod + value
  self.modifiers[name] = mod
  return self:update()
end

function CompositeValue:subMod(name, value)
  local mod = self.modifiers[name] or 0
  mod = mod - value
  self.modifiers[name] = mod
  return self:update()
end

function CompositeValue:unsetMod(name)
  self.modifiers[name] = nil
  return self:update()
end

function CompositeValue:update()
  local v = self.base
  for _,mod in pairs(self.modifiers) do
    v = v + mod
  end
  return SimpleValue.update(self, v)
end

function CompositeValue:set(v)
  self.base = v
  return self:update()
end

function CompositeValue:add(v)
  self.base = self.base + v
  return self:update()
end

function CompositeValue:sub(v)
  self.base = self.base - v
  return self:update()
end

local TableValue = class("TableValue", SimpleValue)
Value.Table = TableValue

function TableValue:initialize(v)
  if type(v) == "table" then
    SimpleValue.initialize(self, v)
  else
    SimpleValue.initialize(self, {})
  end
end

function TableValue:set(k, v)
  local old = self.value[k]
  self.value[k] = v
  if v ~= old then
    self:update(k, v, old)
  end
end

function TableValue:insert(v)
  local old = self.value
  table.insert(self.value, v)
  self:update(#self.value, v)
  return #self.value
end

function TableValue:get(k)
  if k then
    return self.value[k]
  else
    return self.value
  end
end

function TableValue:isset(k)
  return self.value[k] ~= nil
end

function TableValue:__pairs()
  return pairs(self.value)
end

function TableValue:__ipairs()
  return ipairs(self.value)
end

function TableValue:update(key, new_element, old_element)
  self:notify(self.value, nil, key, new_element, old_element)
end

function TableValue:__tostring()
  local out = {}
  for k,v in pairs(self.value) do
    table.insert(out, " - "..tostring(k).." = "..tostring(v))
  end
  return "{\n"..table.concat(out, ", \n").."\n}"
end

-- TODO
function Value.fromData(value_type, ...)
  if value_type == "simple"    then return Value.Simple(...)    end
  if value_type == "composite" then return Value.Composite(...) end
  if value_type == "table"     then return Value.Table(...)     end
end

return Value
