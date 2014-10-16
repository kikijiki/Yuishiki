local class = require "lib.middleclass"

local Trigger = require "trigger"
local Event = require "event"

local Plan = class("Plan")
local plan_class_prefix = "plan_"

Plan.static.Status = ys.common.uti.makeEnum("New", "Active", "WaitEvent", "WaitSubgoal", "Succeeded", "Failed")
Plan.static.FailReason = ys.common.uti.makeEnum("Dropped", "BodyFailed", "SubgoalFailed", "ConditionFailed", "Unknown")
Plan.static.Condition = ys.common.uti.makeEnum("Success", "Failure", "Context", "Completion")

function Plan.static.define(name, data)
  local P = ys.class(plan_class_prefix..name, ys.bdi.Plan)

  P.static.default = data
  P.static.members = {
    "name", "body", "meta", "confidence", "triggers", "condition",
    "on", "manage_subgoal_failure", "priority" }

  P.static.name = name
  P.static.body = data.body
  P.static.meta = data.meta or false
  P.static.confidence = data.confidence
  P.static.trigger = Trigger.fromData(data.trigger)
  P.static.condition = ys.common.ManualTrigger(data.condition)
  P.static.on = ys.common.ManualTrigger(data.on)
  P.static.manage_subgoal_failure = data.manage_subgoal_failure or false
  P.static.priority = data.priority or 0

  P.initialize = function(self, agent, parameters)
    Plan.initialize(self, agent, parameters)
    for _,v in pairs(P.members) do self[v] = P[v] end
    self.thread = coroutine.create(self.body)
    self.on.setDefaultArguments(self, agent)
    self.condition.setDefaultArguments(self, agent)
  end

  return P
end

function Plan.static.extend(name)
  return ys.class(plan_class_prefix..name, ys.bdi.Plan)
end

function Plan:initialize(agent, parameters, goal) assert(agent)
  self.parameters = parameters or {}
  self.goal = goal
  self.agent = agent
  self.status = Plan.Status.New
  self.results = {history = {}, last = nil}
end

function Plan.getYsType()
  return "plan"
end

-- TODO: parameter passing
function Plan:step()
  if self.status ~= Plan.Status.Active then return end

  self.on.step()

  local ret = {coroutine.resume(self.thread,
    self.agent.interface,
    self,
    self.parameters,
    self.agent.bdi.belief_base.interface,
    self.agent.actuator.interface)}

  local err = table.remove(ret, 1) == false
  table.insert(self.results.history, ret)
  self.results.last = ret

  --[[5.2]]-- if err then ys.log.w("Error in plan body.", table.unpack(ret)) end
  --[[5.1]] if err then ys.log.w("Error in plan body.", unpack(ret)) end
  return err, ret
end

-- TODO: refactor
function Plan:onEventTriggered(e)
  self.status = Plan.Status.Active
  self.wait.data = e
end

function Plan:waitForTrigger(trigger)
  if not trigger then
    return self:yield()
  else
    self.status = Plan.Status.WaitEvent
    self.wait = { trigger = trigger }
    self:yield()
    local result = self.wait.result
    self.wait = nil
    return result
  end
end

function Plan:waitForEvent(name, parameters)
  if not name then
    return self:yield()
  else
    local trigger = Trigger.Event(name, parameters)
    return self:waitForTrigger(trigger)
  end
end

function Plan:waitForBelief(name, condition, ...)
  if not name then
    return self:yield()
  else
    local trigger = Trigger.Belief(name, condition, ...)
    return self:waitForTrigger(trigger)
  end
end

function Plan:waitForActuator(id)
  if not id then
    return self:yield()
  else
    local trigger = Trigger.Event(Event.EventType.Actuator, {id = id})
    return self:waitForTrigger(trigger)
  end
end

function Plan:pushSubGoal(goal, parameters)
  self.status = Plan.Status.WaitSubgoal
  local goal_instance = self.agent.bdi:pushGoal(goal, parameters, self.intention)

  self:yield()

  if goal_instance.status ~= Goal.Status.Succeeded and not self.manage_subgoal_failure then
    self:fail(Plan.FailReason.SubgoalFailed)
    return
  end

  self.status = Plan.Status.Active
  return goal_instance
end

function Plan:fail(reason)
  if type(reason) == "string" then reason = Plan.FailReason[reason] end
  self.status = Plan.Status.Failed
  self.fail_reason = reason or Plan.FailReason.Unknown
  self.on.failure()
end

function Plan:succeed()
  self.status = Plan.Status.Succeeded
  self.on.success()
end

function Plan:terminated()
  return self.thread == nil or coroutine.status(self.thread) == "dead"
end

function Plan:yield(...) assert(self)
  self.on.yield()
  coroutine.yield(...)
  self.on.resume()
end

return Plan
