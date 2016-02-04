local plans = {}

plans["defeat-all-enemies-safely"] = {
  meta = true,
  trigger = { "goal", "defeat-all-enemies" },

  body = function(plan, parameters, beliefs, actuator)
    local allies = beliefs.get("ally-count")
    local enemies = beliefs.get("enemy-count")

    if allies < enemies then
      plan:addGoal("flee")
    else
      plan:addGoal("avoid-enemies")
    end
    plan:pushSubPlan("give-fight-all-order", {text = {
        ja = "食い止めろ！",
        en = "Stop them!",
        it = "Fermateli!"
      }
    })
  end
}

plans["flee-if-alone"] = {
  trigger = { "belief", "ally-count", { condition = "zero" }},
  body = function(plan, parameters, beliefs, actuator)
    actuator.speak({ text = {
      en = "You useless weaklings!",
      ja = "この役立たずどもめ！",
      it = "Che inutili smidollati!"
    }})
    plan:pushSubGoal("flee");
  end
}

return {
  plans = plans
}
