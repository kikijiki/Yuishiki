local class = require "lib.middleclass"
local EventDispatcher = class("EventDispatcher")

function EventDispatcher:initialize()
  self.events = {}
end

function EventDispatcher:listen(l, event, fun)
  if not self.events[event] then self.events[event] = setmetatable({},{__mode="k"}) end
  self.events[event][l] = fun
end

function EventDispatcher:unlisten(l, event)
  if event then
    self.events[event][l] = nil
  else
    for _,listeners in pairs(self.events) do
      listeners[l] = nil
    end
  end
end

function EventDispatcher:dispatch(event, ...)
  if self.events[event] then
    for _,callback in pairs(self.events[event]) do
      callback(...)
    end
  end
end

return EventDispatcher
