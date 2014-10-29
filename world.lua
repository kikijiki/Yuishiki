local class = require "lib.middleclass"
local vec = summon.vec
local EventObservable = require "event-observable"

local World = class("World", EventObservable)

function World:initialize(map) assert(map)
  EventObservable.initialize(self)

  self.characters = {}
  self.map = map

  self.events_enabled = false
end

function World:addCharacter(character, id) assert(character)
  if id then
    self.characters[id] = character
  else
    table.insert(self.characters, character)
    id = #self.characters
  end

  character:setEnvironment(self, id)
end

function World:removeCharacter(char)
  if type(char) == "table" then
    if char.id then self.characters[char.id] = nil end
  else
    self.characters[char] = nil
  end
end

function World:start()
  self.events_enabled = true
end

function World:placeCharacter(char, x, y)
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

function World:propagateEvent(source, event, ...)
  if self.events_enabled then
    self:notify(source, event, ...)
  end
end

return World
