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

rules["class-fighter"] = function(gm, c)
  local s = c.status
  local level, lbonus = levelUp("fighter", s)

  s.str  :addMod("fighter", lbonus[2])
  s.dex  :addMod("fighter", lbonus[4])
  s.con  :addMod("fighter", lbonus[3])
  s.maxhp:addMod("fighter", 2)
  s.atk  :addMod("fighter", 1)
  s.def  :addMod("fighter", 1)
end

return {
  rules = rules
}
