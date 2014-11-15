local Weapon

return function(loader)
  if Weapon then return Weapon end
  local Item = loader.load "item"

  Weapon = loader.class("Weapon", Item)

  function Weapon:initialize(data)
    Item.initialize(self, data.name, "weapon", "weapon")

    self.attack = data.attack or 0
    self.damage = data.damage or 0
    self.range = data.range or 0
    self.cost = data.cost or 0
    self.maxDamage = data.maxDamage or function() return 0 end
    self.minDamage = data.minDamage or function() return 0 end

    self:addTrigger(self.triggers)

    if data.initialize then data.initialize(self) end
  end

  function Weapon:getAttack(gm, c, target)
    if type(self.attack) == "function" then
      return self:attack(gm, c, target)
    else
      return self.attack
    end
  end

  function Weapon:getDamage(gm, c, target, dmg)
    if type(self.damage) == "function" then
      return self:damage(gm, c, target, dmg)
    else
      return self.damage
    end
  end

  function Weapon:getCost(gm, c, target)
    if type(self.cost) == "function" then
      return self:cost(gm, c, target)
    else
      return self.cost
    end
  end

  return Weapon
end
