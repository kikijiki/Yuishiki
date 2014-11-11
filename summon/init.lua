--[[SUMMON ENGINE - 鎖門円陣]]--

local module_path = ...

local summon

if not table.unpack then table.unpack = unpack end
if not table.pack then table.pack =
  function(...)
    return { n = select("#", ...), ... }
  end
end

return function (base_path)
  if summon then return summon end

  if not base_path then base_path = module_path end
  base_path = base_path .. "."

  local loader = {}
  loader.load = function(lib, ...)
    return require(base_path..lib)(loader, ...)
  end
  loader.require = function(lib)
    return require(base_path..lib)
  end

  local class = loader.require "middleclass"
  loader.class = class

  summon = {}

  summon.class           = class

  summon.astar           = loader.load "a-star"
  summon.sandbox         = loader.require "sandbox"

  summon.log             = loader.load "log"
  summon.uti             = loader.load "uti"
  summon.Vector          = loader.require "vector"
  summon.Stack           = loader.load "stack"
  summon.PriorityQueue   = loader.load "priority-queue"
  summon.observable      = loader.load "observable"
  summon.EventDispatcher = loader.load "event-dispatcher"
  summon.EventObservable = loader.load "event-observable"

  summon.fs              = loader.require "filesystem"
  summon.AssetLoader     = loader.load "asset-loader"

  summon.graphics        = loader.require "graphics"
  summon.Console         = loader.load "console"
  summon.Camera          = loader.load "camera"
  summon.Texture         = loader.load "texture"
  summon.Font            = loader.load "font"
  summon.Animation       = loader.load "animation"
  summon.SpriteSheet     = loader.load "spritesheet"
  summon.SpriteBatch     = loader.load "spritebatch"
  summon.Sprite          = loader.load "sprite"
  summon.MessageRenderer = loader.load "message-renderer"
  summon.Map             = loader.load "map"

  summon.Commands        = loader.load "commands"
  summon.Action          = loader.load "action"
  summon.Armor           = loader.load "armor"
  summon.Character       = loader.load "character"
  summon.GM              = loader.load "gm"
  summon.Item            = loader.load "item"
  summon.Sensor          = loader.load "sensor"
  summon.Stage           = loader.load "stage"
  summon.Value           = loader.load "value"
  summon.Weapon          = loader.load "weapon"
  summon.World           = loader.load "world"
  summon.Game            = loader.load "game"

  summon.AssetLoader.register("texture",     "textures",   summon.Texture.load,         true)
  summon.AssetLoader.register("spritesheet", "textures",   summon.SpriteSheet.load,     true)
  summon.AssetLoader.register("sprite",      "sprites",    summon.Sprite.load,         false)
  summon.AssetLoader.register("font",        "fonts",      summon.Font.load,            true)
  summon.AssetLoader.register("map",         "maps",       summon.Map.load,            false)
  summon.AssetLoader.register("character",   "characters", summon.AssetLoader.loadRaw, false)
  summon.AssetLoader.register("ruleset",     "rulesets"                                     )
  summon.AssetLoader.register("ai_module",   "ai/modules", summon.AssetLoader.loadRaw, false)
  summon.AssetLoader.register("sensor",      "ai/sensors", summon.Sensor.load,         false)

  summon._VERSION     = "0.0.1"
  summon._DESCRIPTION = "Support game engine."
  summon._AUTHOR      = "Matteo Bernacchia <kikijikispaccaspecchi@gmail.com>"
  summon._COPYRIGHT   = "Copyright (c) 2013-2014 Matteo Bernacchia"

  return summon
end
