local Event

return function(loader)
  if Event then return Event end

  Event = loader.class("Event")

  function Event:initialize(name, parameters) assert(name)
    if type(name) ~= "table" then name = {name} end
    self.name = name
    self.parameters = parameters
    if parameters then
      for k,v in pairs(parameters) do self[k] = v end
    end
  end

  function Event:getType() return self.name[1] end

  function Event.goal(goal)
    return Event({"goal", goal.name}, {goal = goal})
  end

  function Event.message(message)
    return Event("message", {message = message})
  end

  function Event.actuator(id, data)
    return Event({"actuator", id}, data)
  end

  function Event.belief(belief, status, new, old, ...)
    return Event({"belief", belief.path}, {
      belief = belief,
      status = status,
      new = new,
      old = old,
      args = {...}
    })
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
