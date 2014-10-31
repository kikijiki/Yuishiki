local Observable

return function(loader)
  if Observable then return Observable end
  Observable = loader.class("Observable")

  function Observable:initialize()
    self.observers = setmetatable({}, {__mode="k"})
  end

  function Observable:addObserver(l, c)
    self.observers[l] = c
  end

  function Observable:notify(...)
    for _,observer in pairs(self.observers) do
      observer(...)
    end
  end

  return Observable
end
