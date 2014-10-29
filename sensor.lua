local class = require "lib.middleclass"
local Sensor = class("Sensor")

function Sensor:initialize()
  self.events = {}
end

function Sensor.static.load(path)
  local data = summon.AssetLoader.loadRaw(path)
  local s = Sensor()
  if data.triggers then s.triggers = data.triggers end
  if data.update then s.update = data.update end
  return s
end

function Sensor:link(character, agent)
  self.character = character
  self.agent = agent
  self.belief_base = agent.bdi.belief_base
  self.beliefs = agent.bdi.belief_base.interface
end

function Sensor:register(env)
  for _, trigger in pairs(self.triggers) do
    env:addObserver(
      self,
      trigger.event,
      function(...) trigger.body(self, ...) end)
  end
end

function Sensor:update(world)
end

function Sensor.getYsType()
  return "sensor"
end

return Sensor
