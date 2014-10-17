return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local Event = loader.load "event"
  local Observable = loader.load "observable"

  local Belief = class("BDI.Belief", Observable)

  Belief.static.Status = uti.makeEnum("changed", "new", "deleted")

  function Belief:initialize(value, name, base_path, readonly)
    Observable.initialize(self)

    self.name = name
    self.base_path = base_path
    self.full_path = base_path.."."..name

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

  function Belief:__tostring()
    return tostring(self:get())
  end

  return Belief
end
