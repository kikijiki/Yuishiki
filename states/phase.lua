local Phase = summon.class("state.Phase")

local Stage = require "stage"
local Gamestate = require "lib.hump.gamestate"
local gui = require "lib.quickie"
local vec = summon.vec

local padding = 10
local title_size = 80
local description_size = 40

local font = {
  description = summon.AssetLoader.load("font", "ipamp.ttf@"..description_size),
  title = summon.AssetLoader.load("font", "ipamp.ttf@"..title_size),
}

local sg = summon.graphics

function Phase:initialize(data)
  self.stages = {}
  self.activeStage = nil
  self.title = data.title
  self.description = data.desc
  self.vp = vec(0, 0)

  for _,stage_data in pairs(data.stages) do
    local stage = Stage(stage_data)
    table.insert(self.stages, {stage, {}})
  end
end

function Phase:enter(previous)
  self:resize()
  self.activeStage = self.stages[1]
end

function Phase:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end

  self.vp = vec(w, h)
  local header = title_size + description_size + padding * 3
  local scount = #self.stages
  local sw = (w - padding * (scount + 1)) / scount
  local sh = h - header - padding
  local x = padding
  local y = header

  for _,stage in pairs(self.stages) do
    stage[1]:resize(sw, sh)
    stage[2] = {x = x, y = y, w = sw, h = sh}
    x = x + sw + padding
  end
end

function drawStageBorder(stage, color)
    local vp = stage[2]
    local p = padding
    local p2 = p * 2
    sg.setColor(color)
    sg.rectangle("fill",    vp.x - p,    vp.y - p, vp.w + p2,         p)
    sg.rectangle("fill",    vp.x - p, vp.y + vp.h, vp.w + p2,         p)
    sg.rectangle("fill",    vp.x - p,    vp.y - p,         p, vp.h + p2)
    sg.rectangle("fill", vp.x + vp.w,    vp.y - p,         p, vp.h + p2)
end

function Phase:draw()
  sg.setColor(200, 200, 200)
  font.title:apply()
  sg.print(self.title or "", padding, padding)
  font.description:apply()
  sg.print(self.description or "", padding, title_size + padding * 2)

  for _,stage in pairs(self.stages) do
    drawStageBorder(stage, {64, 64, 64})
    sg.push()
    sg.translate(stage[2].x, stage[2].y)
    stage[1]:draw()
    sg.pop()
  end

  font.description:apply()
  gui.core.draw()
end

function Phase:update(dt)
  if gui.Button{
    text = "Next",
    pos = {self.vp.x - 120 - padding, padding},
    size = {120, title_size + description_size}} then
      Gamestate.pop()
  end

  if self.activeStage then
    self.activeStage[1].mouse.x = love.mouse.getX() - self.activeStage[2].x
    self.activeStage[1].mouse.y = love.mouse.getY() - self.activeStage[2].y
  end
  for _,stage in pairs(self.stages) do stage[1]:update(dt) end
end

function Phase:keypressed(key)
  if self.activeStage then self.activeStage[1]:keypressed(key) end
end

function Phase:updateStageMouse(stage, x, y)
  stage.mouse.x = x
  stage.mouse.y = y
end

function Phase:mousepressed(x, y, button)
  for _,stage in pairs(self.stages) do
    if x >= stage[2].x and x < (stage[2].x + stage[2].w) and
       y >= stage[2].y and y < (stage[2].y + stage[2].h) then
        self.activeStage = stage
        x = x - stage[2].x
        y = y - stage[2].y
        self:updateStageMouse(stage[1], x, y)
        stage[1]:mousepressed(x, y, button)
        return
    end
  end
end

function Phase:mousereleased(x, y, button)
  if self.activeStage then
    x = x - self.activeStage[2].x
    y = y - self.activeStage[2].y
    self:updateStageMouse(self.activeStage[1], x, y)
    self.activeStage[1]:mousereleased(x, y, button)
  end
end

return Phase
