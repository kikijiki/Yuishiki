local Event

return function(loader)
  if Event then return Event end

  Event = loader.class("Event")

  function Event:initialize(name, parameters) assert(name)
    if type(name) ~= "table" then name = {name} end
    self.name = name
    if parameters then
      self.parameters = parameters
      for k,v in pairs(parameters) do self[k] = v end
    end
  end

  function Event:getType() return self.name[1] end

  function Event.goal(goal)
    return Event({"goal", goal.name}, goal.parameters)
  end

  function Event.message(message)
    return Event("message", {message = message})
  end

  function Event.actuator(id, data)
    return Event({"actuator", id}, data)
  end

  function Event.belief(belief, status, new, old, ...)
    return Event({"belief", belief.path.full}, {
      belief = belief,
      status = status,
      new = new,
      old = old,
      args = {...}
    })
  end

  function Event.game(event, data)
    return Event({"game", event}, data)
  end

  function Event.system(name, parameters)
    return Event({"system", name}, parameters)
  end

  function Event.static.fromData(event_type, ...)
    event_type = string.lower(event_type)
    if Event[event_type] then return Event[event_type](...) end
  end

  return Event
end
