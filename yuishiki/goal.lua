local Goal

return function(loader)
  if Goal then return Goal end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"

  Goal = loader.class("Goal")

  Goal.static.Status = uti.makeEnum("New", "Active", "Succeeded", "Failed")
  Goal.static.FailReason = uti.makeEnum("Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

  function Goal.static.define(name, data)
    local GoalClass = loader.class("G "..name, Goal)
    GoalClass.static.name = name
    GoalClass.static.default = data

    GoalClass.initialize = function(self, ...)
      Goal.initialize(self, ...)
      self.name = name
    end

    GoalClass.creation = Trigger.fromData(table.unpack(data.creation or {}))
    GoalClass.conditions = ManualTrigger(data.conditions)
    GoalClass.limit = data.limit
    GoalClass.on = ManualTrigger(data.on)
    GoalClass.retry = data.retry
    GoalClass.priority = data.priority
    GoalClass.describe = data.describe
    GoalClass.log = log.tag ("G "..name)

    return GoalClass
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
