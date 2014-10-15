assert(ys, "Yuishiki is not loaded.")

-- TODO: belief history

local Belief = ys.common.class("BDI_Belief")
Belief.static.Source = ys.common.uti.makeEnum("Internal", "External")

local Event = ys.mas.Event

function Belief:initialize(value, source)
  self.path = nil
  self.value = value
  self.source = source
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

function InternalBelief:initialize(value)
  Belief.initialize(self, value, Belief.Source.Internal)
end

--[[External Belief]]--

local ExternalBelief = ys.common.class("ExternalBelief", Belief)
Belief.External = ExternalBelief

function ExternalBelief:initialize(value, Belief.Source.External)
  Belief.initialize(self, value)
end

function ExternalBelief:get()
  if type(self.value) == "function" then return self.value()
  else return self.value end
end

function ExternalBelief:set()
  ys.log.w("Trying to change the external belief <"..self.path..">.")
end

--[[BeliefSet]]

local Beliefset = ys.common.class("Beliefset", Belief)
Belief.Set = Beliefset

function Beliefset:initialize(source)
  Belief.initialize(self, {}, source or Belief.Source.External)
  self.keys = {}
end

function Beliefset:set(k, v)
  self.value[k] = v
  self.keys[v] = k
  v.path = self.path + "." + k
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

function Beliefset:__index(t, k)
  return self:get(k)
end

function Beliefset:__newindex(t, k, v)
  return self:set(k, v)
end

function Beliefset:append(v)
  self:set(#self.values + 1, v)
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

-- TODO beliefset, use path
function Belief.fromData(path, data)
  return Belief.Internal(unpack(data)) end
end

return Belief
