local Console

return function(loader)
  if Console then return Console end

  local sg = loader.require "graphics"

  Console = loader.class("Console")

  function Console:initialize(rw, rh, x, y)
    self.visible = false
    self.enable_key = "`"
    self.buffer = {}
    self.buffer_length = 0
    self.font_size = 20
    self.font = sg.newFont("assets/fonts/msmincho.ttc", self.font_size) -- TODO
    self.current_line = 1
    self.padding = 5
    self.margin = 10
    self.colors = {}
    self.colors.INF        = { 251, 241, 213      }
    self.colors.DBG        = { 235, 197,  50      }
    self.colors.WRN        = { 222,  69,  61      }
    self.colors.ERR        = { 255,  10,  10      }
    self.colors.background = {  23,  55,  86, 190 }
    self.x = x or 0
    self.y = y or 0
    self.rw = rw or 0.5
    self.rh = rh or 1
    self.width = 0
    self.height = 0
  end

  function Console:resize(w, h)
    self.width = self.rw * w
    self.height = self.rh * h
  end

  function Console:keypressed(key)
  	if key == self.enable_key then self.visible = not self.visible end
  end

  function Console:draw()
  	if not self.visible then return end

  	local original_color = {sg.getColor()}
  	local original_font = sg.getFont()

  	sg.setColor(self.colors.background)
  	sg.rectangle("fill", self.x, self.y, self.width, self.height)

    if self.buffer_length == 0 then return end

  	sg.setFont(self.font)

    local index = self.current_line
    local lx = self.margin
    local ly = self.y + self.height - self.margin
    local lw = math.max(0, self.width - self.margin * 2)

    while index > 0 and index <= self.buffer_length do
      local data = self.buffer[self.buffer_length - index + 1]
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

  function Console:mousepressed(x, y, button )
  	if not self.visible then return false end

    local consumed = false

    if button == "wu" then
    	self.current_line = self.current_line + 1
   		consumed = true
    end

    if button == "wd" then
    	self.current_line = self.current_line - 1
    	consumed = true
    end

    if self.current_line < 1 then self.current_line = 1 end
    if self.current_line > self.buffer_length then self.current_line = self.buffer_length end

  	return consumed
  end

  local function log(self, level, msg)
    --local NBSP = "\194\160"
    --msg = msg:gsub(" ", NBSP)
    table.insert(self.buffer, {level, string.format("[%05d]> %s", (self.buffer_length + 1), msg)})
    self.buffer_length = self.buffer_length + 1
    if self.current_line > 1 then self.current_line = self.current_line + 1 end
  end

  function Console:i(msg) log(self, "INF", msg) end
  function Console:d(msg) log(self, "DBG", msg) end
  function Console:w(msg) log(self, "WRN", msg) end
  function Console:e(msg)	log(self, "ERR", msg) end

  return Console
end
