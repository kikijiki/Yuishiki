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

rules["class-mage"] = function(gm, c)
  local s = c.status
  local level, lbonus = levelUp("mage", s)

  s.dex  :addMod("mage", lbonus[5])
  s.con  :addMod("mage", lbonus[4])
  s.int  :addMod("mage", lbonus[2])
  s.maxhp:addMod("mage", lbonus[2])
  s.atk  :addMod("mage", lbonus[3])
  s.def  :addMod("mage", lbonus[3])
  s.matk :addMod("mage", 1)
  s.mdef :addMod("mage", lbonus[2])
  s.marm :addMod("mage", lbonus[4])
end

return {
  rules = rules
}
