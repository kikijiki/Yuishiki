return function(loader)
  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"

  local Goal = class("Goal")

  local goal_class_prefix = "goal_"

  Goal.static.Status = uti.makeEnum("New", "Active", "Succeeded", "Failed")
  Goal.static.FailReason = uti.makeEnum("Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

  function Goal.static.define(name, data)
    local G = class(goal_class_prefix..name, Goal)

    G.static.default = data
    G.static.members = {"name", "creation", "condition", "limit", "on", "retry"}

    G.static.name = name
    G.static.creation = Trigger.fromData(data.creation)
    G.static.condition = ManualTrigger(data.condition)
    G.static.limit = data.limit
    G.static.on = ManualTrigger(data.on)
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
    return class(goal_class_prefix..name, Goal)
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
end
