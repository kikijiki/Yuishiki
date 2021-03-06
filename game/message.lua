local summon = require "summon"()
local sg = summon.graphics

local Message = summon.class("state.Message")

function Message:initialize(data)
  self.title = data.title
  self.message = data.message
  self.fade = -255
  self.fadeout = 0.2
  self.margin = 100
  self.title_size = 80
  self.description_size = 40

  self.font = {
    description = summon.AssetLoader.load("font", "ipamp.ttf@"..self.description_size),
    title       = summon.AssetLoader.load("font", "ipamp.ttf@"..self.title_size)
  }

  self.continue = {
    en = "Press any key to continue",
    ja = "続けるには, どれかキーを押してください",
    it = "Premi un tasto per continuare",
    jitter = 5
  }
end

function Message:onPush(game, prev)
  self.game = game
end

function Message:onResume()
  self:resize(sg.getDimensions())
end

function Message:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end

  self.w = w
  self.h = h
end

function Message:draw()
  sg.setBackgroundColor(20, 20, 20)
  sg.setColor(200, 200, 200)
  self.font.title:apply()
  sg.print(self.game:getLocalizedString(self.title), self.margin, self.margin)

  self.font.description:apply()
  sg.printf(self.game:getLocalizedString(self.message),
    self.margin, self.margin * 2 + self.title_size, self.w)

  sg.setColor(255, 0, 0)
  local dx = math.random(self.continue.jitter)
  local dy = math.random(self.continue.jitter)
  sg.printf(self.game:getLocalizedString(self.continue),
    60 + dx, self.h - self.description_size - 20 + dy, self.w - 120,
    "center")

  if self.fade then
    sg.setColor(0, 0, 0, math.abs(self.fade))
    sg.rectangle("fill", 0, 0, self.w, self.h)
  end
end

function Message:update(dt)
  if self.fade then
    if self.fade < 0 then
      self.fade = self.fade + 255 / self.fadeout * dt
      if self.fade >= 0 then self.fade = nil end
    else
      self.fade = self.fade + 255 / self.fadeout * dt
      if self.fade > 255 then self.game:pop() end
    end
  end
end

function Message:keypressed(key)
  if not self.fade then self.fade = 0 end
end

function Message:mousepressed(x, y, button)
  if not self.fade then self.fade = 0 end
end

return Message
