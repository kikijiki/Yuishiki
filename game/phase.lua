local gui = require "lib.quickie"
local summon = require "summon"()
local Stage = summon.Stage
local vec = summon.Vector
local sg = summon.graphics

local Phase = summon.class("state.Phase")

function Phase:initialize(data)
  self.stages = {}
  self.activeStage = nil
  self.title = data.title
  self.description = data.description
  self.vp = vec(0, 0)
  self.padding = 10
  self.title_size = 80
  self.description_size = 40
  self.font = {
    description =
      summon.AssetLoader.load("font", "ipamp.ttf@"..self.description_size),
    title = summon.AssetLoader.load("font", "ipamp.ttf@"..self.title_size),
  }

  self.text = {
    next = {
      en = "Next",
      ja = "次へ"
    }
  }

  for _,stage_data in pairs(data.stages) do
    local stage = Stage(stage_data)
    table.insert(self.stages, {instance = stage, mouse = {}, vp = {}})
  end

  self:resize()
  self.activeStage = self.stages[1]
end

function Phase:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end

  self.vp = vec(w, h)
  local header = self.title_size + self.description_size + self.padding * 3
  local scount = #self.stages
  local sw = (w - self.padding * (scount + 1)) / scount
  local sh = h - header - self.padding
  local x = self.padding
  local y = header

  for _,stage in pairs(self.stages) do
    stage.instance:resize(sw, sh)
    stage.vp = {x = x, y = y, w = sw, h = sh}
    x = x + sw + self.padding
  end
end

function Phase:drawStageBorder(stage, color)
    local vp = stage.vp
    local p = self.padding
    local p2 = p * 2
    sg.setColor(color)
    sg.rectangle("fill",    vp.x - p,    vp.y - p, vp.w + p2,         p)
    sg.rectangle("fill",    vp.x - p, vp.y + vp.h, vp.w + p2,         p)
    sg.rectangle("fill",    vp.x - p,    vp.y - p,         p, vp.h + p2)
    sg.rectangle("fill", vp.x + vp.w,    vp.y - p,         p, vp.h + p2)
end

function Phase:draw()
  local locale = self.game.locale

  sg.setColor(200, 200, 200)
  self.font.title:apply()
  sg.print(self.title[locale] or "", self.padding, self.padding)

  self.font.description:apply()
  sg.print(self.description[locale] or "",
    self.padding, self.title_size + self.padding * 2)

  for _,stage in pairs(self.stages) do
    self:drawStageBorder(stage, {64, 64, 64})
    sg.push()
    sg.translate(stage.vp.x, stage.vp.y)
    stage.instance:draw()
    sg.pop()
  end

  gui.core.draw()
end

local function setLocalCoordinates(stage, x, y)
  local mx = x - stage.vp.x
  if mx < 0 then mx = 0 end
  if mx > stage.vp.w then mx = stage.vp.w end
  stage.mouse.x = mx

  local my = y - stage.vp.y
  if my < 0 then my = 0 end
  if my > stage.vp.h then my = stage.vp.h end
  stage.mouse.y = my

  stage.instance.mouse.x = stage.mouse.x
  stage.instance.mouse.y = stage.mouse.y
end

local function isInStage(stage, x, y)
  return x >= stage.vp.x and x < (stage.vp.x + stage.vp.w) and
    y >= stage.vp.y and y < (stage.vp.y + stage.vp.h)
end

function Phase:update(dt)
  local locale = self.game.locale

  self.font.description:apply()
  if gui.Button{
    text = self.text.next[locale],
    pos = {self.vp.x - self.padding - 120, self.padding},
    size = {120, self.title_size + self.description_size}} then
      self:pop()
    end

  if gui.Button{
      text = ".",
      pos = {self.vp.x - self.padding -180, self.padding + 80},
      size = {40, 40}}
    then
    console:flip()
  end

  local mx, my = love.mouse.getPosition()

  for _,stage in pairs(self.stages) do
    if isInStage(stage, mx, my) then
      self.activeStage = stage
    end
    setLocalCoordinates(stage, mx, my)
    stage.instance:update(dt)
  end
end

function Phase:onPush(game, prev)
  self.game = game
  for _,stage in pairs(self.stages) do stage.instance:setLocale(game.locale) end
end

function Phase:keypressed(key)
  if self.activeStage then self.activeStage.instance:keypressed(key) end
end

function Phase:mousepressed(x, y, button)
  local as = self.activeStage
  if as then
    setLocalCoordinates(as, x, y)
    as.instance:mousepressed(as.mouse.x, as.mouse.y, button)
  end
end

function Phase:mousereleased(x, y, button)
  local as = self.activeStage
  if as then
    setLocalCoordinates(as, x, y)
    as.instance:mousereleased(as.mouse.x, as.mouse.y, button)
  end
end

function Phase:pop()
  local data = {}
  for i, stage in ipairs(self.stages) do
    data[i] = stage.instance:export()
  end
  if self.next_phase then self.next_phase:import(data) end
  self.game:pop()
end

function Phase:import(data)
  for i, stage in ipairs(self.stages) do
    stage.instance:import(data[i])
  end
end

return Phase
