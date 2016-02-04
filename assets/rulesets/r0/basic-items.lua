local items = {}

items["katana"] = {
  name = "Katana",
  item_type = "weapon",
  base_damage_type = "slashing",
  range = 1,
  attack = 5,
  damage = function(w, gm, c, target, dmg)
    dmg:setMod("slashing", (c.status.str:get() + gm:roll(1, 10)))
  end,
  maxDamage = function(w, gm, c, target)
    return c.status.str:get() + 10
  end,
  minDamage = function(w, gm, c, target)
    return c.status.str:get() + 1
  end,
  cost = 25,
  -- triggers = {
  --   onAttack = function(w, gm, c, target, bonus) end
  --   onDamage = function(w, gm, c, target, damage) end
  -- },
}

items["oni-club"] = {
  name = "Oni club",
  item_type = "weapon",
  base_damage_type = "bludgeoning",
  range = 1,
  attack = 6,
  damage = function(w, gm, c, target, dmg)
    dmg:setMod("bludgeoning", c.status.str:get() + gm:roll(1, 8))
    dmg:setMod("fire", gm:roll(1, 2))
  end,
  maxDamage = function(w, gm, c, target)
    return c.status.str:get() + 4 + 2
  end,
  minDamage = function(w, gm, c, target)
    return c.status.str:get() + 1 + 1
  end,
  cost = 60,
  -- triggers = {
  --   onAttack = function(w, gm, c, target, bonus) end
  --   onDamage = function(w, gm, c, target, damage) end
  -- },
}

items["oni-armor"] = {
  name = "Oni armor",
  item_type = "armor",
  def = 8,
  mdef = 0,
  arm = 3,
  marm = 0,
  -- sarm = {},
  -- triggers = {
  --   onAttacked = function(w, gm, c, target, weapon, bonus) end,
  --   onDamaged = function(w, gm, c, target, dmg_type, dmg) end,
  -- }
}

items["ninja-armor"] = {
  name = "Ninja armor",
  item_type = "armor",
  def = 4,
  mdef = 2,
  arm = 1,
  marm = 0,
  -- sarm = {},
  -- triggers = {
  --   onAttacked = function(w, gm, c, target, weapon, bonus) end,
  --   onDamaged = function(w, gm, c, target, dmg_type, dmg) end,
  -- }
}

return {
  items = items
}
