local Message = summon.class("state.Message")

local Gamestate = require "lib.hump.gamestate"

local sg = summon.graphics
local fadeout = 0.2

local margin = 100
local title_size = 80
local description_size = 40

local font = {
  description = summon.AssetLoader.load("font", "ipamp.ttf@"..description_size),
  title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size),
}

function Message:initialize(data)
  self.title = data.title
  self.message = data.msg
  self.fade = -255
end

function Message:init()
end

function Message:enter(previous)
end

function Message:leave()
end

function Message:draw()
  sg.setBackgroundColor(20, 20, 20)
  sg.setColor(200, 200, 200)
  font.title:apply()
  sg.print(self.title, margin, margin)
  font.description:apply()
  sg.printf(self.message, margin, margin * 2 + title_size, sg.getWidth())

  if self.fade then
    sg.setColor(0, 0, 0, math.abs(self.fade))
    sg.rectangle("fill", 0, 0, sg.getWidth(), sg.getHeight())
  end
end

function Message:update(dt)
  if self.fade then
    if self.fade < 0 then
      self.fade = self.fade + 255 / fadeout * dt
      if self.fade >= 0 then self.fade = nil end
    else
      self.fade = self.fade + 255 / fadeout * dt
      if self.fade > 255 then Gamestate.pop() end
    end
  end
end

function Message:keyreleased(key)
  self.fade = 0
end

function Message:mousereleased(x, y, button)
  self.fade = 0
end

return Message;
