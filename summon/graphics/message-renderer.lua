assert(summon, "SUMMON is not loaded.")

local sg  = summon.graphics

local vec = summon.vec
local split = summon.common.uti.split

local MessageRenderer = summon.class("MessageRenderer")

function MessageRenderer:initialize(font, size)
  self.speech = {
    fontsize = size or 28,
    fontname = font or "ipamp.ttf",
    interline = 1,
    border = 4,
    padding = 8,
    arrow = {
      height = 20,
      offset = 10,
      left = 20,
      right = 60},
    color = {
      text = {255, 255, 255, 255},
      background = {100, 100, 100, 200},
      border = {200, 200, 200, 255}},
    queues = {}
  }
  self.speech.font = summon.AssetLoader.load(
    "font", self.speech.fontname.."@"..self.speech.fontsize)

  self.bubbling = {
    fontsize = size or 40,
    fontname = font or "ipamp.ttf",
    top = 200,
    fadeout = 50,
    speed = 250,
    jitter = 50,
    bubbles = {}
  }
  self.bubbling.font = summon.AssetLoader.load(
    "font", self.bubbling.fontname.."@"..self.bubbling.fontsize)

end

function MessageRenderer:update(dt)
self:updateSpeech(dt)
self:updateBubbles(dt)
end

function MessageRenderer:draw()
  self:drawSpeech()
  self:drawBubbles()
end

function MessageRenderer:speak(source, content, duration, position)
  local s = self.speech
  local text = split(content, "\n")
  local size = vec(0, (s.fontsize + s.interline) * #text - s.interline)

  for _,v in pairs(text) do size.x = math.max(size.x, s.font:getWidth(v)) end
  size.x = size.x + 1

  local msg = {
    source = source,
    position = position,
    text = text,
    size = size,
    duration = duration}

  if not s.queues[source] then s.queues[source] = {} end
  table.insert(s.queues[source], msg)
end

function MessageRenderer:updateSpeech(dt)
  local s = self.speech
  for _,queue in pairs(s.queues) do
    local t = dt
    while t > 0 and #queue > 0 do
      local speech = queue[1]
      if speech.duration < t then
        t = t - speech.duration
        table.remove(queue, 1)
      else
        speech.duration = speech.duration - t
        t = -1
      end
    end
  end
end

function MessageRenderer:drawSpeech()
  local s = self.speech
  local pad = s.padding
  local brd = s.border
  local brdpad = brd + pad
  s.font:apply()

  for _,queue in pairs(s.queues) do
    if #queue > 0 then
      local speech = queue[1]
      local size = speech.size
      local position = speech.position

      if type(position) == "function" then position = position(speech.source)
      elseif position.getPosition then position = position:getPosition() end

      local o = position:clone()

      o.x = o.x + s.arrow.offset

      local v = o:clone()
      v.x = v.x + brdpad
      v.y = v.y - size.y - brdpad - s.arrow.height

      local cb = v.y + size.y + pad
      local cl = v.x - pad
      local cr = math.max(v.x + pad + size.x, o.x + s.arrow.right + s.border)
      local ct = v.y - pad
      local ar, al = s.arrow.right, s.arrow.left
      local callout = {
        cl      , ct,  -- left top corner
        cr      , ct,  -- right top corner
        cr      , cb,  -- right bottom corner
        o.x + ar, cb,  -- right arrow corner
        o.x     , o.y, -- arrow point
        o.x + al, cb,  -- left arrow corner
        cl      , cb   -- left bottom corner
      }

      local arrow = {
        o.x + ar, cb,
        o.x     , o.y,
        o.x + al, cb
      }

      sg.setColor(s.color.background)
      sg.rectangle("fill", cl, ct, cr - cl, cb - ct)
      sg.polygon("fill", arrow)

      sg.setColor(s.color.border)
      sg.setLineWidth(brd)
      sg.polygon("line", callout)

      sg.setColor(s.color.text)

      for _,line in pairs(speech.text) do
        sg.printf(line, v.x, v.y, size.x, "center")
        v.y = v.y + s.interline + s.fontsize
      end
    end
  end
end

function MessageRenderer:bubble(sprite, message, position, color)
  local b = self.bubbling
  local width = b.font:getWidth(message)
  if not b.bubbles[sprite] then b.bubbles[sprite] = {} end
  local col = color or {255, 255, 255, 255}
  if not col[4] then col[4] = 255 end
  position.x = position.x + (b.jitter - 2*b.jitter*math.random()) - width / 2
  position.y = position.y - b.fontsize

  table.insert(b.bubbles[sprite], {
    message = message,
    position = position,
    color = col,
    alpha = 1,
    offset = 0})
end

function MessageRenderer:updateBubbles(dt)
  local b = self.bubbling
  for _,s in pairs(b.bubbles) do
    for i = 1, #s do
      local bubble = s[i]
      if not bubble then return end
      bubble.offset = bubble.offset + b.speed * dt
      if bubble.offset > b.top then
        table.remove(s, i)
        i = i - 1
      end
      local remaining = b.top - bubble.offset
      if remaining < b.fadeout then
        bubble.alpha = remaining / b.fadeout
      end
      if bubble.offset < b.fontsize then return end
    end
  end
end

function MessageRenderer:drawBubbles()
  for _,s in pairs(self.bubbling.bubbles) do
    for _,b in pairs(s) do
      if b.offset > 0 then self:drawBubble(b) end
    end
  end
end

function MessageRenderer:drawBubble(b)
  local c = b.color
  sg.setColor(c[1], c[2], c[3], c[4] * b.alpha)
  self.bubbling.font:apply()
  sg.print(b.message, b.position.x, b.position.y - b.offset)
end

return MessageRenderer
