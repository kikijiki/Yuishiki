local summon = require "summon"()
local Character = summon.Character
local Stage = summon.Stage
local Phase = require "game.phase"
local Message = require "game.message"
local gui = require "lib.quickie"

local vec = summon.Vector
local sg = summon.graphics

local Scenario = summon.class("Scenario")

function Scenario:initialize(data)
  assert(data)
  assert(data.phases, "Phase data missing from scenario.")

  self.name = data.name
  self.description = data.description
  self.vp = vec(sg.getDimensions())
  self.data = data
  self.font = {
    normal = summon.AssetLoader.load("font", "ipamp.ttf@60"),
    title = summon.AssetLoader.load("font", "ipamp.ttf@120")
  }

end

function Scenario:onResume()
  self:resize(sg.getDimensions())
  gui.keyboard.clearFocus()
end

function Scenario:play()
  local phases = self.data.phases
  for phase = #phases, 1, -1 do
    local data = phases[phase]
    if data[1] == "message" then self.game:push(Message(data))
    else self.game:push(Phase(data, characters)) end
  end
end

function Scenario:resize(w, h)
  self.vp = vec(w, h)
end

function Scenario:draw()
  sg.setBackgroundColor(20, 20, 20)

  sg.setColor(0, 200, 255)
  self.font.title:apply()
  sg.printf(self.name, 60, 60, self.vp.x - 60, "center")
  sg.setColor(200, 200, 200)
  self.font.normal:apply()
  sg.printf(self.description, 60, 200, self.vp.x - 60, "left")

  gui.core.draw()
end

function Scenario:update(dt)
  local width = self.vp.x
  local height = self.vp.y

  self.font.normal:apply()
  gui.group{grow = "right", pos = {0, height - 160}, function()
    if gui.Button{
      text = "START", size = {width - 200, 100}} then self:play() end
    if gui.Button{
      text = "Back", size = {200, 100}} then self.game:pop() end
  end}
end

function Scenario:keypressed(key)
  gui.keyboard.pressed(key)
end

function Scenario:mousepressed(x, y, button)
end

return Scenario
