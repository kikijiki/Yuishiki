local EventDispatcher = ys.class("EventDispatcher")
local Event = ys.mas.Event

function EventDispatcher:initialize()
  self.listeners = {}

  for _,v in pairs(Event.EventType) do
    self.listeners[v] = {}
  end
end

 function EventDispatcher:register(l, event_types, priority)
  assert(
    l and 
    l.onEvent and 
    type(l.onEvent) == "function")

  event_types = event_types or Event.EventType
  if type(event_types) ~= "table" then event_type = {event_type} end

  for _,event_type in pairs(event_types) do
    table.insert(self.listeners[event_type], setmetatable({priority = priority, listener = l}, {__mode = "v"}))
    table.sort(self.listeners[event_type],
      function(a, b)
        return a.priority < b.priority
      end)
  end
end

function EventDispatcher:unregister(l)
  for _,event_type_list in pairs(self.listeners) do
    for k, listener_entry in pairs(event_type_list) do
      if listener_entry.listener == l then
        event_type_list[k] = nil
      end
    end
  end
  self.listeners[l] = nil
end

function EventDispatcher:send(event)
  for _,listener_entry in pairs(self.listeners[event.event_type]) do
    listener_entry.listener:onEvent(event)
  end
end

return EventDispatcher