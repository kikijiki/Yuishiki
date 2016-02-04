local rules = {}

rules["race-oni"] = function(gm, c)
  local s = c.status
  s.race:set("oni")
  s.str:set(3)
  s.dex:set(1)
  s.con:set(3)
  s.int:set(0)
  s.maxhp:set(30)
  s.spd:set(1)
  s.mov:set(30)
  s.def:set(6)
  s.arm:set(2)
end

return {
  rules = rules
}
