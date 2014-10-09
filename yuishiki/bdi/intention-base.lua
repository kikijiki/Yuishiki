local IntentionBase = ys.common.class("BDI_IntentionBase")

local Plan = ys.bdi.Plan

function IntentionBase:initialize(agent) assert(agent)
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
    if top.getYsType() == "plan" and top.status == Plan.Status.WaitEvent then   ys.log.i("WAITINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG")
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

function IntentionBase:execute(intention)
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
  for _,intention in pairs(self.intentions) do
    ys.log.i(intention.id)
    for _,element in pairs(intention.stack.elements) do
      ys.log.i(" - "..element.name.." ["..element.status.."]")
    end
  end
end

return IntentionBase
