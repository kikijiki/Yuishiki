local class = require "lib.middleclass"
local Sensor = class("Sensor")

function Sensor:initialize()
  self.events = {}
end

function Sensor.static.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  local s = Sensor()
  if data.events then s.events = data.events end
  if data.update then s.update = data.update end
  return s
end

function Sensor:link(character, agent)
  self.character = character
  self.agent = agent
  self.belief_base = agent.bdi.belief_base
  self.beliefs = agent.bdi.belief_base.interface
end

function Sensor:onEvent()
end

function Sensor:update(world)
end

function Sensor.getYsType()
  return "sensor"
end

return Sensor
