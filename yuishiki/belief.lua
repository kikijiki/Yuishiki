return function(loader)
  local log = loader.load "log"
  local uti = loader.load "uti"
  local Event = loader.load "event"
  local Observable = loader.load "observable"

  local Belief = loader.class("BDI.Belief", Observable)

  Belief.static.Status = uti.makeEnum("changed", "new", "deleted")

  function Belief:initialize(value, name, path, retention, source)
    Observable.initialize(self)

    self.name = name
    self.path = path

    self.value  = value

    self.retention = retention or "short"
    self.source  = source or "internal"
    self.history = nil -- TODO: save past values.
  end

  function Belief.getYsType()
    return "belief"
  end

  function Belief:get()
    if type(self.value) == "table" and self.value.get then
      return self.value:get()
    else
      return self.value
    end
  end

  function Belief:set(value)
    if self.source == "external" then
      log.fw("Trying to write the external belief [%s].", self.path)
      return
    end

    local old = self:get()

    if type(self.value) == "table" and self.value.set then
      self.value:set(value)
    else
      self.value = value
    end

    self:notify(self, value, old)
  end

  function Belief:__tostring()
    return tostring(self.value)
  end

  return Belief
end
