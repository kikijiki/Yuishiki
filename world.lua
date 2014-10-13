local World = summon.class("World")
local vec = summon.vec

function World:initialize(map) assert(map)
  self.characters = {}
  self.map = map
end

function World:addCharacter(character, id) assert(character)
  character:setEnvironment(self, id)

  if id then
    self.characters[id] = character
  else
    table.insert(self.characters, character)
  end
end

function World:removeCharacter(char)
  if type(char) == "table" then
    if char.id then self.characters[char.id] = nil end
  else
    self.characters[char] = nil
  end
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

function World:dispatchEvent(source, e)
  for _,c in pairs(self.characters) do
    if c ~= source then c.agent:sendEvent(e) end
  end
end

return World
