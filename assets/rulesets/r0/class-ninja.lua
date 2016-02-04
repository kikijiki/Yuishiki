local rules = {}

function levelUp(class, s, max_period)
  max_period = max_period or 10
  s.class:insert(class)

  local level = 0
  for _,c in pairs(s.class) do
    if c == class then level = level + 1 end
  end
  s.level:add(1)

  local lbonus = {}
  for i = 2, max_period do
    if level % i == 0 then lbonus[i] = 1 else lbonus[i] = 0 end
  end
  return s.level:get(), lbonus
end

rules["class-ninja"] = function(gm, c)
  local s = c.status
  local level, lbonus = levelUp("ninja", s)

  s.str  :addMod("ninja", lbonus[3])
  s.dex  :addMod("ninja", lbonus[2])
  s.con  :addMod("ninja", lbonus[4])
  s.maxhp:addMod("ninja", 2)
  s.maxap:addMod("ninja", 4)
  s.atk  :addMod("ninja", 1)
  s.def  :addMod("ninja", 1)
  s.mdef :addMod("ninja", lbonus[3])
  s.spd  :addMod("ninja", 1)

  if level == 2 then c:addAction("rengiri") end
  if level == 3 then c:addAction("disappear") end
  if level == 4 then c:addAction("daikyougeki") end
end

local actions = {}

-- Rengiri

local rengiri_atk_num  =  4 -- current animation allows up to 4.
local rengiri_atk_mod  = -4
local rengiri_dmg_mod  = -4
local rengiri_cost_mod =  2

actions["rengiri"] = {
  async = true,
  cost = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return 0 end
    return weapon:getCost(gm, c, target) * rengiri_cost_mod
  end,
  condition = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return false end
    local distance = gm:getCharacterDistance(c, target)
    return weapon.range >= distance
  end,
  body = function(gm, c, target)
    target = gm:getCharacter(target)
    local atk_dir = gm:getAttackDirection(c, target)
    local weapon = c.equipment:get("weapon")

    local total_damage = 0
    local max_damage =
      math.max(0, weapon:maxDamage(gm, c, target)
      + rengiri_dmg_mod) * rengiri_atk_num

    local function atkmod(atk) atk:setMod( "rengiri", rengiri_atk_mod) end
    local function dmgmod(dmg) dmg:addMod("physical", rengiri_dmg_mod) end

    local atkfun = function()
      local hit, damage =
        gm:applyRule("physical-attack", c, target, atkmod, dmgmod)

      c:bubble("ora!", -atk_dir)
      if hit then
        if damage then
          target:hit(damage, atk_dir)
          total_damage = total_damage + damage
        else
          c:bubble("no damage", atk_dir)
        end
      else
        c:bubble("miss", atk_dir)
      end
    end

    c:speak({
      ja = "連斬り！",
      en = "Slashing flurry!",
      it = "Raffica!"
    })

    local tags = {}
    for i = 1, rengiri_atk_num do tags["hit"..i] = atkfun end
    c:pushCommand("animation", "rengiri", { tags = tags })

    c:pushCommand("lookAt", target)
    target:pushCommand("lookAt", c)

    coroutine.yield()
    return total_damage
  end,
  meta = function(gm, c, target)
    local weapon = c.equipment:get("weapon")
    target = gm:getCharacter(target)
    return {
      cost = weapon:getCost(gm, c, target) * rengiri_cost_mod,
      damage = {
        max = math.max(0, weapon:maxDamage(gm, c, target) + rengiri_dmg_mod) * rengiri_atk_num,
        min = math.max(0, weapon:minDamage(gm, c, target) + rengiri_dmg_mod) * rengiri_atk_num,
      }
    }
  end
}

-- Daikyougeki

local daikyougeki_atk_mod  = 5
local daikyougeki_dmg_mod  = 5
local daikyougeki_cost_mod = 2

actions["daikyougeki"] = {
  async = true,
  cost = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return 0 end
    return weapon:getCost(gm, c, target) * daikyougeki_cost_mod
  end,
  condition = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return false end
    local distance = gm:getCharacterDistance(c, target)
    return weapon.range >= distance
  end,
  body = function(gm, c, target)
    target = gm:getCharacter(target)
    local atk_dir = gm:getAttackDirection(c, target)
    local weapon = c.equipment:get("weapon")

    local hit, damage = 0
    local max_damage = weapon:maxDamage(gm, c, target) + daikyougeki_dmg_mod
--[[
    c:push(function()
      if damage / max_damage < 0.25 then
        c:speak({
          ja = "大強撃が効かない！",
          en = "Power attack it's not effective!",
          it = "Attacco poderoso non è efficace!"
        })
      end
    end)
]]
    local function atkmod(atk) atk:setMod("daikyougeki", daikyougeki_atk_mod) end
    local function dmgmod(dmg) dmg:addMod(   "physical", daikyougeki_dmg_mod) end

    c:speak({
      ja = "大強撃！",
      en = "Power attack!",
      it = "Attacco poderoso!"
    })
    c:pushCommand("animation", "daikyougeki", {
      tags = {
        ["hit"] = function()
          c:bubble("urya!", -atk_dir)
          hit, damage = gm:applyRule("physical-attack", c, target, atkmod, dmgmod)
          if hit then
            if damage then
              target:hit(damage, atk_dir)
            else
              c:bubble("no damage", atk_dir)
            end
          else
            c:bubble("miss", atk_dir)
          end
        end
      }})

    c:pushCommand("lookAt", target)
    target:pushCommand("lookAt", c)

    coroutine.yield()
    return damage
  end,
  meta = function(gm, c, target)
    local weapon = c.equipment:get("weapon")
    target = gm:getCharacter(target)
    return {
      cost = weapon:getCost(gm, c, target) * daikyougeki_cost_mod,
      damage = {
        max = weapon:maxDamage(gm, c, target) + daikyougeki_dmg_mod,
        min = weapon:minDamage(gm, c, target) + daikyougeki_dmg_mod,
      }
    }
  end
}

actions["disappear"] = {
  async = true,
  cost = function(gm, c) return 50 end,
  body = function(gm, c)
    c:push(function()
      gm:listen(c, "next-character", function()
        gm:removeCharacter(c)
      end)
    end)
    c:pushCommand("fade")
  end
}

return {
  rules = rules,
  actions = actions
}
