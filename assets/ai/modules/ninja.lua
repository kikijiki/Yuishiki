local plans = {}

local function shuffle(t)
  local ret = {}
  for i = 1, #t do
    ret[#ret+1] = table.remove(t, math.random(#t))
  end
  return ret
end

plans["attack-using-skills"] = {
  meta = true,
  trigger = { "goal", "inflict-damage" },

  body = function(plan, parameters, beliefs, actuator)
    local goal = parameters.goal
    local target = goal.parameters.target
    local pb = parameters.plan_base
    local plans = parameters.plans

    local target_position = plan:pushSubGoal(
      "know", {belief = {"characters", target, "status.position"}})

    local weapon = beliefs.d.self.equipment:get()["weapon"]
    if not weapon then plan:fail() return end

    plan:pushSubGoal(
      "be-in-character-range", {target = target, range = weapon.range})

    local options = {}
    if actuator.rengiri.available() then
      table.insert(options, {
        plan = "rengiri",
        cost = actuator.rengiri.cost(weapon, target),
        efficiency = pb:getEfficiency("rengiri", goal)
      })
    end

    if actuator.daikyougeki.available() then
      table.insert(options, {
        plan = "daikyougeki",
        cost = actuator.daikyougeki.cost(weapon, target),
        efficiency = pb:getEfficiency("daikyougeki", goal)
      })
    end

    table.insert(options, {
      plan = "physical-attack",
      cost = actuator.attack.cost(weapon, target),
      efficiency = pb:getEfficiency("physical-attack", goal)
    })

    local attacked = false
    options = shuffle(options)
    table.sort(options, function(a, b) return a.efficiency > b.efficiency end)
    local ap = beliefs.d.self.status.ap:get()
    for _, option in pairs(options) do
      if option.cost <= ap then
        plan:pushSubPlan(option.plan, goal.parameters)
        attacked = true
        break
      end
    end

    if not attacked then
      plan:waitForBelief("self.status.ap", "increased")
    end
  end
}

plans["rengiri"] = {
  trigger = { "goal", "inflict-damage" },

  enabled = function(plan, parameters, beliefs, actuator)
    local weapon = beliefs.d.self.equipment:get()["weapon"]
    return weapon and actuator.rengiri.available()
  end,

  body = function(plan, parameters, beliefs, actuator)
    local target = parameters.target

    local dmg = actuator.rengiri(target)

    plan:record(beliefs, dmg or 0, {
      --id = target,
      race = beliefs.get("characters", target, "status.race"),
    })

    local meta = actuator.rengiri.meta(target)
    local match, value = plan.schema:match(beliefs, {
      --id = target,
      race = beliefs.get("characters", target, "status.race")
    })

    if match >= 1
        and value < (meta.damage.max / 2)
        and beliefs.isPositive("ally-count")
        and not beliefs.isTrue("no-cooperation") then
      local history = plan:getHistory(beliefs)
      plan:addGoal("communicate", {
        message = {
          target = nil,
          performative = "inform-plan-result",
          plan = "rengiri",
          result = dmg or 0,
          entries = history.data,
          text = parameters.text or {
            ja = "連斬りは効かない！",
            en = "Slashing flurry won't work!",
            it = "L'attacco raffica non funziona!"
          }
        }
      })
    end

    plan:yield()
  end,

  efficiency = function(plan, parameters, beliefs, actuator)
    local target = parameters.target
    local match, value = plan:match(beliefs, {
      --id = target,
      race = beliefs.get("characters", target, "status.race")
    })
    local meta = actuator.rengiri.meta(target)
    local dmg = match * value + (1 - match) * meta.damage.max
    local cost = actuator.rengiri.cost(weapon, target)
    return dmg / cost
  end
}

plans["daikyougeki"] = {
  trigger = { "goal", "inflict-damage" },

  enabled = function(plan, parameters, beliefs, actuator)
    local weapon = beliefs.d.self.equipment:get()["weapon"]
    return weapon and actuator.daikyougeki.available()
  end,

  body = function(plan, parameters, beliefs, actuator)
    local target = parameters.target

    local dmg = actuator.daikyougeki(target)

    plan:record(beliefs, dmg or 0, {
      --id = target,
      race = beliefs.get("characters", target, "status.race"),
    }, 10)

    plan:yield()
  end,

  efficiency = function(plan, parameters, beliefs, actuator)
    local target = parameters.target
    local match, value = plan:match(beliefs, {
      --id = target,
      race = beliefs.get("characters", target, "status.race")
    })
    local meta = actuator.daikyougeki.meta(target)
    local dmg = match * value + (1 - match) * meta.damage.max
    local cost = actuator.daikyougeki.cost(weapon, target)
    return dmg / cost
  end
}

plans["disappear"] = {
  trigger = { "goal", "flee" },

  enabled = function(plan, parameters, beliefs, actuator)
    return actuator.disappear.available()
  end,

  body = function(plan, parameters, beliefs, actuator)
    local cost = actuator.disappear.cost()

    if beliefs.d.self.status.ap:get() < cost then
      plan:waitForBelief("self.status.ap", "at-least", cost)
    end

    actuator.disappear()
  end
}

return {
  plans = plans
}
