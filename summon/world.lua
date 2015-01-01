local World

return function(loader)
  if World then return World end

  local vec             = loader.require "vector"
  local log             = loader.load "log"
  local EventObservable = loader.load "event-observable"

  World = loader.class("World", EventObservable)

  function World:initialize(map) assert(map)
    EventObservable.initialize(self)

    self.characters          = {}
    self.inactive_characters = {}
    self.map                 = map
    self.events_enabled      = false
    self.event_queue         = {}
    self.log                 = log.tag("world")
  end

  function World:addCharacter(character, id) assert(character)
    if id then
      self.characters[id] = character
    else
      table.insert(self.characters, character)
      id = #self.characters
    end

    character:setWorld(self, id)
    self:propagateEvent(character, {"character", "new"})
  end

  function World:removeCharacter(character)
    if type(character) == "table" then
      if character.id then
        self.inactive_characters[character.id] = self.characters[character.id]
        self.characters[character.id] = nil
      end
    else
      self.inactive_characters[character] = self.characters[character]
      self.characters[character] = nil
    end
    self:propagateEvent(character, {"character", "removed"})
  end

  function World:start()
    self.events_enabled = true
    for _,event_data in pairs(self.event_queue) do
      self:propagateEvent(table.unpack(event_data))
    end
  end

  function World:placeCharacter(char, x, y, direction)
    local pos
    if type(char) == "string" then char = self.characters[char] end

    if not x then
      pos = char.status.position:get()
    else
      if y then pos = vec(x, y)
      else pos = x end
    end
    char.status.position:set(pos)
    char.sprite:setPositionFromTile(self.map, pos)
    if direction then char.sprite:setDirection(direction) end
  end

  function World:draw()
    self.map:draw()
    for _,character in pairs(self.characters) do
      character:draw(self.map)
    end
  end

  function World:update(dt)
    self.map:update(dt)
    for _,character in pairs(self.characters) do
      character:update(dt)
    end
  end

  function World:otherCharacterPairs(c)
    local char = self.characters

    function next_char()
      for k,v in pairs(char) do
        if v ~= c then coroutine.yield(k, v) end
      end
    end
    local f = coroutine.create(next_char)
    return function()
      return select(2, coroutine.resume(f))
    end
  end

  function World:propagateEvent(source, event, ...) assert(source and event)
    if type(event) == "string" then event = {event} end
    if self.events_enabled then
      self:notify(source, event, ...)
    else
      table.insert(self.event_queue, {source, event, ...})
    end
  end

  function World:exportAgentData()
    local data = {}
    for id, char in pairs(self.characters) do
      data[id] = char.agent:save()
    end
    for id, char in pairs(self.inactive_characters) do
      data[id] = char.agent:save()
    end
    return data
  end

  function World:importAgentData(data)
    for id, agent_data in pairs(data) do
      if self.characters[id] then
        self.characters[id].agent:restore(agent_data)
      elseif self.inactive_characters[id] then
        self.inactive_characters[id].agent:restore(agent_data)
      end
    end
  end

  return World
end
