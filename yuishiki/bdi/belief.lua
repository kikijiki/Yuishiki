assert(ys, "Yuishiki is not loaded.")

-- TODO: belief history

local Belief = ys.common.class("BDI_Belief")
Belief.static.Source = ys.common.uti.makeEnum("Internal", "External", "Dynamic")

local Event = ys.mas.Event

function Belief:initialize(name, value) assert(name)
  self.name = name
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
  Belief.initialize(self, name)
  self.source = Belief.Source.Internal
  self.value = value
end

--[[External Belief]]--

local ExternalBelief = ys.common.class("ExternalBelief", Belief)
Belief.External = ExternalBelief

function ExternalBelief:initialize(name, getter)
  Belief.initialize(self, name, getter)
  self.source = Belief.Source.External
end

function ExternalBelief:get()
  if self.value then
    return self.value()
  end
end

function ExternalBelief:bind(getter)
  self.value = getter
end

function ExternalBelief:update(old)
  Belief.onChange(self, old)
end

function ExternalBelief:clone()
  local copy = ExternalBelief(self.name, self.value)
  return copy
end

--[[Dynamic Belief]]--

local DynamicBelief = ys.common.class("DynamicBelief", Belief)
Belief.Dynamic = DynamicBelief

function DynamicBelief:initialize(name, data) assert(data) assert(data.f)
  Belief.initialize(self, name)
  
  self.data = data -- keep for easy cloning.
  self.source = Belief.Source.Dynamic
  self.f = data.f
  self.refresh = data.refresh or {}
  self:update(true)
  
  if self.refresh.timed then
    -- Register to an appropriate service
    assert(false, "Not implemented.") -- low priority
  end
end

-- Hmm, fire the event only if it's a timed update.
function DynamicBelief:update(suppressEvent)
  local old = self.value
  self.value = self.f()
  
  if suppressEvent ~= true then
    Belief.onChange(self, old)
  end
end

function DynamicBelief:get()
  if self.refresh.always then self:update(true) end
  return self.value
end

--[[BeliefSet]]

local BeliefSet = ys.common.class("BeliefSet", Belief)
Belief.Set = BeliefSet

function BeliefSet:initialize(name)
  Belief.initialize(self, name)
  self.value = {}
  self.keys = {}
end

function BeliefSet:set(k, v)
  self.value[k] = v
  self.keys[v] = k
  self:onChange("set", k, v)
end

function BeliefSet:unset(k)
  local v = self.value[k]
  self.value[k] = nil
  self.keys[v] = nil
  self:onChange("unset", k, v)
end

function BeliefSet:get(k)
  return self.value[k]
end

function BeliefSet:append(v)
  table.insert(self.value, v)
  local k = #self.values
  self.keys[v] = k
  self:onChange("append", k, v)
end

function BeliefSet:pairs()
  return pairs(self.value)
end

function BeliefSet:onChange(change, key, ...)
  if self.dispatcher then
    local event = Event.BeliefSet(self, change, key, ...)
    self.dispatcher:send(event)
    if self.parent then
      self.parent:onChildChange(event)
    end
  end
end

function BeliefSet:onChildChange(child_event)
  if self.dispatcher then
    local child = child_event.belief
    local key = self.keys[child]
    local event = Event.BeliefSet(self, "child", key, child_event)
    self.dispatcher:send(event)
    if self.parent then
      self.parent:onChildChange(event)
    end
  end
end

function Belief.fromData(name, data)
  if data[1] == "internal" then return Belief.Internal(name, select(2, unpack(data))) end
  if data[1] == "external" then return Belief.External(name, select(2, unpack(data))) end
end

return Belief