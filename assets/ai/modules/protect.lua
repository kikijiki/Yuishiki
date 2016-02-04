local goals = {}

goals["protect-character"] = {
  priority = 5,

  conditions = {
    failure = function(goal, parameters, beliefs, actuator)
      return beliefs.isFalse("characters", parameters.target, "alive")
    end
  },

  describe = function(goal, parameters)
    return tostring(parameters.target)
  end
}

goals["avoid-enemies"] = {
  retry = true,
  priority = function(goal, parameters, beliefs, actuator)
    local hp = beliefs.get("self.status.hp")
    local maxhp = beliefs.get("self.status.maxhp")
    return 5 + (1 - hp / maxhp) * 5
  end
}

local plans = {}

plans["send-away-if-hurt"] = {
  trigger = { "goal", "protect-character" },

  body = function(plan, parameters, beliefs, actuator)
    local target = parameters.target

    while true do
      plan:waitForBelief(
        "characters."..target..".status.health",
        "at-most", 0.5)

      plan:pushSubGoal("communicate", {
        message = {
          performative = "request",
          target = target,
          text = {
            ja = "敵から離れろ！",
            en = "Get away!",
            it = "Allontanati!"
          },
          goal = "avoid-enemies",
          parameters = {}
        }
      })

      -- TODO: attack target enemy

      plan:waitForBelief(
        "characters."..target..".status.health",
        "more-than", 0.5)
    end
  end
}

plans["move-away-from-enemies"] = {
  trigger = { "goal", "avoid-enemies" },

  conditions = {
    success = function(plan, parameters, beliefs, actuator)
      local characters = beliefs.d.characters
      for _,c in pairs(characters) do
        if c.faction:get() == "enemy" and c.alive:get() then return false end
      end
      return true
    end
  },

  body = function(plan, parameters, beliefs, actuator)
    local characters = beliefs.d.characters
    local range = parameters.range or 4
--[[
    ib = plan.bdi.intention_base
    for id,intention in pairs(ib.intentions) do
      if intention ~= plan.intention then
        ib:drop(intention)
      end
    end
]]
    while(true) do
      local nearest

      for _,c in pairs(characters) do
        if c.status and c.status.position and c.status.position:get() then
          local position = c.status.position:get()
          local distance = actuator.getDistance(position)

          if c.faction:get() == "enemy" and distance < range then
            if not nearest or nearest.distance > distance then
              nearest = {
                position = position,
                distance = distance
              }
            end
          end
        end
      end

      if nearest then
        local destination = actuator.getFarthest(nearest.position, true)
        plan:pushSubGoal("be-in-location", {destination = destination})
      else
        plan:waitForEvent("game", "turn-end")
      end
    end
  end
}

return {
  goals = goals,
  plans = plans
}
