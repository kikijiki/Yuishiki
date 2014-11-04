local Gui

return function(loader)
  if Gui then return Gui end

  local graphics = loader.require "graphics"
  local Gui = loader.class("Gui")
  local Vector = loader.class("Gui.Vector")
  local Widget = loader.class("Gui.Widget")
  local Button = loader.class("Gui.Button", Widget)

  function Gui:initialize(w, h)
    self.widgets = {}
    self:resize(w, h)
  end

  function Gui:draw()
    for _,w in pairs(self.widgets) do
      w:draw(self)
    end
  end

  function Gui:update(dt)
  end

  function Gui:resize(w, h)
    self.width = w
    self.height = h
  end

  function Gui:keypressed(key)

  end

  function Gui:mousepressed(x, y, button)

  end

  function Gui:add(widget)
    table.insert(self.widgets, widget)
    widget:prepare(self)
  end

  function Gui:getPixelValue(value)
    local x = value[1] * self.width + value[2]
    local y = value[3] * self.height + value[4]
    return vec(x, y)
  end

  function Vector:initialize(xr, xp, yr, yp)
    self.xr = xr or 0
    self.xp = xp or 0
    self.yr = yr or 0
    self.yp = yp or 0
  end

  function Vector:get(gui)
    local x = self.xr * gui.width + self.xp
    local y = self.yr * gui.heigt + self.yp
    return {x = x, y = y}
  end

  function Widget:initialize(xt, xp, yr, yp)
    self.position = Vector(xt, xp, yr, yp)
  end

  function Button:initialize(text, handler, xt, xp, yr, yp)
    Widget.initialize(self, xt, xp, yr, yp)
    self.text = text
    self.handler = handler
    self.status = "active"
    self.margin = 4
    self.corner = 10
    self.background = {
      active = {100, 100, 100},
      disabled = {20, 20, 20},
      hover = {120, 120, 120},
      pressed = {150, 150, 150}
    }
    self.color = {220, 220, 220}
  end

  function Button:prepare(gui)
    local text_width = gui.font:getWidth(self.text)
    local text_height = gui.font:getWrap(self.text, text_width)
  end

  function Button:draw(gui)
    local pos = self.position:get(gui)
    local x = pos.x
    local y = pos.y + self.corner * 2
    local width = self.text_width + self.margin * 2
    local height = self.text_height + self.margin * 2
    local background = self.background[self.status]

    graphics.setColor(background)
    graphics.rectangle("fill", x, y, width, height)

    x = x + self.corner
    y = y - self.corner
    width = width - self.corner * 2
    height = height + self.corner * 2

    graphics.setColor(background)
    graphics.rectangle("fill", x, y, width, height)

    x = x + self.corner
    y = y - self.corner
    width = width - self.corner * 2
    height = height + self.corner * 2

    graphics.setColor(background)
    graphics.rectangle("fill", x, y, width, height)

    x = pos.x
    y = pos.y + self.corner * 2

    graphics.setColor(self.color)
    graphics.printf(self.text, x, y, self.text_width, self.text_height, "center")
  end

  function Button:onClick()
    if self.handler then self.handler() end
  end

  return Gui
end