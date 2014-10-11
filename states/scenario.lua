local Scenario = summon.class("Scenario")

local summon = require "summon"
local Gamestate = require "lib.hump.gamestate"
local Character = require "character"
local Stage = require "stage"
local Phase = require "states.phase"
local Message = require "states.message"
local gui = require "lib.quickie"

local vec = summon.vec
local sg = summon.graphics

local font = {
  normal = summon.AssetLoader.load("font", "ipamp.ttf@60"),
  title = summon.AssetLoader.load("font", "ipamp.ttf@120")
}

function Scenario:initialize(data)
  assert(data)
  assert(data.characters, "Character data missing from scenario.")
  assert(data.phases, "Phase data missing from scenario.")

  self.name = data.name
  self.description = data.description
  self.vp = vec(sg.getDimensions())
  self.data = data
end

function Scenario:play()
  local characters = {}
  for id,char in pairs(self.data.characters) do
    characters[id] = summon.AssetLoader.load("character", char, false, id)
  end

  local phases = self.data.phases
  for phase = #phases, 1, -1 do
    local data = phases[phase]
    if data[1] == "message" then Gamestate.push(Message(data))
    else Gamestate.push(Phase(data, characters)) end
  end
end

function Scenario:resize(w, h)
  self.vp = vec(w, h)
end

function Scenario:draw()
  sg.setBackgroundColor(20, 20, 20)

  sg.setColor(0, 200, 255)
  font.title:apply()
  sg.printf(self.name, 60, 60, self.vp.x - 60, "center")
  sg.setColor(200, 200, 200)
  font.normal:apply()
  sg.printf(self.description, 60, 200, self.vp.x - 60, "left")

  gui.core.draw()
end

function Scenario:update(dt)
  local width = self.vp.x
  local height = self.vp.y

  font.normal:apply()
  gui.group{grow = "right", pos = {0, height - 160}, function()
    if gui.Button{text = "START", size = {width - 200, 100}} then self:play() end
    if gui.Button{text = "Back", size = {200, 100}} then Gamestate.pop() end
  end}
end

function Scenario:keypressed(key)
end

function Scenario:mousepressed(x, y, button)
end

return Scenario
