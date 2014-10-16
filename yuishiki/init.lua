--[[Yuishiki AI - 唯識永合]]--

local path = ... .. "."
path = ""
ys = {}

ys.class         = require (path.."lib.middleclass")
ys.inspect       = require (path.."lib.inspect")
ys.ansicolors    = require (path.."lib.ansicolors")
ys.uti           = require (path.."uti")
ys.PriorityQueue = require (path.."priority-queue")
ys.Stack         = require (path.."stack")
ys.log           = require (path.."log")
ys.ManualTrigger = require (path.."manual-trigger")
ys.Observable    = require (path.."observable")

ys.Agent         = require (path.."agent")
ys.Event         = require (path.."event")
ys.Sensor        = require (path.."sensor")
ys.Actuator      = require (path.."actuator")

ys.BDIModel      = require (path.."bdi-model")
ys.Belief        = require (path.."belief")
ys.BeliefBase    = require (path.."belief-base")
ys.Plan          = require (path.."plan")
ys.PlanBase      = require (path.."plan-base")
ys.Goal          = require (path.."goal")
ys.GoalBase      = require (path.."goal-base")
ys.Intention     = require (path.."intention")
ys.IntentionBase = require (path.."intention-base")
ys.Trigger       = require (path.."trigger")

ys._VERSION = "0.0.1"
ys._DESCRIPTION = "A game-oriented BDI multi agent system."
ys._AUTHOR = "Matteo Bernacchia <kikijikispaccaspecchi@gmail.com>"
ys._COPYRIGHT = "Copyright (c) 2013-2014 Matteo Bernacchia"

return ys
