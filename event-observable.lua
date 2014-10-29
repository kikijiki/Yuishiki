local class = require "lib.middleclass"

local EventObservable = class("EventObservable")

function EventObservable:initialize()
  self.events = {nodes = {}, leafs = setmetatable({}, {__mode="k"})}
end

function EventObservable:addObserver(observer, event, handler)
  local target = self.events

  if type(event) == "table" then
    for _,v in pairs(event) do
      if not target.nodes[v] then target.nodes[v] = {nodes = {}, leafs = setmetatable({}, {__mode="k"})} end
      target = target.nodes[v]
    end
  end

  target.leafs[observer] = handler
end

function EventObservable:notify(source, event, ...)
  local target = self.events
  -- catch all
  for observer, handler in pairs(target.leafs) do
    if observer ~= source then handler(source, event, ...) end
  end

  -- match
  for _,v in pairs(event) do
    if target.nodes[v] then target = target.nodes[v] end
    for observer, handler in pairs(target.leafs) do
      if observer ~= source then handler(source, event, ...) end
    end
  end
end

return EventObservable
