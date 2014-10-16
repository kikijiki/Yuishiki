--[[Yuishiki AI - 唯識永合]]--

return function (base_path)

  local loader = {}
  loader.load = function(lib, ...)
    return require(base_path.."."..lib)(loader, ...)
  end
  loader.require = function(lib)
    return require(base_path.."."..lib)
  end

  ys = {}

  ys.uti           = loader.load ("uti")
  ys.PriorityQueue = loader.load ("priority-queue")
  ys.Stack         = loader.load ("stack")
  ys.log           = loader.load ("log")
  ys.ManualTrigger = loader.load ("manual-trigger")
  ys.Observable    = loader.load ("observable")

  ys.Agent         = loader.load ("agent")
  ys.Event         = loader.load ("event")
  ys.Sensor        = loader.load ("sensor")
  ys.Actuator      = loader.load ("actuator")

  ys.BDIModel      = loader.load ("bdi-model")
  ys.Belief        = loader.load ("belief")
  ys.BeliefBase    = loader.load ("belief-base")
  ys.Plan          = loader.load ("plan")
  ys.PlanBase      = loader.load ("plan-base")
  ys.Goal          = loader.load ("goal")
  ys.GoalBase      = loader.load ("goal-base")
  ys.Intention     = loader.load ("intention")
  ys.IntentionBase = loader.load ("intention-base")
  ys.Trigger       = loader.load ("trigger")

  ys._VERSION = "0.0.1"
  ys._DESCRIPTION = "A game-oriented BDI multi agent system."
  ys._AUTHOR = "Matteo Bernacchia <kikijikispaccaspecchi@gmail.com>"
  ys._COPYRIGHT = "Copyright (c) 2013-2014 Matteo Bernacchia"

  return ys
end
