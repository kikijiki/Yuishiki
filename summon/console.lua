local Console

return function(loader)
  if Console then return Console end

  local sg          = loader.require "graphics"
  local uti         = loader.load "uti"
  local AssetLoader = loader.load "asset-loader"

  Console = loader.class("Console")

  function Console:initialize(rw, rh, x, y)
    self.visible       = false
    self.enable_key    = "`"
    self.buffer        = {length = 0}
    self.font_size     = 20
    self.font          = AssetLoader.load("font", "msmincho.ttc@"..self.font_size)
    self.current_line  = 0
    self.padding       = 5
    self.margin        = 10
    self.colors        = {}
    self.colors.INF    = { 251, 241, 213      }
    self.colors.DBG    = { 235, 197,  50      }
    self.colors.WRN    = { 222,  69,  61      }
    self.colors.ERR    = { 255,  10,  10      }
    self.colors.back   = {  23,  55,  86, 190 }
    self.x             = x or 0
    self.y             = y or 0
    self.rw            = rw or 0.5
    self.rh            = rh or 1
    self.width         = 0
    self.height        = 0
    self.page          = 3
  end

  function Console:resize(w, h)
    self.width = self.rw * w
    self.height = self.rh * h
    self.page = math.max(1, math.floor((h - self.margin * 2) / (self.font_size + self.padding)) - 1)
  end

  function Console:scroll(l)
    if l == 0 then self.current_line = 1
    else self.current_line = self.current_line + l end

    if self.current_line < 1 then self.current_line = 1 end
    if self.current_line > self.buffer.length then self.current_line = self.buffer.length end
  end

  function Console:show() self.visible = true end
  function Console:hide() self.visible = false end
  function Console:flip() self.visible = not self.visible end

  function Console:keypressed(key)
  	if key == self.enable_key then self:flip() return false end
    if not self.visible then return false end

    local consumed = false

    if key == "up"       then self:scroll( 1)         consumed = true end
    if key == "down"     then self:scroll(-1)         consumed = true end
    if key == "pageup"   then self:scroll( self.page) consumed = true end
    if key == "pagedown" then self:scroll(-self.page) consumed = true end
    if key == "end"      then self:scroll(0)          consumed = true end

    if key == "delete"   then self:clear()            consumed = true end

    return consumed
  end

  function Console:mousepressed(x, y, button)
  	if not self.visible then return false end

    local consumed = false

    if button == "wu" then self:scroll( 3) consumed = true end
    if button == "wd" then self:scroll(-3) consumed = true end
    if button ==  "m" then self:scroll( 0) consumed = true end

    if self.current_line < 1 then self.current_line = 1 end
    if self.current_line > self.buffer.length then self.current_line = self.buffer.length end

  	return consumed
  end

  function Console:mousereleased(x, y, button)
    return false
  end

  function Console:draw()
  	if not self.visible then return end

  	local original_color = {sg.getColor()}
  	local original_font = sg.getFont()

  	sg.setColor(self.colors.back)
  	sg.rectangle("fill", self.x, self.y, self.width, self.height)

    if self.buffer.length == 0 then return end

  	self.font:apply()

    local index = self.current_line or 1
    local lx = self.margin
    local ly = self.y + self.height - self.margin
    local lw = math.max(0, self.width - self.margin * 2)

    while index > 0 and index <= self.buffer.length do
      local data = self.buffer[self.buffer.length - index + 1]
      local width, lines = self.font:getWrap(data[2], lw)
      lines = math.max(1, lines)
      ly = ly - lines * (self.font_size + self.padding)
      sg.setColor(self.colors[data[1]])
      sg.printf(data[2], lx, ly, lw, "left")
      if ly < self.y then return end
      index = index + 1
    end

    if original_font then sg.setFont(original_font) end
  	sg.setColor(original_color)
  end

  function Console:clear()
    self.current_line = 1
    self.buffer = {length = 0}
  end

  local function insert(buf, level, str, noindex)
    table.insert(buf, {level, str})
    buf.length = buf.length + 1
  end

  local function log(self, level, msg)
    local l = uti.lines(msg)
    insert(self.buffer, level, l[1])
    if #l > 1 then
      for i = 2, #l do insert(self.buffer, level, l[i]) end
    end
    if self.current_line > 1 then self.current_line = self.current_line + #l end
  end

  function Console:i(msg) log(self, "INF", msg) end
  function Console:d(msg) log(self, "DBG", msg) end
  function Console:w(msg) log(self, "WRN", msg) end
  function Console:e(msg)	log(self, "ERR", msg) end

  return Console
end
