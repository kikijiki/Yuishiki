local class = require "lib.middleclass"

local BattleInterface = class("BattelInterface")
local Cursor = summon.class("Cursor")

local sg = summon.graphics
local vec = summon.vec

local fonts = {
  normal = summon.AssetLoader.load("font", "ipamp.ttf@24"),
  small = summon.AssetLoader.load("font", "ipamp.ttf@12")
}

function Cursor:initialize()
  self.texture = summon.AssetLoader.load("texture", "gb.png")
  self.size = vec(84, 96)
  self.center = self.size / 2
  self.target = nil
  self.dy = 0
  self.elapsed = 0
  self.offset = 20
  self.jump = 15
  self.scale = 0.2
end

function Cursor:update(dt)
  self.elapsed = self.elapsed + dt
  self.dy = math.sin(self.elapsed * 10) * self.jump
  if self.dy > 0 then self.dy = -self.offset
  else self.dy = self.dy - self.offset end
end

function Cursor:draw()
  if not self.target then return end
  sg.setColor(255, 255, 255, 255)
  sg.draw(
    self.texture.data,
    self.target.x, self.target.y + self.dy, 0,
    self.scale, self.scale,
    self.center.x, self.center.y);
end

function BattleInterface:initialize(stage)
  self.stage = stage
  self.cursor = Cursor()
  self.mouse = {}
  self.console = {}
end

function BattleInterface:setCursor(position)
  self.cursor.target = position
end

function BattleInterface:update(dt)
  self.cursor:update(dt)
end

function BattleInterface:drawCursor()
  self.cursor:draw()
end

function BattleInterface:drawTurnOrder(x, y)
  local init = self.stage.gm.initiative
  local turnc = self.stage.gm.turnCount
  local spacing = fonts.normal:getHeight() + 10
  if turnc == 0 or init.current == 0 then return end

  fonts.normal:apply()
  sg.setColor(255, 255, 255, 255)

  for i = 1, #init.list do
    local j = (i + init.current) % #init.list + 1
    local name = init.results[j][2].name
    local value = init.results[j][1]
    local text = j..". "..name.."("..value..")"
    sg.print(text, x, y)
    y = y + spacing
  end
end

function drawBar(x, y, w, h, v, max, color)
  local barw = w * v / max
  barw = math.max(0, barw)

  sg.setColor(30, 30, 30)
  sg.rectangle("fill", x, y, w, h)

  sg.setColor(color)
  sg.rectangle("fill", x + 2, y + 2, barw - 4, h - 4)

  local pad = (h - fonts.normal:getHeight()) / 2
  fonts.normal:apply()
  sg.setColor(255, 255, 255)
  sg.print(v.."/"..max, x + pad, y + pad)

  sg.setColor(180, 180, 180)
  sg.rectangle("line", x, y, w, h)
end

function BattleInterface:drawCharacterInfo(char, x, y, w, scrh)
  if not char then return end

  local border = 2
  local padding = 10
  local p2 = padding / 2
  local stats = {}-- "str", "dex", "cos", "int", "spd", "mov"}--, "atk", "def", "arm", "matk", "mdef", "marm" }
  local spacing = fonts.normal:getHeight() + padding
  local h = #stats * spacing + (spacing + 4) * 3 + spacing + padding
  y = scrh - y - h
  local sx, sy = x, y

  sg.setColor(100, 100, 100, 200)
  sg.rectangle("fill", sx, sy, w + border * 2, h + border * 2)

  x = x + border
  y = y + border + p2

  sg.setColor(255, 255, 255, 255)
  fonts.normal:apply()

  sg.printf(char.name, x, y, w, "center")
  y = y + spacing

  drawBar(x + p2, y, w - padding, spacing, char.status.hp:get(), char.status.maxhp:get(), {200, 0, 0}) y = y + spacing + 4
  drawBar(x + p2, y, w - padding, spacing, char.status.mp:get(), char.status.maxmp:get(), {60, 60, 200}) y = y + spacing + 4
  drawBar(x + p2, y, w - padding, spacing, char.status.ap:get(), char.status.maxap:get(), {200, 200, 0}) y = y + spacing + 4

  sg.setColor(255, 255, 255, 255)
  for _,stat in pairs(stats) do
    local v = char.status[stat]
    sg.printf(stat..":", x, y, w/2, "right")
    sg.printf(tostring(v), x + w/2 + 5, y, w/2, "center")
    y = y + spacing
  end

  sg.setLineWidth(border)
  sg.setColor(180, 180, 180)
  sg.rectangle("line", sx, sy, w + border * 2, y - sy)
  sg.setColor(255, 255, 255)
end

function BattleInterface:draw()
  self:drawTurnOrder(20, 20)
  self:drawCharacterInfo(self.stage.gm.activeCharacter, 20, 20, 150, self.stage.height)
end

return BattleInterface
