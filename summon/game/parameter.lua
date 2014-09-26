assert(summon, "SUMMON is not loaded.")

local Parameter = summon.class("Parameter")
Parameter.static.simple = {}
Parameter.static.list = {}
Parameter.static.composite = {}

local clamp = summon.common.uti.clamp
local shallowCopy = summon.common.uti.shallowCopy

local Modifier = summon.class("Modifier")

function Modifier:initialize(name, mode)
  self.name = name
  self.mode = mode
  self.value = 0
  self.sources = {}
end

function Modifier:compute()
  if self.mode == "stack" then
    local ret = 0
    for source,v in pairs(self.sources) do ret = ret + v.value end
    return ret
  end
  
  if self.mode == "max" then
    local _, ret = next(self.sources)
    if not ret then return 0 end
    ret = ret.value
    for _,v in pairs(self.sources) do ret = math.max(ret, v.value) end
    return ret
  end
  
  if self.mode == "min" then
    local _, ret = next(self.sources) 
    if not ret then return 0 end
    ret = ret.value
    for _,v in pairs(self.sources) do ret = math.min(ret, v.value) end
    return ret
  end
end

function Modifier:set(source, name, value)
  if self.sources[source] then
    if value then self.sources[source].value = value end
    if name then self.sources[source].name = name end
  else 
    self.sources[source] = 
      {source = source, name = name, value = value}
  end
end

function Modifier:remove(source)
  self.sources[source] = nil
end

function Modifier:reset()
  self.sources = {}
end

Parameter.static.simple = {}
Parameter.static.simple.set = function(self, value)
  self.changed = self.value ~= value
  self.value = value
end

Parameter.static.simple.get = function(self)
  if self.bounds then
    return clamp(self.value, self.bounds.min, self.bounds.max)
  else
    return self.value
  end
end

Parameter.static.simple.add = function(self, value)
  if value ~= 0 then
    self.value = self.value + value 
    self.changed = true
  end
end

Parameter.static.simple.sub = function(self, value)
  if value ~= 0 then
    self.value = self.value - value 
    self.changed = true
  end
end

Parameter.static.list = {}
Parameter.static.list.reset = function(self)
  self.value = {}
end

Parameter.static.list.push_back = function(self, value)
  self.changed = true
  if type(value) == "table" then
    for _,v in pairs(value) do table.insert(self.value, v) end
  else
    table.insert(self.value, value)
  end
end

Parameter.static.list.push_front = function(self, value)
  self.changed = true
  if type(value) == "table" then
    for i = #value, 1, -1 do table.insert(self.value, 1, value[i]) end
  else
    table.insert(self.value, 1, value)
  end
end

Parameter.static.list.pop_back = function(self)
  self.changed = #self.value > 0
  return table.remove(self.value)
end

Parameter.static.list.pop_front = function(self)
  self.changed = #self.value > 0
  return table.remove(self.value, 1)
end

Parameter.static.list.front = function(self)
  return self.value[1]
end

Parameter.static.list.back = function(self)
  return self.value[#self.value]
end

Parameter.static.list.get = function(self)
  return self.value
end

Parameter.static.list.contains = function(self, value)
  for i = 1, #self.value do
    if self.value[i] == value then return i end
  end

  return false
end

Parameter.static.list.remove = function(self, index)
  return table.remove(self.value, index)
end

Parameter.static.map = {}
Parameter.static.map.set = function(self, key, value)
  self.changed = self.value[key] ~= value
  self.value[key] = value
end

Parameter.static.map.remove = function(self, key)
  self.changed = self.value[key] ~= nil
  self.value[key] = nil
end

Parameter.static.map.contains = function(self, key)
  return self.value[key] ~= nil
end

Parameter.static.map.get = function(self, key)
  if key then return self.value[key]
  else return self.value end
end

Parameter.static.map.reset = function(self)
  self.changed = #self.value ~= 0
  self.value = {}
end

Parameter.static.composite = {}
Parameter.static.composite.addModifier = function(self, name, mode)
  self.modifiers[name] = Modifier(name, mode)
end

Parameter.static.composite.set = function(self, modifier, source, name, value)
  local v = self:get()
  self.modifiers[modifier]:set(source, name, value)
  self.changed = v ~= self:get()
end

Parameter.static.composite.get = function(self)
  local ret = self.f(self.modifiers)
  if self.bounds then return clamp(ret, self.bounds.min, self.bounds.max)
  else return ret end
end

Parameter.static.composite.sum = function(mod)
  local ret = 0
  for _,m in pairs(mod) do
    ret = ret + m:compute()
  end
end

function Parameter:initialize(data, value)
  self.name = data.name
  self.mode = data.mode
  self.changed = false
  
  if data.mode == "simple" then
    self.value = value or 0
    self.bounds = data.bounds
  elseif data.mode == "list" then 
    self.value = value or {}
  elseif data.mode == "map" then
    self.value = value or {}
  elseif mode == "composite" then
    self.value = 0
    self.bounds = data.bounds
    self.f = data.f or Parameter[mode].sum
    self.modifiers = {}
    if data.modifiers then
      for _,v in pairs(data.modifiers) do 
        self:addModifier(v.name, v.mode)
      end
    end
    if value then
      for _,v in pairs(value) do
        self:set(v[1], v[2], v[3], v[4])
      end
    end
  end

  for k,v in pairs(Parameter.static[self.mode]) do self[k] = v end
end

function Parameter:clone()
  local c = {}
  
  shallowCopy(self, c, true)
  shallowCopy(self.bounds, c.bounds)
  shallowCopy(self.value, c.value)
  
  if self.modifiers then 
    shallowCopy(self.modifiers, c.modifiers, true)
    shallowCopy(self.modifiers.sources, c.modifiers.sources)
  end
  
  return c
end

return Parameter