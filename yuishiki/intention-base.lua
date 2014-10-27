local IntentionBase

return function(loader)
  if IntentionBase then return IntentionBase end

  local class = loader.require "middleclass"
  local log = loader.load "log"
  local Plan = loader.load "plan"
  local Observable = loader.load "observable"

  IntentionBase = class("IntentionBase", Observable)

  function IntentionBase:initialize(agent) assert(agent)
    Observable.initialize(self)

    self.agent = agent
    self.intentions = {}
  end

  function IntentionBase:add(intention)
    self.intentions[intention.id] = intention
    intention.agent = self.agent
  end

  function IntentionBase:drop(intention)
    if type(intention) == "string" then
      self.intentions[intention] = nil
    else
      self.intentions[intention.id] = nil
    end
  end

  function IntentionBase:onEvent(e)
    for _,intention in pairs(self.intentions) do
      local top = intention:top()
      if not top then return end
      if top.getYsType() == "plan" and top.status == Plan.Status.Waiting then
        local trigger = top.wait.trigger
        if trigger:check(e) then
          top:onEventTriggered(e)
        end
      end
    end
  end

  function IntentionBase:removeIntention(intention)
    self.intentions[intention.id] = nil
  end

  function IntentionBase:execute(intention) self:dump()
    intention:step()
    if intention:empty() then self.intentions[intention.id] = nil end
  end

  function IntentionBase:waiting()
    for _,intention in pairs(self.intentions) do
      if intention:waiting() then return true end
    end

    return false
  end

  function IntentionBase:dump()
    log.i("--[[INTENTION BASE DUMP START]]--")
    
    for _,intention in pairs(self.intentions) do
      log.i(intention)
      local i = 1
      for _,element in pairs(intention.stack.elements) do
        local indent = string.rep("-", i)
        log.fi("%s %s", indent, tostring(element))
        i = i + 1
      end
    end
    
    log.i("--[[INTENTION BASE DUMP END]]--")
  end

  return IntentionBase
end
