local Goal

return function(loader)
  if Goal then return Goal end

  local class = loader.require "middleclass"
  local uti = loader.load "uti"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"

  Goal = class("Goal")

  local goal_class_prefix = "goal_"

  Goal.static.Status = uti.makeEnum("New", "Active", "Succeeded", "Failed")
  Goal.static.FailReason = uti.makeEnum("Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

  function Goal.static.define(name, data)
    local G = class(goal_class_prefix..name, Goal)

    G.static.default = data
    G.static.members = {"name", "creation", "conditions", "limit", "on", "retry", "priority", "describe"}

    G.static.name = name
    G.static.creation = Trigger.fromData(data.creation)
    G.static.conditions = ManualTrigger(data.conditions)
    G.static.limit = data.limit
    G.static.on = ManualTrigger(data.on)
    G.static.retry = data.retry
    G.static.priority = data.priority
    G.static.describe = data.describe

    G.initialize = function(self, agent, parameters)
      Goal.initialize(self, parameters)
      for _,v in pairs(G.members) do self[v] = G[v] end
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

  function Goal:bind(...)
    self.on.setDefaultArguments(...)
    self.conditions.setDefaultArguments(...)
  end

  function Goal:fail(reason)
    self.status = Goal.Status.Failed
    self.failReason = reason or Goal.FailReason.Unknown
    self.on.failure()
  end

  function Goal:succeed(result)
    self.status = Goal.Status.Succeeded
    self.result = result
    self.on.success()
  end

  function Goal:activate()
    self.status = Goal.Status.Active
    self.on.activation()
  end
  
  function Goal:__tostring()
    if self.describe then
      return "[G]("..self.status..") <"..self.name.."> {"..self:describe(self.parameters).."}"
    else
      return "[G]("..self.status..") <"..self.name..">"
    end
  end

  return Goal
end
