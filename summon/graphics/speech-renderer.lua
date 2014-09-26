assert(summon, "SUMMON is not loaded.")

local sg  = summon.graphics

local vec = summon.vec
local split = summon.common.uti.split

local SpeechRenderer = {
  fontsize = 28,
  fontname = "ipamp.ttf",
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

--function SpeechRenderer.initialize()
  local font = summon.AssetLoader.load("font", SpeechRenderer.fontname.."@"..SpeechRenderer.fontsize)
  SpeechRenderer.font = font
  --font:apply()
--end

function SpeechRenderer.add(source, content, duration, position)
  local text = split(content, "\n")
  local size = vec(0, (SpeechRenderer.fontsize + SpeechRenderer.interline) * #text - SpeechRenderer.interline)

  for _,v in pairs(text) do size.x = math.max(size.x, SpeechRenderer.font:getWidth(v)) end
  size.x = size.x + 1
  
  local msg = {
    source = source,
    position = position,
    text = text,
    size = size,
    duration = duration}
  
  if not SpeechRenderer.queues[source] then SpeechRenderer.queues[source] = {} end
  table.insert(SpeechRenderer.queues[source], msg)
end

function SpeechRenderer.update(dt)
  for _,queue in pairs(SpeechRenderer.queues) do
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

function SpeechRenderer.draw(camera)
  local pad = SpeechRenderer.padding
  local brd = SpeechRenderer.border
  local brdpad = brd + pad

  for _,queue in pairs(SpeechRenderer.queues) do
    if #queue > 0 then
      local speech = queue[1]
      local size = speech.size
      local position = speech.position
      
      if type(position) == "function" then position = position(speech.source)
      elseif position.getPosition then position = position:getPosition() end
      
      local o = position:clone()
      if camera then o = camera:gameToScreen(o) end
      
      o.x = o.x + SpeechRenderer.arrow.offset
      
      local v = o:clone()
      v.x = v.x + brdpad
      v.y = v.y - size.y - brdpad - SpeechRenderer.arrow.height
      
      local scrw = summon.graphics.getWidth()
      if v.x + size.x > scrw then
        v.x = math.max(brd + pad, scrw - size.x - brdpad) end

      if v.y - brdpad < 0 then v.y =  brdpad end
      
      local cb = v.y + size.y + pad
      local cl = v.x - pad
      local cr = math.max(v.x + pad + size.x, o.x + SpeechRenderer.arrow.right + SpeechRenderer.border)
      local ct = v.y - pad
      local ar, al = SpeechRenderer.arrow.right, SpeechRenderer.arrow.left
      local callout = {
        cl      , ct,
        cr      , ct,
        cr      , cb,
        o.x + ar, cb,
        o.x     , o.y,
        o.x + al, cb,
        cl      , cb
      }
      
      local arrow = {
        o.x + ar, cb,
        o.x     , o.y,
        o.x + al, cb
      }

      sg.setColor(SpeechRenderer.color.background)
      sg.rectangle("fill", cl, ct, cr - cl, cb - ct)
      sg.polygon("fill", arrow)
      
      sg.setColor(SpeechRenderer.color.border)
      sg.setLineWidth(brd)
      sg.polygon("line", callout)
      
      sg.setColor(SpeechRenderer.color.text)
      SpeechRenderer.font:apply()
      for _,line in pairs(speech.text) do
        sg.printf(line, v.x, v.y, size.x, "center")
        v.y = v.y + SpeechRenderer.interline + SpeechRenderer.fontsize
      end
    end    
  end
end

return SpeechRenderer