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
  self.data = data

  self.text = {
    start = {
      en = "Start",
      ja = "スタート",
      it = "Inizia"
    },
    back = {
      en = "Back",
      ja = "戻る",
      it = "Esci"
    }
  }

  self:resize()
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

function Scenario:onPush(game, prev)
  self.game = game
end

function Scenario:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end
  local size = math.min(w, h)

  self.margin = size / 20
  local normal_size = size / 15
  local title_size = size / 10

  self.font = {
    normal_size = normal_size,
    normal = summon.AssetLoader.load("font", "ipamp.ttf@"..normal_size),
    title_size = title_size,
    title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size)
  }

  self.vp = vec(w, h)
end

function Scenario:draw()
  local offset = self.font.title_size + self.margin * 2

  sg.setBackgroundColor(20, 20, 20)

  sg.setColor(0, 200, 255)
  self.font.title:apply()
  sg.printf(self.game:getLocalizedString(self.name),
    self.margin, self.margin, self.vp.x - self.margin, "center")

  sg.setColor(200, 200, 200)
  self.font.normal:apply()
  sg.printf(self.game:getLocalizedString(self.description),
    self.margin, offset, self.vp.x - self.margin, "left")

  gui.core.draw()
end

function Scenario:update(dt)
  local width = self.vp.x
  local height = self.vp.y
  local h = self.font.title_size * 1.5
  local w = self.font.title:getWidth(
    self.game:getLocalizedString(self.text.back)) * 1.5

  gui.group{grow = "right", pos = {0, height - h - self.margin}, function()
    self.font.title:apply()
    if gui.Button{
      text = self.game:getLocalizedString(self.text.start), size = {width - w, h}}
      then self:play() end
    if gui.Button{
      text = self.game:getLocalizedString(self.text.back), size = {w, h}}
    then self.game:pop() end
  end}
end

function Scenario:keypressed(key)
  gui.keyboard.pressed(key)
end

function Scenario:mousepressed(x, y, button)
end

return Scenario
