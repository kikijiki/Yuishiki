local BattleInterface

return function(loader)
  if BattleInterface then return BattleInterface end
  BattleInterface = loader.class("BattleInterface")

  local sg          = loader.require "graphics"
  local vec         = loader.require "vector"
  local AssetLoader = loader.load "asset-loader"

  local Cursor = loader.class("Cursor")

  function Cursor:initialize()
    self.texture = AssetLoader.load("texture", "gb.png")
    self.size    = vec(84, 96)
    self.center  = self.size / 2
    self.target  = nil
    self.dy      = 0
    self.elapsed = 0
    self.offset  = 20
    self.jump    = 15
    self.scale   = 0.2
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
    self.game = stage.game
    self.cursor = Cursor()
    self.mouse = {}
    self.console = {}
  end

  function BattleInterface:resize(w, h)
    w = w or 0
    h = h or 0
    local size = math.min(w, h)
    local normal_size = size / 20
    local small_size = size / 25
    self.border = small_size / 8
    self.padding = small_size / 8

    self.fonts = {
      normal_size = normal_size,
      normal = AssetLoader.load("font", "ipamp.ttf@"..normal_size),
      small_size = small_size,
      small = AssetLoader.load("font", "ipamp.ttf@"..small_size)
    }
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
    local spacing = self.fonts.normal_size * 1.1
    if turnc == 0 or init.current == 0 then return end
    local pad = (spacing - self.fonts.normal_size) / 2

    self.fonts.normal:apply()
    sg.setColor(255, 255, 255, 255)

    for i = 1, #init.list do
      local name = self.game:getLocalizedString(init.list[i].character.name)
      local value = init.list[i].value
      local text = i..". "..name.."("..value..")"
      local textw = self.fonts.normal:getWidth(text)
      sg.setColor(0, 0, 0, 135)
      sg.rectangle("fill", x - pad * 2, y - pad, textw + pad * 4, self.fonts.normal_size + pad*2)
      if i == init.current then
        sg.setColor(255, 0, 0)
      else
        sg.setColor(255, 255, 255)
      end
      sg.print(text, x, y)
      y = y + spacing
    end
  end

  local function drawBar(font, x, y, w, h, b, v, max, color)
    local barw = w * v / max
    barw = math.max(0, barw)

    sg.setColor(30, 30, 30)
    sg.rectangle("fill", x, y, w, h)

    sg.setColor(color)
    sg.rectangle("fill", x + b, y + b, barw - b*2, h - b*2)

    local pad = (h - font:getHeight()) / 2
    font:apply()
    sg.setColor(255, 255, 255)
    sg.print(v.."/"..max, x + pad, y + pad)

    sg.setColor(180, 180, 180)
    sg.rectangle("line", x, y, w, h)
  end

  function BattleInterface:drawCharacterInfo(char, x, y, scrh)
    if not char then return end

    local bar_width = math.max(
      self.fonts.small:getWidth("000/000"),
      self.fonts.small:getWidth(self.game:getLocalizedString(char.name)))

    bar_width = bar_width * 1.5

    local border = self.border
    local padding = self.padding
    local p2 = padding / 2
    local stats = {}-- "str", "dex", "con", "int", "spd", "mov"}--, "atk", "def", "arm", "matk", "mdef", "marm" }
    local spacing = self.fonts.normal:getHeight() + padding
    local h = #stats * spacing + (spacing + 4) * 3 + spacing + padding
    y = scrh - y - h
    local sx, sy = x, y

    sg.setColor(100, 100, 100, 200)
    sg.rectangle("fill", sx, sy, bar_width + border * 2, h + border * 2)

    x = x + border
    y = y + border + p2

    sg.setColor(255, 255, 255, 255)
    local font = self.fonts.small
    local fsize = self.fonts.small_size
    font:apply()

    sg.printf(self.game:getLocalizedString(char.name), x, y, bar_width, "center")
    y = y + spacing

    drawBar(
      font,
      x + p2, y, bar_width - padding, spacing, border,
      char.status.hp:get(),
      char.status.maxhp:get(),
      {200, 0, 0})
    y = y + spacing + 4

    drawBar(
      font,
      x + p2, y, bar_width - padding, spacing, border,
      char.status.mp:get(),
      char.status.maxmp:get(),
      {60, 60, 200})
    y = y + spacing + 4

    drawBar(
      font,
      x + p2, y, bar_width - padding, spacing, border,
      char.status.ap:get(),
      char.status.maxap:get(),
      {200, 200, 0})
    y = y + spacing + 4

    sg.setColor(255, 255, 255, 255)
    for _,stat in pairs(stats) do
      local v = char.status[stat]
      sg.printf(stat..":", x, y, bar_width/2, "right")
      sg.printf(tostring(v), x + bar_width/2 + 5, y, bar_width/2, "center")
      y = y + spacing
    end

    sg.setLineWidth(border)
    sg.setColor(180, 180, 180)
    sg.rectangle("line", sx, sy, bar_width + border * 2, y - sy)
    sg.setColor(255, 255, 255)
  end

  function BattleInterface:draw(char)
    self:drawTurnOrder(20, 20)
    self:drawCharacterInfo(char, 20, 20, self.stage.height)
  end

  return BattleInterface
end
