local summon = require "summon"()
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

  self.text = {
    start = {
      en = "Start",
      ja = "スタート"
    },
    back = {
      en = "Back",
      ja = "戻る"
    }
  }

end

function Scenario:onResume()
  self:resize(sg.getDimensions())
  gui.keyboard.clearFocus()
end

function Scenario:play()
  self.game:pop()
  local phases = self.data.phases
  local next_battle_phase
  for i = #phases, 1, -1 do
    local data = phases[i]

    if data[1] == "message" then
      self.game:push(Message(data))
    else
      local phase = Phase(data)

      if next_battle_phase then
        phase.next_phase = next_battle_phase
      end

      self.game:push(phase)
      next_battle_phase = phase
    end
  end
end

function Scenario:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end

  self.vp = vec(w, h)
end

function Scenario:draw()
  local locale = self.game.locale

  sg.setBackgroundColor(20, 20, 20)

  sg.setColor(0, 200, 255)
  self.font.title:apply()
  sg.printf(self.name[locale], 60, 60, self.vp.x - 60, "center")

  sg.setColor(200, 200, 200)
  self.font.normal:apply()
  sg.printf(self.description[locale], 60, 250, self.vp.x - 60, "left")

  gui.core.draw()
end

function Scenario:update(dt)
  local locale = self.game.locale

  local width = self.vp.x
  local height = self.vp.y

  self.font.normal:apply()
  gui.group{grow = "right", pos = {0, height - 160}, function()
    if gui.Button{
      text = self.text.start[locale], size = {width - 200, 100}} then self:play() end
    if gui.Button{
      text = self.text.back[locale], size = {200, 100}} then self.game:pop() end
  end}
end

function Scenario:keypressed(key)
  gui.keyboard.pressed(key)
end

function Scenario:mousepressed(x, y, button)
end

return Scenario
