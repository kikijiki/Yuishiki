assert(summon, "SUMMON is not loaded.")

local vec = summon.vec
local draw = summon.graphics.draw
local Animation = summon.graphics.sprite.Animation

local Sprite = summon.class("Sprite")

function Sprite:initialize(spritesheet)
  self.spritesheet = spritesheet
  self.texture = spritesheet.texture
  self.animations = {}
  self.position = vec(0, 0)
  self.z = 0
  self.scale = 1
  self.direction = "SE"
  self.current = {}
  self.speed = {movement = 100, animation = 1}
end

function Sprite.static.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  local ss = summon.AssetLoader.load("spritesheet", data.spritesheet)

  local sprite = Sprite(ss)
  sprite.scale = data.scale
  
  for k,v in pairs(data.animations) do
    local a = Animation.parse(k, v, ss)
    sprite.animations[k] = a
  end

  if sprite.animations["idle"] then sprite.current.animation = sprite.animations["idle"]
  else sprite.current.animation = select(2, next(sprite.animations)) end
  sprite:update(0)

  return sprite
end

function Sprite:setAnimation(name, reset)
  if not self.animations[name] then return end
  
  local a = self.current.animation
  if a.name == name and a.loop <= 0 then
    if reset then a:reset() end
    return
  end

  self.current.animation = self.animations[name]
  if not reset == false then self.current.animation:reset() end
end

function Sprite:setDirection(dir)
  dir = string.upper(dir)
  self.direction = dir
end

function Sprite:getPosition()
  return self.position
end

function Sprite:getTag(tag, side)
  local tags = self.current.frame.tags
  local pos = self.position
  if not tags[tag] then return end
  
  if side and tags[tag][side] then
    return (pos + tags[tag][side].position * self.scale), tags[tag][side].z
  else
    return (pos + tags[tag].position * self.scale), tags[tag].z
  end
end

function Sprite:setPosition(v, z)
  self.position = v
  if z then self.z = z end
end

function Sprite:setPositionFromTile(map, v)
  local tilec = map:getTilePixelCoordinates(v)
  self:setPosition(tilec.top, tilec.spriteZ)
end

function Sprite:move(v, z)
  self.position = self.position + v
  if z then self.z = self.z + z end
end

function Sprite:updateAnimation(dt)
  local frame = self.current.animation:update(dt * self.speed.animation, self.direction)
  self.current.frame = frame
  self.current.center = frame.center
end

function Sprite:update(dt)
  self:updateAnimation(dt)
end

function Sprite:draw()
  local frame = self.current.frame
  local scale = self.scale
  
  if not frame.quad then return end
  
  local pos = self.position
  local cnt = frame.center
  
  if frame.mirror then
    draw(self.texture.data, frame.quad, pos.x, pos.y, 0, -scale, scale,  cnt.x, cnt.y)
  else
    draw(self.texture.data, frame.quad, pos.x, pos.y, 0, scale, scale, cnt.x, cnt.y)
  end
end

function Sprite:face(v)
  local dir
  local diff1 = vec(v.x - v.y, v.x + v.y)
  local diff2 = vec(self.position.x - self.position.y, self.position.x + self.position.y)
  local diff = diff1 - diff2
  
  if math.abs(diff.x) > math.abs(diff.y) then
    if diff.x > 0 then dir = "NE" else dir = "SW" end
  else
    if diff.y > 0 then dir = "SE" else dir = "NW" end
  end

  setDirection(dir)
end

return Sprite