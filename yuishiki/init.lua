--[[Yuishiki AI - 唯識永合]]--

local path = ... .. "."

--[[]] ys = {}

--[[Common]]
--[[]] ys.common = {}
--[[]] ys.common.class         = require (path.."lib.middleclass")
--[[]] ys.common.inspect       = require (path.."lib.inspect")
--[[]] ys.common.ansicolors    = require (path.."lib.ansicolors")
--[[]] ys.common.uti           = require (path.."common.uti")
--[[]] ys.common.PriorityQueue = require (path.."common.priority-queue")
--[[]] ys.common.Stack         = require (path.."common.stack")
--[[]] ys.common.log           = require (path.."common.log")
--[[]] ys.common.ManualTrigger = require (path.."common.manual-trigger")

--[[Shortcuts]]
--[[]] ys.log   = ys.common.log
--[[]] ys.class = ys.common.class

--[[MAS]]--
--[[]] ys.mas = {}
--[[]] ys.mas.Sensor          = require (path.."mas.sensor")
--[[]] ys.mas.Actuator        = require (path.."mas.actuator")
--[[]] ys.mas.EventQueue      = require (path.."mas.event-queue")
--[[]] ys.mas.Event           = require (path.."mas.event")
--[[]] ys.mas.Trigger         = require (path.."mas.trigger")
--[[]] ys.mas.EventDispatcher = require (path.."mas.event-dispatcher")
--[[]] ys.mas.Module          = require (path.."mas.module")
--[[]] ys.mas.Agent           = require (path.."mas.agent")

--[[BDI]]
--[[]] ys.bdi = {}
--[[]] ys.bdi.Belief        = require (path.."bdi.belief")
--[[]] ys.bdi.BeliefBase    = require (path.."bdi.belief-base")
--[[]] ys.bdi.Plan          = require (path.."bdi.plan")
--[[]] ys.bdi.PlanBase      = require (path.."bdi.plan-base")
--[[]] ys.bdi.Goal          = require (path.."bdi.goal")
--[[]] ys.bdi.GoalBase      = require (path.."bdi.goal-base")
--[[]] ys.bdi.Intention     = require (path.."bdi.intention")
--[[]] ys.bdi.IntentionBase = require (path.."bdi.intention-base")
--[[]] ys.bdi.Model         = require (path.."bdi.model")

ys._VERSION = "0.0.1"
ys._DESCRIPTION = "A game-oriented BDI multi agent system."
ys._AUTHOR = "Matteo Bernacchia <kikijikispaccaspecchi@gmail.com>"
ys._COPYRIGHT = "Copyright (c) 2013-2014 Matteo Bernacchia"

return ys