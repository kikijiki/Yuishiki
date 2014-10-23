local class = require "lib.middleclass"

local EventObservable = class("EventObservable")

function EventObservable:initialize()
  self.events = {}
  self.all = setmetatable({}, {__mode="k"})
end

function EventObservable:addObserver(observer, event, handler)
  local target
  if event == nil or event == "*" then
    target = self.all
  else
    if not self.events[event] then
      self.events[event] = setmetatable({}, {__mode="k"})
    end
    target = self.events[event]
  end

  target[observer] = handler
end

function EventObservable:notify(source, event, ...)
  if self.events[event] then
    for observer,handler in pairs(self.events[event]) do
      if observer ~= source then handler(...) end
    end
  end
  for observer,handler in pairs(self.all) do
    if observer ~= source then handler(...) end
  end
end

return EventObservable
