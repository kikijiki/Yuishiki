local rules = {}

rules["race-human"] = function(gm, c)
  local s = c.status
  s.race:set("human")
  s.str:set(1)
  s.dex:set(2)
  s.con:set(1)
  s.int:set(3)
  s.maxhp:set(10)
  s.spd:set(5)
  s.mov:set(25)

  c:addAction("speak")
end

local actions = {}

actions["speak"] = {
  body = function(gm, c, message)
    local world = gm.world
    c:speak(message.text, message.duration or 4)
    message.sender = c.id
    world:propagateEvent(c, {"character", "speech"}, message)
  end
}

return {
  rules = rules,
  actions = actions
}
