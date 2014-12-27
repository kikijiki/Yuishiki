local MessageRenderer

return function(loader)
  if MessageRenderer then return MessageRenderer end

  local sg          = loader.require "graphics"
  local sp          = loader.require "physics"
  local vec         = loader.require "vector"
  local uti         = loader.load "uti"
  local AssetLoader = loader.load "asset-loader"

  MessageRenderer = loader.class("MessageRenderer")

  function MessageRenderer:initialize(mfont, msize, bfont, bsize, camera)
    self.locale = "en"

    self.dialog_data = {
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
    self.dialog_data.font = AssetLoader.load(
      "font", self.dialog_data.fontname.."@"..self.dialog_data.fontsize)

    self.bubble_data = {
      fontsize = bsize or 40,
      fontname = bfont or "ipamp.ttf",
      bubbles = {}
    }
    self.bubble_data.font = AssetLoader.load(
      "font", self.bubble_data.fontname.."@"..self.bubble_data.fontsize)

    self.camera = camera

    sp.setMeter(100)
    self.world = sp.newWorld(0, 1000, true)
  end

  function MessageRenderer:setLocale(locale)
    self.locale = locale
  end

  function MessageRenderer:update(dt)
  self.world:update(dt)

  self:updateDialogs(dt)
  self:updateBubbles(dt)
  end

  function MessageRenderer:draw()
    self:drawDialogs()
    self:drawBubbles()
    sg.setColor(255, 255, 255)
  end

  function getLocalizedText(data, locale)
    if type(data) == "table" then
      if data[locale] then return data[locale]
      elseif data["en"] then return data["en"]
      elseif select(2, next(data)) then return select(2, next(data))
      else return "" end
    else
      return data
    end
  end

  local function getPosition(position, source, camera)
    local p
    if type(position) == "function" then
      p = position(source)
    elseif position.getPosition then
      p = position:getPosition()
    else
      p = position
    end

    return camera:gameToScreen(p)
  end

  function MessageRenderer:dialog(source, content, duration, position)
    local s = self.dialog_data

    text = uti.lines(getLocalizedText(content, self.locale))

    local size = vec(0, (s.fontsize + s.interline) * #text - s.interline)

    for _,v in pairs(text) do size.x = math.max(size.x, s.font:getWidth(v)) end
    size.x = size.x + 1

    if not duration then duration = #text end

    local msg = {
      source = source,
      position = position,
      current_pos = getPosition(position, source, self.camera),
      text = text,
      size = size,
      duration = duration}

    if not s.queues[source] then s.queues[source] = {} end
    table.insert(s.queues[source], msg)
  end

  function MessageRenderer:updateDialogs(dt)
    local s = self.dialog_data
    for _,queue in pairs(s.queues) do
      local t = dt
      local dialog
      while t > 0 and #queue > 0 do
        dialog = queue[1]
        if dialog.duration < t then
          t = t - dialog.duration
          table.remove(queue, 1)
        else
          dialog.duration = dialog.duration - t
          t = -1
        end
      end
      if dialog then
        local position = getPosition(dialog.position, dialog.source, self.camera)
        local diff = position - dialog.current_pos
        if diff:len() < 2 then
          dialog.current_pos.x = position.x
          dialog.current_pos.y = position.y
        else
          dialog.current_pos = dialog.current_pos + diff * dt * 10
        end
      end
    end
  end

  function MessageRenderer:drawDialogs()
    local s = self.dialog_data
    local pad = s.padding
    local brd = s.border
    local brdpad = brd + pad
    s.font:apply()

    for _,queue in pairs(s.queues) do
      if #queue > 0 then
        local dialog = queue[1]
        local size = dialog.size

        local o = dialog.current_pos:clone()

        o.x = o.x + s.arrow.offset

        local v = o:clone()
        v.x = v.x + brdpad
        v.y = v.y - size.y - brdpad - s.arrow.height

        local cb = v.y + size.y + pad
        local cl = v.x - pad
        local cr = math.max(v.x + pad + size.x, o.x + s.arrow.right + s.border)
        local ct = v.y - pad
        local ar, al = s.arrow.right, s.arrow.left
        local rect = {
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
        sg.polygon("line", rect)

        sg.setColor(s.color.text)

        for _,line in pairs(dialog.text) do
          sg.printf(line, v.x, v.y, size.x, "center")
          v.y = v.y + s.interline + s.fontsize
        end
      end
    end
  end

  function MessageRenderer:bubble(id, message, position, direction, color)
    local b = self.bubble_data
    message = getLocalizedText(message, self.locale)
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
    for i = #self.bubble_data.bubbles, 1, -1 do
      local b = self.bubble_data.bubbles[i]
      local posx, posy = b.body:getWorldPoints(b.shape:getPoints())
      if posy > self.camera.vp.y then
        table.remove(self.bubble_data.bubbles, i)
      end
    end
  end

  function MessageRenderer:drawBubbles()
    for _,b in pairs(self.bubble_data.bubbles) do
      self:drawBubble(b)
    end
  end

  function MessageRenderer:drawBubble(b)
    local c = b.color
    self.bubble_data.font:apply()
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
