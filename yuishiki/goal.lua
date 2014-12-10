local Goal

return function(loader)
  if Goal then return Goal end

  local uti = loader.load "uti"
  local log = loader.load "log"
  local Trigger = loader.load "trigger"
  local ManualTrigger = loader.load "manual-trigger"

  Goal = loader.class("Goal")

  Goal.static.Status = uti.makeEnum(
    "New", "Active", "Succeeded", "Failed", "WaitingAvailability")
  Goal.static.FailReason = uti.makeEnum(
    "Dropped", "PlanFailed", "NoPlansAvailable", "ConditionFailed", "unknown")

  function Goal.static.define(name, data)
    local GoalClass = loader.class("G-"..name, Goal)
    GoalClass.static.name = name
    GoalClass.static.data = data

    GoalClass.initialize = function(self, ...)
      Goal.initialize(self, ...)
      self.name = name
      self.on = ManualTrigger(data.on)
      self.conditions = ManualTrigger(data.conditions)
      self.retry = data.retry
    end

    if data.trigger then
      GoalClass.trigger = Trigger.fromData(table.unpack(data.trigger))
    end
    GoalClass.limit = data.limit
    GoalClass.priority = data.priority
    GoalClass.describe = data.describe
    GoalClass.log = log.tag ("G-"..name)

    return GoalClass
  end

  function Goal:initialize(parameters)
    self.parameters = parameters
    self.past = {history = {}, plans = {}, length = 0, last = nil}
  end

  function Goal.getYsType()
    return "goal"
  end

  function Goal:bind(...)
    self.exported = {...}
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
    if self.status ~= Goal.Status.Active then
      self.status = Goal.Status.Active
      self.on.activation()
    end
  end

  function Goal:prepare()
    self.status = Goal.Status.WaitingAvailability
  end

  function Goal:wait()
  end

  function Goal:__tostring()
    if self.describe then
      return string.format("[G](%s) <%s> {%s}",
        self.status, self.name, self:describe(self.parameters))
    else
      return string.format("[G](%s) <%s>", self.status, self.name)
    end
  end

  function Goal:getPriority()
    local priority = self.priority
    if not priority then priority = 0 end

    if type(priority) == "function" then
      priority = priority(table.unpack(self.exported))
    end

    priority = priority - self.past.length --penalize failed goals priority
    return priority
  end

  return Goal
end
