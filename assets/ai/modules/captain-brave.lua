local plans = {}

plans["defeat-all-enemies-together"] = {
  meta = true,
  trigger = { "goal", "defeat-all-enemies" },

  body = function(plan, parameters, beliefs, actuator)
    local allies = beliefs.get("ally-count")
    local enemies = beliefs.get("enemy-count")

    if allies < enemies then -- Flee with the others.
      plan:addGoal("flee")
      plan:pushSubPlan("give-flee-order")
    else                     -- Attack with the others.
      for id,char in pairs(beliefs.d.characters) do
        if char.faction:get() == "enemy" then
          plan:addGoal("defeat-character", {target = id})
        end
      end
      plan:pushSubPlan("give-fight-all-order", {text =
        {
          ja = "突撃！",
          en = "Charge!",
          it = "Caricate!"
        }
      })
    end
  end
}

return {
  plans = plans
}
