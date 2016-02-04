local rules = {}

local damage_type = { physical = "physical", magical = "magical"}
local damage_source = {
  physical     = damage_type.physical,
  slashing     = damage_type.physical,
  bludgeoning  = damage_type.physical,
  piercing     = damage_type.physical,
  magical      = damage_type.magical,
  fire         = damage_type.magical,
  cold         = damage_type.magical,
  lightning    = damage_type.magical,
  acid         = damage_type.magical,
  nonelemental = damage_type.magical
}


rules["initialize-character"] = function(gm, c)
  gm:applyRule("set-basic-stats", c)
  gm:applyRule("set-basic-actions", c)
end

rules["set-basic-stats"] = function(gm, c)
  c:addValue({"composite"     }, "status", "str"  )
  c:addValue({"composite"     }, "status", "dex"  )
  c:addValue({"composite"     }, "status", "con"  )
  c:addValue({"composite"     }, "status", "int"  )
  c:addValue({"simple",      1}, "status", "hp"   )
  c:addValue({"composite",   1}, "status", "maxhp")
  c:addValue({"simple"        }, "status", "mp"   )
  c:addValue({"composite"     }, "status", "maxmp")
  c:addValue({"simple"        }, "status", "ap"   )
  c:addValue({"composite", 100}, "status", "maxap")
  c:addValue({"composite",   3}, "status", "spd"  )
  c:addValue({"composite",  25}, "status", "mov"  )
  c:addValue({"composite"     }, "status", "atk"  )
  c:addValue({"composite"     }, "status", "matk" )
  c:addValue({"composite"     }, "status", "def"  )
  c:addValue({"composite"     }, "status", "mdef" )
  c:addValue({"composite"     }, "status", "arm"  )
  c:addValue({"composite"     }, "status", "marm" )
  c:addValue({"simple"        }, "status", "level")
  c:addValue({"simple"        }, "status", "race" )
  c:addValue({"table"         }, "status", "class")
end

rules["set-basic-actions"] = function(gm, c)
  c:addAction("move")
  c:addAction("getPathTo")
  c:addAction("attack")
  c:addAction("endTurn")
  c:addAction("getRange")
  c:addAction("isInRange")
  c:addAction("getDistance")
  c:addAction("getClosestInRange")
  c:addAction("getAttackCost")
  c:addAction("getFarthest")
end

rules["move-character"] = function(gm, c, path)
  return c:move(path)
end

local function computeAttackModifiers(gm, c, target, weapon, bonus)
  for _,item in pairs(c.equipment) do
    if item.onAttack then
      item:onAttack(gm, c, target, weapon, bonus)
    end
  end
end

local function computeDefenseModifiers(gm, c, target, weapon, bonus)
  for _,item in pairs(target.equipment) do
    if item.sdef and weapon.base_damage_type and item.sdef[weapon.base_damage_type] then
      bonus:setMod(weapon.base_damage_type, -item.sdef[weapon.base_damage_type])
    end
    if item.def then bonus:addMod(item.name, item.def) end
    if item.onReceiveAttack then
      item:onReceiveAttack(gm, target, c, weapon, bonus)
    end
  end
end

rules["physical-attack"] = function(gm, c, target, atkmod, dmgmod)
  local weapon = c.equipment:get("weapon")
  if not weapon then return false end

  local atk = gm:newValue("composite")
  atk:setMod("base", c.status.atk:get())
  atk:setMod("weapon", weapon:getAttack(gm, c, target))
  atk:setMod("roll", gm:roll(10))
  if type(atkmod) == "function" then atkmod(atk) end
  computeAttackModifiers(gm, c, target, weapon, atk)

  local def = gm:newValue("composite")
  def:setMod("dex", target.status.dex:get())
  def:setMod("base", target.status.def:get())
  computeDefenseModifiers(gm, c, target, weapon, def)

  if atk:get() > def:get() then
    gm.logcc(c, target, "Physical attack (hit), atk:"..atk:get()..", def:"..def:get())
    local dmg = gm:newValue("composite")
    weapon:getDamage(gm, c, target, dmg)
    if type(dmgmod) == "function" then dmgmod(dmg) end
    return true, gm:applyRule("damage", c, target, dmg)
  else
    gm.logcc(c, target, "Physical attack (miss), atk:"..atk:get()..", def:"..def:get())
    return false;
  end
end

local function computeDamageModifiers(gm, c, target, damage)
  local red = {}
  for _,item in pairs(target.equipment) do
    if item.sarm then
      for k,v in pairs(damage) do
        if item.sarm[k] then
          if not red[k] then red[k] = 0 end
          red[k] = red[k] + v
        end
      end
    end
  end
  for dmg_type,dmg_value in pairs(damage) do
    if red[dmg_type] then damage:subMod(dmg_type, red[dmg_type], 0) end
  end
end

rules["damage"] = function(gm, c, target, damage)
  local arm = target.status.arm:get()
  local marm = target.status.marm:get()
  local magical_damage = 0
  local physical_damage = 0
  local other_damage = 0
  local full_damage = damage:get()

  for _,item in pairs(c.equipment) do
    if item.onInflictDamage then item:onInflictDamage(gm, c, target, damage) end
  end

  for _,item in pairs(target.equipment) do
    if item.onReceiveDamage then item:onReceiveDamage(gm, target, c, damage) end
  end

  computeDamageModifiers(gm, c, target, damage)

  for dmg_type,dmg_value in damage:pairs() do gm.logc(c, dmg_type,dmg_value)
    if damage_source[dmg_type] == damage_type.physical then
      physical_damage = physical_damage + dmg_value
    elseif damage_source[dmg_type] == damage_type.magical then
      magical_damage = magical_damage + dmg_value
    else
      other_damage = other_damage + dmg_value
    end
  end

  -- Armor and magic armor damage reduction
  local physical_damage = math.max(0, physical_damage - arm)
  local magical_damage = math.max(0, magical_damage - marm)

  local final_damage = physical_damage + magical_damage + other_damage
  local efficiency = final_damage / full_damage

  if final_damage > 0 then
    gm.logcc(c, target, "Damage, dmg:"..final_damage..", eff:"..efficiency)
    gm:applyRule("direct-damage", target, final_damage)
    return final_damage
  else
    gm.logcc(c, target, "No damage")
    return false
  end
end

rules["direct-damage"] = function(gm, c, dmg)
  local hp = c.status.hp:sub(dmg)
  gm.logc(c, "Hit for "..dmg.." damage, hp left:"..c.status.hp:get())
  if hp <= 0 then
    gm:applyRule("kill", c)
  end
end

rules["kill"] = function(gm, c)
  gm.logc(c, "Dead")
  gm:killCharacter(c)
end

rules["turn-start"] = function(gm)
  for _,c in pairs(gm.world.characters) do
    c.status.ap:set(c.status.maxap:get())
  end
end

rules["initiative"] = function(gm, c)
  return gm:roll(10) + c.status.spd:get()
end

rules["start"] = function(gm)
  for _,c in pairs(gm.world.characters) do
    c.status.hp:set(c.status.maxhp:get())
    c.status.mp:set(c.status.maxmp:get())
    c.status.ap:set(c.status.maxap:get())
  end
end

return {
  rules = rules
}
