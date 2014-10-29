local console = {}
console.__index = console

function console.new(rw, rh, x, y)
  local c = {}
  c.visible = false
  c.enable_key = "`"
  c.buffer = {}
  c.buffer_length = 0
  c.font_size = 20
  c.font = love.graphics.newFont(c.font_size)
  c.current_line = 1
  c.padding = 5
  c.margin = 10
  console.colors = {}
  console.colors.INF        = { 251, 241, 213      }
  console.colors.DBG        = { 235, 197,  50      }
  console.colors.WRN        = { 222,  69,  61      }
  console.colors.ERR        = { 255,  10,  10      }
  console.colors.background = {  23,  55,  86, 190 }
  c.x = x or 0
  c.y = y or 0
  c.rw = rw or 0.5
  c.rh = rh or 1
  c.width = 0
  c.height = 0

  return setmetatable(c, console)
end

function console.resize(self, w, h)
  self.width = self.rw * w
  self.height = self.rh * h
end

function console.keypressed(self, key) 
	if key == self.enable_key then self.visible = not self.visible end
end

function console.draw(self)
	if not self.visible then return end

	local original_color = {love.graphics.getColor()}
	local original_font = love.graphics.getFont()

	love.graphics.setColor(self.colors.background)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

  if self.buffer_length == 0 then return end

	love.graphics.setFont(self.font)

  local index = self.current_line
  local lx = self.margin
  local ly = self.y + self.height - self.margin
  local lw = math.max(0, self.width - self.margin * 2)

  while index > 0 and index <= self.buffer_length do
    local data = self.buffer[self.buffer_length - index + 1]
    local width, lines = self.font:getWrap(data[2], lw)
    lines = math.max(1, lines)
    ly = ly - lines * (self.font_size + self.padding)
    if ly < self.y then return end

    love.graphics.setColor(self.colors[data[1]])
    love.graphics.printf(data[2], lx, ly, lw, "left")
    index = index + 1
  end

  if original_font then love.graphics.setFont(original_font) end
	love.graphics.setColor(original_color)
end

function console.mousepressed(self, x, y, button )
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
  table.insert(self.buffer, {level, " - "..msg})
  self.buffer_length = self.buffer_length + 1
  if self.current_line > 1 then self.current_line = self.current_line + 1 end
end

function console.i(self, msg) log(self, "INF", msg) end
function console.d(self, msg) log(self, "DBG", msg) end
function console.w(self, msg) log(self, "WRN", msg) end
function console.e(self, msg)	log(self, "ERR", msg) end

return console