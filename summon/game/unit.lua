assert(summon, "SUMMON is not loaded.")

local vec = summon.vec
local entity = summon.game.Entity

local Unit = summon.class("Unit", entity)

function Unit:initialize(data)
  entity.initialize(self)
  
  self.name = data.name
  self.sprite = summon.AssetLoader.load("sprite", data.sprite)
  self.ai = {}
end

function Unit.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  local u = Unit(data)
  return u
end

function Unit:draw(lg)
  self.sprite:draw(lg)
end

function Unit:update(dt)
  self.sprite:update(dt)
end

return Unit