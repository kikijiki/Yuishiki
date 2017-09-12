--[[Yuishiki AI - 唯識永合]]--

local module_path = ...

local ys

if not table.unpack then table.unpack = unpack end

return function (base_path)
  if ys then return ys end

  if not base_path then base_path = module_path end
  base_path = base_path .. "."

  local loader = {}
  loader.load = function(lib, ...)
    return require(base_path..lib)(loader, ...)
  end
  loader.require = function(lib)
    return require(base_path..lib)
  end
  loader.class = loader.require "middleclass"

  ys = {}

  ys.log   = loader.load "log"
  ys.Agent = loader.load "agent"

  ys._VERSION = "0.4.0"
  ys._DESCRIPTION = "A game-oriented BDI multi agent system."
  ys._AUTHOR = "Matteo Bernacchia <makikijiki@gmail.com>"
  ys._COPYRIGHT = "Copyright (c) 2013-2014 Matteo Bernacchia"

  return ys
end
