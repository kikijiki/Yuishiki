local Gui

return function(loader)
  if Gui then return Gui end

  local sg          = loader.require "graphics"
  local AssetLoader = loader.load    "asset-loader"

  Gui = {}

  local Chatlog = loader.class("Gui.Chatlog")
  Gui.Chatlog = Chatlog

  function Chatlog:initialize(w, limit, fade)
    self.x = 0
    self.y = y or 10
    self.w = w
    self.buffer = {}
    self.size = 0
    self.limit = limit or 3
  end

  function Chatlog:resize(w, h)
    local size = math.min(w, h)

    self.font_size = size / 20
    self.spacing = self.font_size / 4
    self.font = AssetLoader.load("font", "ipamp.ttf@"..self.font_size)

    self.w = w
    self.y = h - (self.font_size + self.spacing) * self.limit
  end

  function Chatlog:log(tag, text)
    table.insert(self.buffer,
      {
        tag,
        text,
        5000
      })
    self.size = self.size + 1
    end

  function Chatlog:draw()
    local y = self.y
    local s = self.spacing
    local s2 = self.spacing / 2

    if self.size == 0 then return end

    self.font:apply()
    local last = math.max(1, self.size - self.limit)
    for i = self.size, last, -1 do
      local entry = self.buffer[i]

      if entry[3] > 0 then
        local text = string.format("%s - %s", entry[1], entry[2])
        local w = self.font:getWidth(text)
        local x = self.x + (self.w - w) / 2

        sg.setColor(128, 128, 128, math.min(128, entry[3]))
        sg.rectangle("fill", x - s2, y - s2, w + s, self.font_size + s)

        sg.setColor(255, 255, 255, math.min(255, entry[3]))
        sg.printf(text, self.x, y, self.w, "center")
        y = y + self.font_size + self.spacing
      else
        return
      end
    end
  end

  function Chatlog:update(dt)
    local last = math.max(1, self.size - self.limit)
    for i = self.size, last, -1 do
      local entry = self.buffer[i]
      if entry[3] > 0 then entry[3] = entry[3] - dt * 1000 end
    end
  end

  local RoundButton = loader.class("Gui.RoundButton")
  Gui.RoundButton = RoundButton

  function RoundButton:initialize(x, y, size, text, callback)
    self.x = x
    self.y = y
    self.callback = callback
    self.text = text
    self.colors = {
      background = { 60,  60,  60},
      foreground = {120, 120, 120},
      border     = {255, 255, 255}
    }
    self:resize(size)
  end

  function RoundButton:resize(size)
    self.size = size
    self.font_size = size * 2
    self.font = AssetLoader.load("font", "ipamp.ttf@"..self.font_size)
    self.text_width = self.font:getWidth(self.text)
  end

  function RoundButton:draw()
    sg.setColor(self.colors.background)
    sg.circle("fill", self.x, self.y, self.size)
    sg.setColor(self.colors.border)
    sg.circle("line", self.x, self.y, self.size)
    sg.setColor(self.colors.foreground)
    self.font:apply()
    sg.print(self.text, self.x - self.text_width / 2, self.y - self.font_size / 2)
    sg.setColor(255, 255, 255)
  end

  function RoundButton:mousereleased(x, y, button)
    local dx = self.x - x
    local dy = self.y - y
    if dx^2 + dy^2 < self.size^2 then
      self.callback()
    end
  end

  function RoundButton:update(dt) end

  local PlayButton = loader.class("Gui.PlayButton")
  Gui.PlayButton = PlayButton

  function PlayButton:initialize(x, y, size, callback)
    self.x = x
    self.y = y
    self.size = size
    self.font_size = size
    self.color = {255, 255, 255}
    self.callback = callback

    self.colors = {
      background = { 60,  60,  60},
      foreground = {120, 120, 120},
      border     = {255, 255, 255}
    }

    self.state = "play"
    self.elapsed = 0
  end

  function PlayButton:draw()
    sg.setColor(self.colors.background)
    sg.circle("fill", self.x, self.y, self.size)
    sg.setColor(self.colors.border)
    sg.circle("line", self.x, self.y, self.size)

    local x = self.x
    local y = self.y

    sg.setColor(self.colors.foreground)
    if self.state == "play" then
      local d2 = self.size / 2
      local d4 = self.size / 4

      sg.polygon("fill",
        x - d4, y - d2,
        x + d2, y,
        x - d4, y + d2)
    else
      local d2 = self.size / 2
      local d3 = self.size / 3
      local pi3 = 2 * math.pi / 3
      local a = self.elapsed * 10
      local cx, cy

      cx = x + math.cos(a) * d2
      cy = y + math.sin(a) * d2
      sg.circle("fill", cx, cy, d3)

      a = a + pi3
      cx = x + math.cos(a) * d2
      cy = y + math.sin(a) * d2
      sg.circle("fill", cx, cy, d3)

      a = a + pi3
      cx = x + math.cos(a) * d2
      cy = y + math.sin(a) * d2
      sg.circle("fill", cx, cy, d3)
    end

    sg.setColor(255, 255, 255, 255)
  end

  function PlayButton:update(dt)
    self.elapsed = self.elapsed + dt
  end

  function PlayButton:play()
    self.state = "play"
  end

  function PlayButton:stop()
    self.state = "stop"
  end

  function PlayButton:mousereleased(x, y, button)
    local dx = self.x - x
    local dy = self.y - y
    if dx^2 + dy^2 < self.size^2 then
      self.callback()
    end
  end

  return Gui
end
