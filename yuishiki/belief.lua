assert(ys, "Yuishiki is not loaded.")

local Event = ys.mas.Event
local EventDispatcher = ys.common.EventDispatcher

local Belief = ys.common.class("BDI.Belief", EventDispatcher)

Belief.static.Source = ys.common.uti.makeEnum("Internal", "External")

function Belief:initialize(value, name, path, getter, setter)
  self.name = name
  self.base_path = path
  self.full_path = path.."."..name

  self.value  = value
  self.getter = getter
  self.setter = setter

  self.source  = nil -- TODO
  self.history = nil -- TODO
end

function Belief.getYsType()
  return "belief"
end

function Belief:get()
  if self.getter then return self.getter(self.value)
  else return self.value end
end

function Belief:set(value)
  if self.setter then
    local old = self:get()
    if type(self.setter) == "function" then
      self.value = self.setter(self.value, value)
    else
      self.value = value
    end
    self:notify(self, self:get(), old)
  end
end

return Belief
