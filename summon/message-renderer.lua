local MessageRenderer

return function(loader)
  if MessageRenderer then return MessageRenderer end

  local sg = loader.require "graphics"
  local sp = loader.require "physics"
  local vec = loader.require "vector"
  local split = loader.load("uti").split
  local AssetLoader = loader.load "asset-loader"

  MessageRenderer = loader.class("MessageRenderer")

  function MessageRenderer:initialize(mfont, msize, bfont, bsize, camera)
    self.speech = {
      fontsize = msize or 28,
      fontname = mfont or "ipamp.ttf",
      interline = 1,
      border = 4,
      padding = 8,
      arrow = {
        height = 20,
        offset = 10,
        left = 20,
        right = 60},
      color = {
        text = {0, 0, 0, 255},
        background = {255, 255, 255, 200},
        border = {50, 50, 50, 255}},
      queues = {}
    }
    self.speech.font = AssetLoader.load(
      "font", self.speech.fontname.."@"..self.speech.fontsize)

    self.bubbling = {
      fontsize = bsize or 40,
      fontname = bfont or "ipamp.ttf",
      bubbles = {}
    }
    self.bubbling.font = AssetLoader.load(
      "font", self.bubbling.fontname.."@"..self.bubbling.fontsize)

    self.camera = camera

    sp.setMeter(100)
    self.world = sp.newWorld(0, 1000, true)
  end

  function MessageRenderer:update(dt)
  self.world:update(dt)

  self:updateSpeech(dt)
  self:updateBubbles(dt)
  end

  function MessageRenderer:draw()
    self:drawSpeech()
    self:drawBubbles()
    sg.setColor(255, 255, 255)
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

        position = self.camera:gameToScreen(position)
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
local ba = false
  function MessageRenderer:bubble(id, message, position, direction, color)
    local b = self.bubbling
    local width = b.font:getWidth(message)
    directon = direction or 0

    local col = color or {255, 255, 255, 255}
    if not col[4] then col[4] = 255 end

    position.x = position.x - (width / 2) * (1 - direction)
    position.y = position.y - b.fontsize

    local body = sp.newBody(self.world, position.x, position.y, "dynamic")
    local shape = sp.newRectangleShape(width, b.fontsize)
    local fixture = sp.newFixture(body, shape)

    body:setMass(1)
    body:applyForce(direction * 10000, -30000)

    local cat = math.floor(direction) + 2
    fixture:setCategory(cat)
    if cat ~= 1 then fixture:setMask(1) end
    if cat ~= 2 then fixture:setMask(2) end
    if cat ~= 3 then fixture:setMask(3) end

    table.insert(b.bubbles, {
      message = message,
      size = {width, b.fontsize},
      color = col,
      alpha = 1,
      body = body,
      shape = shape,
      fixture = fixture
    })
  end

  function MessageRenderer:updateBubbles(dt)

  end

  function MessageRenderer:drawBubbles()
    for _,b in pairs(self.bubbling.bubbles) do
      self:drawBubble(b)
    end
  end

  function MessageRenderer:drawBubble(b)
    local c = b.color
    self.bubbling.font:apply()
    local posx, posy = b.body:getWorldPoints(b.shape:getPoints())
    sg.setColor(0, 0, 0, 255 * b.alpha)
    sg.print(b.message, posx - 2, posy - 2, b.body:getAngle())
    sg.print(b.message, posx - 2, posy + 2, b.body:getAngle())
    sg.print(b.message, posx + 2, posy + 2, b.body:getAngle())
    sg.print(b.message, posx + 2, posy - 2, b.body:getAngle())
    sg.setColor(c[1], c[2], c[3], c[4] * b.alpha)
    sg.print(b.message, posx, posy, b.body:getAngle())
  end

  return MessageRenderer
end
