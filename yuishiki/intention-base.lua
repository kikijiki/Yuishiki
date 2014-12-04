local IntentionBase

return function(loader)
  if IntentionBase then return IntentionBase end

  local log = loader.load "log"
  local Plan = loader.load "plan"
  local Observable = loader.load "observable"

  IntentionBase = loader.class("IntentionBase", Observable)

  function IntentionBase:initialize(agent) assert(agent)
    Observable.initialize(self)

    self.agent = agent
    self.intentions = {}
    self.log = log.tag("IB")
  end

  function IntentionBase:add(intention)
    self.intentions[intention.id] = intention
    intention.agent = self.agent
  end

  function IntentionBase:drop(intention)
    self.log.i("Dropping intention", intention)
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

  function IntentionBase:execute(intention)
    if self.verbose then self:dump() end
    intention:step()
    if intention:isEmpty() then self:drop(intention) end
  end

  function IntentionBase:allWaiting()
    for _,intention in pairs(self.intentions) do
      if not intention:waiting() then return false end
    end

    return true
  end

  function IntentionBase:dump()
    if not next(self.intentions) then
      self.log.i("--[[INTENTION BASE EMPTY]]--")
      return
    end
    self.log.i("--[[INTENTION BASE DUMP START]]--")
    self.log.i()
    for _,intention in pairs(self.intentions) do
      self.log.fi("%s / %d", intention, intention:getPriority())
      local i = 1
      for _,element in pairs(intention.stack.elements) do
        local indent = string.rep("-", i)
        self.log.fi("%s %s", indent, tostring(element))
        i = i + 1
      end
    end
    self.log.i()
    self.log.i("--[[INTENTION BASE DUMP END]]--")
  end

  function IntentionBase:isEmpty()
    return #self.intentions == 0
  end

  return IntentionBase
end
