local Gui

return function(loader)
  if Gui then return Gui end

  local sg          = loader.require "graphics"
  local AssetLoader = loader.load    "asset-loader"

  Gui = {}

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
