local Item = require "item"
local Weapon = summon.class("Weapon", Item)

function Weapon:initialize(data)
  Item.initialize(self, data.name, "weapon", "weapon")
  self.attack = data.attack
  self.damage = data.damage
  self.range = data.range
  self.cost = data.cost
end

function Weapon:getAttack(gm, c, target)
  return self:attack(gm, c, target)
end

function Weapon:getDamage(gm, c, target)
  return self:damage(gm, c, target)
end

function Weapon:getCost(gm, c, target)
  return self:cost(gm, c, target)
end

return Weapon
