assert(ys, "Yuishiki is not loaded.")

local Goal = ys.common.class("BDI_Goal")
local goal_class_prefix = "goal_"
local Trigger = ys.mas.Trigger

Goal.static.Status = ys.common.uti.makeEnum("New", "Active", "Succeeded", "Failed")
Goal.static.FailReason = ys.common.uti.makeEnum("Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

function Goal.static.define(name, data)
  local G = ys.class(goal_class_prefix..name, ys.bdi.Goal)
  
  G.static.default = data
  G.static.members = {"name", "trigger", "condition", "limit", "on", "retry"}
  G.static.name = name
  G.static.trigger = Trigger.fromData(data.trigger)
  G.static.condition = ys.common.ManualTrigger(data.condition)
  G.static.limit = data.limit
  G.static.on = ys.common.ManualTrigger(data.on)
  G.static.retry = data.retry
  
  G.initialize = function(self, agent, parameters)
    Goal.initialize(self, parameters)
    for _,v in pairs(G.members) do self[v] = G[v] end
    self.on.setDefaultArguments(self, agent)
    self.condition.setDefaultArguments(self, agent)
  end
  
  return G
end

function Goal.static.extend(name)
  return ys.class(goal_class_prefix..name, ys.bdi.Goal)
end

function Goal:initialize(parameters)
  self.parameters = parameters
  self.plans = {history = {}, last = nil}
end

function Goal:fail(reason, plan)
  self.status = Goal.Status.Failed
  self.failReason = reason or Goal.FailReason.Unknown
  self.on.failure()
end

function Goal:succeed()
  self.status = Goal.Status.Succeeded
  self.on.success()
end

function Goal:activate()
  self.status = Goal.Status.Active
  self.on.activation()
end

function Goal.getYsType()
  return "goal"
end

return Goal