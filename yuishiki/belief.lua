return function(loader)
  local class = loader.require "middleclass"
  local Event = loader.load "event"
  local Observable = loader.load "observable"
  local uti = loader.load "uti"

  local Belief = class("BDI.Belief", Observable)

  Belief.static.Source = uti.makeEnum("Internal", "External")

  function Belief:initialize(value, name, path, readonly)
    self.name = name
    self.base_path = path
    self.full_path = path.."."..name

    self.value  = value
    self.readonly = readonly or false

    self.source  = nil -- TODO
    self.history = nil -- TODO
  end

  function Belief.getYsType()
    return "belief"
  end

  function Belief:get()
    if self.value.get then return self.value:get()
    else return self.value end
  end

  function Belief:set(value)
    if self.readonly then return end
    local old = self:get()

    if self.value.set then
      self.value:set(value)
    else
      self.value = value
    end

    self:notify(self, self:get(), old)
  end

  return Belief
end
