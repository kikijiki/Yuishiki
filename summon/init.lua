--[[SUMMON ENGINE - 鎖門円陣]]--

local path = ... .. "."

summon = {}

--[[Core and common]]--
--[[]] summon.common = {}

--[[]] summon.common.Vector        = require (path.."common.vector")
--[[]] summon.common.log           = require (path.."common.log")
--[[]] summon.common.class         = require (path.."lib.middleclass")
--[[]] summon.common.astar         = require (path.."lib.a-star")

--[[Shortcuts]]
--[[]] summon.vec   = summon.common.Vector
--[[]] summon.log   = summon.common.log
--[[]] summon.class = summon.common.class

--[[]] summon.common.inspect       = require (path.."lib.inspect")
--[[]] summon.common.sandbox       = require (path.."lib.sandbox")
--[[]] summon.common.uti           = require (path.."common.uti")
--[[]] summon.common.Stack         = require (path.."common.stack")
--[[]] summon.common.PriorityQueue = require (path.."common.priority-queue")
--[[]] summon.uti = summon.common.uti

--[[]] summon.common.AssetLoader   = require (path.."common.asset-loader")
--[[]] summon.AssetLoader = summon.common.AssetLoader

--[[Graphics]]--
--[[]] summon.graphics = love.graphics
--[[]]
--[[]] summon.graphics.Camera  = require (path.."graphics.camera")
--[[]] summon.graphics.Texture = require (path.."graphics.texture")
--[[]] summon.graphics.Font    = require (path.."graphics.font")

--[[Filesystem]]--
--[[]] summon.fs = love.filesystem

--[[Sprite]]--
--[[]] summon.graphics.sprite = {}
--[[]] summon.graphics.sprite.Animation   = require (path.."graphics.animation")
--[[]] summon.graphics.sprite.SpriteSheet = require (path.."graphics.spritesheet")
--[[]] summon.graphics.sprite.SpriteBatch = require (path.."graphics.spritebatch")
--[[]]
--[[]] summon.graphics.Sprite             = require (path.."graphics.sprite")
--[[]] summon.graphics.SpriteBatch        = summon.graphics.sprite.SpriteBatch
--[[]] summon.graphics.MessageRenderer    = require (path.."graphics.message-renderer")

--[[Map]]--
--[[]] summon.graphics.Map = require (path.."graphics.map")

--[[Game]]--
--[[]] summon.game = {}
--[[]] summon.game.Ruleset        = require (path.."game.ruleset")
--[[]] summon.game.Entity         = require (path.."game.entity")
--[[]] summon.game.Unit           = require (path.."game.unit")
--[[]] summon.game.World          = require (path.."game.world")
--[[]] summon.game.WorldInterface = require (path.."game.world-interface")
--[[]] summon.game.Parameter      = require (path.."game.parameter")
--[[]] summon.game.RuleHandler    = require (path.."game.rule-handler")
--[[]] summon.game.Command        = require (path.."game.command")
--[[]]
--[[]] summon.Game = require (path.."game.game")

--[[Supported assets]]--
--[[]] summon.AssetLoader.register("texture",     "textures", summon.graphics.Texture.load,            true)
--[[]] summon.AssetLoader.register("spritesheet", "textures", summon.graphics.sprite.SpriteSheet.load, true)
--[[]] summon.AssetLoader.register("sprite",      "sprites",  summon.graphics.Sprite.load,             false)
--[[]] summon.AssetLoader.register("font",        "fonts",    summon.graphics.Font.load,               true)
--[[]] summon.AssetLoader.register("map",         "maps",     summon.graphics.Map.load,                false)
--[[]] summon.AssetLoader.register("ruleset",     "rulesets", summon.game.Ruleset.load,                false)
--[[]] summon.AssetLoader.register("unit",        "units",    summon.game.Unit.load,                   false)

return summon
