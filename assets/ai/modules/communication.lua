local goals = {}

local function getMessageText(msg)
  local text = msg.text
  if type(text) == "table" then
    if text["en"] then return text.en
    else return select(2, next(text)) end
  else
    return text
  end
end

local function replyMessage(t1, t2)
  local locales = {}
  t1 = t1 or {}
  t2 = t2 or {}
  for locale,_ in pairs(t1) do locales[locale] = true end
  for locale,_ in pairs(t2) do locales[locale] = true end

  local out = {}
  for locale,_ in pairs(locales) do
    out[locale] = (t1[locale] or "") .. (t2[locale] or "")
  end

  return out
end

goals["communicate"] = {
  describe = function(goal, parameters)
    local message = parameters.message
    return tostring(message.target or "*all*").." <- '"..getMessageText(message).."'"
  end
}

goals["process-message"] = {
  trigger = { "event", "message" },
  priority = 10,
  describe = function(goal, parameters)
    return getMessageText(parameters.message)
  end
}

local plans = {}

plans["interpret-message"] = {
  meta = true,
  trigger = { "goal", "process-message" },

  body = function(plan, parameters, beliefs, actuator)
    local goal = parameters.goal
    local message = goal.parameters.message

    if message.target and message.target ~= beliefs.get("self.id") then
      return
    end

    if beliefs.get("characters", message.sender, "faction") ~= "ally" then
      return
    end

    if message.performative == "request" then
      plan:pushSubPlan("execute-request", goal.parameters)
    end

    if message.performative == "inform-plan-result" then
      local history = beliefs.get("history.plan", message.plan)
      if not history then
        history = plan.ResultHistory()
        beliefs.setLT(history, "history.plan", message.plan)
      end
      for _,entry in pairs(message.entries) do
        history:record(entry.result, entry.state)
      end
      local reply = {
        ja = "わかった！",
        en = "I see!",
        it = "Ho capito!"
      }
      actuator.speak({text = reply, duration = 0.5})
    end
  end
}

plans["execute-request"] = {
  body = function(plan, parameters, beliefs, actuator)
    local message = parameters.message
    local reply = {
      ja = "はい！",
      en = "Understood!",
      it = "Ricevuto!"
    }
    actuator.speak({text = reply, duration = 1})
    if message.goals then
      for _,goal in pairs(message.goals) do
        plan:addGoal(goal.name, goal.parameters)
      end
    end
    if message.goal then
      plan:pushSubGoal(message.goal, message.parameters)
    end
  end
}

plans["speak"] = {
  trigger = { "goal", "communicate" },

  enabled = function(plan, parameters, beliefs, actuator)
    return actuator.speak.available() and parameters.message
  end,

  body = function(plan, parameters, beliefs, actuator)
    actuator.speak(parameters.message)
  end
}

return {
  goals = goals,
  plans = plans
}
