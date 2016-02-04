local goals = {}

goals["defeat-all-enemies"] = {}

local plans = {}

plans["give-fight-all-order"] = {
  body = function(plan, parameters, beliefs, actuator)
    local goals = {}
    local characters = beliefs.d.characters
    for id, char in pairs(characters) do
      if char.faction:get() == "enemy" then
        table.insert(goals, {
          name = "defeat-character",
          parameters = {target = id}
        })
      end
    end

    if #goals == 0 then return end
    plan:pushSubGoal("communicate", {
      message = {
        target = nil,
        performative = "request",
        goals = goals,
        text = parameters.text or {
          ja = "敵を倒せ！",
          en = "Attack!",
          it = "Attaccate!"
        }
      }
    })
  end
}

plans["give-flee-order"] = {
  body = function(plan, parameters, beliefs, actuator)
    local goals = {}
    local characters = beliefs.d.characters

    plan:pushSubGoal("communicate", {
      message = {
        target = nil,
        performative = "request",
        goal = "flee",
        text = {
          ja = "逃げろ！",
          en = "Retreat!",
          it = "Ritirata!"
        }
      }
    })
  end
}

return {
  goals = goals,
  plans = plans
}
