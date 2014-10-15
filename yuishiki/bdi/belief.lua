assert(ys, "Yuishiki is not loaded.")

-- TODO: belief history

local Belief = ys.common.class("BDI_Belief")
Belief.static.Source = ys.common.uti.makeEnum("Internal", "External")

local Event = ys.mas.Event

function Belief:initialize(name, value) assert(name)
  self.name = name
  self.path = nil
  self.value = value
end

function Belief:get()
  return self.value
end

function Belief:set(value)
  local old = self.value
  self.value = value
  self:onChange(old)
end

function Belief:onChange(old)
  if self.dispatcher then
    local event = Event.Belief(self, old)
    self.dispatcher:send(Event.Belief(self, old))
    if self.parent then
      self.parent:onChildChange(self, event)
    end
  end
end

function Belief.getYsType()
  return "belief"
end

--[[Internal Belief]]--

local InternalBelief = ys.common.class("InternalBelief", Belief)
Belief.Internal = InternalBelief

function InternalBelief:initialize(name, value)
  Belief.initialize(self, name, value)
  self.source = Belief.Source.Internal
end

--[[External Belief]]--

local ExternalBelief = ys.common.class("ExternalBelief", Belief)
Belief.External = ExternalBelief

function ExternalBelief:initialize(name, value)
  Belief.initialize(self, name, value)
  self.source = Belief.Source.External
end

function ExternalBelief:get()
  if type(self.value) == "function" then return self.value()
  else return self.value end
end

function ExternalBelief:set()
  ys.log.w("Trying to change the external belief <"..self.name..">.")
end

--[[BeliefSet]]

local Beliefset = ys.common.class("Beliefset", Belief)
Belief.Set = Beliefset

function Beliefset:initialize(name)
  Belief.initialize(self, name)
  self.value = {}
  self.keys = {}
end

function Beliefset:set(k, v)
  self.value[k] = v
  self.keys[v] = k
  self:onChange("set", k, v)
end

function Beliefset:unset(k)
  local v = self.value[k]
  self.value[k] = nil
  self.keys[v] = nil
  self:onChange("unset", k, v)
end

function Beliefset:get(k)
  return self.value[k]
end

function Beliefset:append(v)
  table.insert(self.value, v)
  local k = #self.values
  self.keys[v] = k
  self:onChange("append", k, v)
end

function Beliefset:pairs()
  return pairs(self.value)
end

function Beliefset:onChange(change, key, ...)
  if self.dispatcher then
    local event = Event.Beliefset(self, change, key, ...)
    self.dispatcher:send(event)
    if self.parent then
      self.parent:onChildChange(event)
    end
  end
end

function Beliefset:onChildChange(child_event)
  if self.dispatcher then
    local child = child_event.belief
    local key = self.keys[child]
    local event = Event.Beliefset(self, "child", key, child_event)
    self.dispatcher:send(event)
    if self.parent then
      self.parent:onChildChange(event)
    end
  end
end

-- TODO beliefset, dynamic
function Belief.fromData(name, data)
  if data[1] == "internal" then return Belief.Internal(name, select(2, unpack(data))) end
  if data[1] == "external" then return Belief.External(name, select(2, unpack(data))) end
end

return Belief
