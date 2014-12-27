local EventObservable

return function(loader)
  if EventObservable then return EventObservable end
  EventObservable = loader.class("EventObservable")

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

    if target.leafs[observer] then table.insert(target.leafs[observer], handler)
    else target.leafs[observer] = {handler} end
  end

  function EventObservable:notify(source, event, ...)
    local target = self.events
    -- catch all
    for observer, handlers in pairs(target.leafs) do
      if observer ~= source then
        for _, handler in pairs(handlers) do
          handler(source, event, ...)
        end
      end
    end

    -- match
    for _,v in pairs(event) do
      if target.nodes[v] then target = target.nodes[v] end
      for observer, handlers in pairs(target.leafs) do
        if observer ~= source then
          for _, handler in pairs(handlers) do
            handler(source, event, ...)
          end
        end
      end
    end
  end

  return EventObservable
end
