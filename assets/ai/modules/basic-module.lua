local beliefs = {}

beliefs["test.number"] = 100

local goals = {}

goals["know"] = {
  conditions = {
    success = function(goal, parameters, beliefs, actuator)
      return beliefs.isDefined(parameters.belief)
    end
  },

  on = {
    success = function(goal, parameters, beliefs, actuator)
      goal.result = beliefs.get(parameters.belief)
    end
  },

  describe = function(goal, parameters)
    return tostring(parameters.belief)
  end
}

goals["be-in-location"] = {
  describe = function(goal, parameters)
    return tostring(parameters.destination)
  end
}

goals["be-in-character-range"] = {
  describe = function(goal, parameters)
    return string.format("%s, range=%d", parameters.target, parameters.range)
  end
}

goals["defeat-character"] = {
  retry = true,
  conditions = {
    success = function(goal, parameters, beliefs, actuator)
      return beliefs.isFalse("characters", parameters.target, "alive")
    end,
    context = function(goal, parameters, beliefs, actuator)
      return beliefs.isDefined("characters", parameters.target, "status.position")
    end
  },

  limit = 1,

  priority = function(goal, parameters, beliefs, actuator)
    local target = parameters.target

    local target_position = beliefs.get("characters", target, "status.position")
    local distance = 100
    if target_position then distance = actuator.getDistance(target_position) end

    local health = beliefs.get("characters", target, "status.health") or 1

    local weapon = beliefs.d.self.equipment:get()["weapon"]
    local range = 0
    if weapon then range = weapon.range end

    local c_distance = math.min(1, math.max(0, (10 + range - distance) / 10))
    local c_health   = 1 - health
    local c_base     = 1
    return c_base + c_health + c_distance * 2
  end,

  describe = function(goal, parameters)
    return tostring(parameters.target)
  end
}

goals["inflict-damage"] = {
  describe = function(goal, parameters)
    return parameters.target
  end
}

goals["flee"] = {
  priority = 10
}

local plans = {}

plans["walk-to-location"] = {
  trigger = { "goal", "be-in-location" },

  conditions = {
    success = function(plan, parameters, beliefs, actuator)
      return beliefs.isEqual(parameters.destination, "self.status.position")
    end
  },

  body = function(plan, parameters, beliefs, actuator)
    local destination = parameters.destination

    while(true) do
      local path, full_path, cost, step_cost = actuator.getPathTo(destination, true)

      if path and #path > 0 then -- there is a path walkable with current AP left
        actuator.move(path)
        plan:yield()
      else
        if full_path and #full_path > 0 then -- path was found but current AP wasn't enough
          plan:waitForBelief("self.status.ap", "at-least", step_cost)
          else -- there was no path to the destination
            plan:fail()
            return
          end
        end
    end
  end
}

plans["walk-in-character-range"] = {
  trigger = { "goal", "be-in-character-range" },

  conditions = {
    success = function(plan, parameters, beliefs, actuator)
      local position =
        beliefs.get("characters", parameters.target, "status.position")
      if not position then return false
      else return actuator.isInRange(position, parameters.range) end
    end
  },

  body = function(plan, parameters, beliefs, actuator)
    local target = parameters.target
    local range = parameters.range

    while(true) do
      local target_position = plan:pushSubGoal(
        "know", {belief = "characters."..target..".status.position"})

      local destination =
        actuator.getClosestInRange(target_position, range, true, true)

      if not destination then plan:fail() return end
      local path, full_path, cost, step_cost = actuator.getPathTo(destination, true)

      if path and #path > 0 then -- there is a path walkable with current AP left
        actuator.move(path)
        plan:yield()
      else
        if full_path and #full_path > 0 then -- path was found but current AP wasn't enough
          plan:waitForBelief("self.status.ap", "at-least", step_cost)
        else -- there was no path to the destination
          plan:fail()
          return
        end
      end
    end
  end
}

plans["empty-target-hp"] = {
  trigger = { "goal", "defeat-character" },

  conditions = {
    success = function(plan, parameters, beliefs, actuator)
      return beliefs.isLessEqual(0,
        "characters", parameters.target, "status.health")
    end
  },

  body = function(plan, parameters, beliefs, actuator)
    while true do
      plan:pushSubGoal("inflict-damage", parameters)
    end
  end
}

plans["physical-attack"] = {
  trigger = { "goal", "inflict-damage" },

  enabled = function(plan, parameters, beliefs, actuator)
    local weapon = beliefs.d.self.equipment:get()["weapon"]
    return weapon and actuator.attack.available()
  end,

  body = function(plan, parameters, beliefs, actuator)
    local target = parameters.target
    local target_position = plan:pushSubGoal(
      "know", {belief = {"characters", target, "status.position"}})

    local weapon = beliefs.d.self.equipment:get()["weapon"]
    if not weapon then plan:fail() return end

    plan:pushSubGoal(
      "be-in-character-range", {target = target, range = weapon.range})

    local cost = actuator.attack.cost(weapon, target)


    if beliefs.isLess(cost, "self.status.ap") then
      plan:waitForBelief("self.status.ap", "at-least", cost)
    end

    local dmg = actuator.attack(target)

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
    local meta = actuator.attack.meta(target)
    local dmg = match * value + (1 - match) * meta.damage.max
    local cost = actuator.attack.cost(weapon, target)
    return dmg / cost
  end
}

return {
  beliefs = beliefs,
  goals = goals,
  plans = plans
}
