local gui = require "lib.quickie"
local summon = require "summon"()
local Stage = summon.Stage
local vec = summon.Vector
local sg = summon.graphics

local Phase = summon.class("state.Phase")

function Phase:initialize(data)
  self.stages = {}
  self.stages_data = data.stages
  self.activeStage = nil
  self.title = data.title
  self.description = data.description
  self.text = {
    next = {
      en = "Next",
      ja = "次へ",
      it = "Continua"
    },
    finish = {
      en = "End",
      ja = "終了",
      it = "Fine"
    }
  }
end

function Phase:onPush(game, prev)
  for _,stage_data in pairs(self.stages_data) do
    local stage = Stage(game, stage_data)
    table.insert(self.stages, {instance = stage, mouse = {}, vp = {}})
  end
  self.stage_data = nil
  self.activeStage = self.stages[1]

  self:resize()
  self.next_w = 1.5 * self.font.description:getWidth(
    game:getLocalizedString(self.text.next))
end

function Phase:resize(w, h)
  if not w or not h then w,h = sg.getDimensions() end
  local size = math.min(w, h)

  self.padding = size / 100
  self.title_size = size / 15
  self.description_size = size / 20
  self.font = {
    description = summon.AssetLoader.load("font", "ipamp.ttf@"..self.description_size),
    title = summon.AssetLoader.load("font", "ipamp.ttf@"..self.title_size),
  }

  self.vp = vec(w, h)
  local header = self.title_size + self.description_size + self.padding * 3
  local scount = #self.stages
  local sw = (w - self.padding * (scount + 1)) / scount
  local sh = h - header - self.padding
  local x = self.padding
  local y = header

  self.next_w = 1.5 * self.font.description:getWidth(
    self.game:getLocalizedString(self.text.next))

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
  sg.setColor(200, 200, 200)
  self.font.title:apply()
  sg.print(self.game:getLocalizedString(self.title), self.padding, self.padding)

  self.font.description:apply()
  sg.print(self.game:getLocalizedString(self.description),
    self.padding, self.title_size + self.padding * 2)

  for _,stage in pairs(self.stages) do
    self:drawStageBorder(stage, {64, 64, 64})
    sg.push()
    sg.translate(stage.vp.x, stage.vp.y)
    stage.instance:draw()
    sg.pop()
  end

  if self.activeStage then
    self:drawStageBorder(self.activeStage, {128, 128, 128})
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
  self.font.description:apply()
  local caption
  if self.next_phase then caption = self.text.next
  else caption = self.text.finish end

  if gui.Button{
      text = self.game:getLocalizedString(caption),
      pos = {self.vp.x - self.padding - self.next_w, self.padding},
      size = {self.next_w, self.title_size + self.description_size}} then
    self:pop()
  end

  for _,stage in pairs(self.stages) do
    stage.instance:update(dt)
  end
end

function Phase:keypressed(key)
  if self.activeStage then self.activeStage.instance:keypressed(key) end
end

function Phase:updateMouse(x, y)
  for _,stage in pairs(self.stages) do
    setLocalCoordinates(stage, x, y)
  end
end

function Phase:mousepressed(x, y, button)
  for _,stage in pairs(self.stages) do
    if isInStage(stage, x, y) then
      self.activeStage = stage
      setLocalCoordinates(stage, x, y)
      stage.instance:mousepressed(stage.mouse.x, stage.mouse.y, button)
      return
    end
  end
end

function Phase:mousereleased(x, y, button)
  local as = self.activeStage
  if as then
    setLocalCoordinates(as, x, y)
    as.instance:mousereleased(as.mouse.x, as.mouse.y, button)
  end
end

function Phase:touchgestured(x, y, theta, distance, touchcount)
  local as = self.activeStage
  if as then
    as.instance:touchgestured(as.mouse.x, as.mouse.y, theta, distance, touchcount)
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
