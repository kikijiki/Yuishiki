local class = require "lib.middleclass"
local uti = require "uti"
local Trigger = require "trigger"

local Goal = class("Goal")

local goal_class_prefix = "goal_"

Goal.static.Status = uti.makeEnum("New", "Active", "Succeeded", "Failed")
Goal.static.FailReason = uti.makeEnum("Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

function Goal.static.define(name, data)
  local G = ys.class(goal_class_prefix..name, ys.bdi.Goal)

  G.static.default = data
  G.static.members = {"name", "creation", "condition", "limit", "on", "retry"}

  G.static.name = name
  G.static.creation = Trigger.fromData(data.creation)
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
  self.past = {history = {}, plans = {}, last = nil}
end

function Goal.getYsType()
  return "goal"
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

return Goal
