local Camera

return function(loader)
  if Camera then return Camera end

  local sg  = loader.require "graphics"
  local vec = loader.require "vector"
  local push, translate, scale, pop = sg.push, sg.translate, sg.scale, sg.pop
  local getWidth, getHeight = sg.getWidth, sg.getHeight

  Camera = loader.class("Camera")

  function Camera:initialize()
    self._scale         = 1
    self.center         = vec(0, 0)
    self.speed          = 10
    self.scalespeed     = 10
    self.tolerance      = 1
    self.scaletolerance = 0.01
    self.vp             = vec(0, 0)
    self.vp2            = vec(0, 0)
    self.max_scale      = 10;
    self.min_scale      = 1/5;
    self.scale          = 1
    self.target         = vec(0, 0)
    self.drag           = { active = false, x = 0, y = 0 }
  end

  function Camera:resize(w, h)
    self.vp  = vec(w, h)
    self.vp2 = vec(w / 2, h / 2)
  end

  function Camera:begin()
    push()
    translate(self.vp2.x, self.vp2.y)
    scale(self._scale, self._scale)
    translate(self.center:unpack())
  end

  function Camera:getTarget()
    if type(self.target) == "function" then return self.target() end
    if self.target.getTag then
      if self.target:getTag("camera") then return self.target:getTag("camera") end
      if self.target:getTag("head") then return self.target:getTag("head") end
    end
    if self.target.getPosition then return self.target:getPosition() end
    return self.target
  end

  function Camera:zoom(factor)
    local newscale = self.scale * factor
    if newscale > self.min_scale and newscale < self.max_scale then
      self.scale = newscale
    end
  end

  function Camera:zoomIn()
    self:zoom(1.2)
  end

  function Camera:zoomOut()
    self:zoom(1/1.2)
  end

  function Camera:follow(target)
    self.target = target
  end

  function Camera:unfollow()
    local pos = self:getTarget()
    self:follow(pos)
  end

  function Camera:move(d)
    self:unfollow()
    self.target = self.target + d
  end

  function Camera:update(dt, mouse)
    local cnt = -self.center
    local trg = self:getTarget()

    local diff = trg - cnt
    local len = diff:len()

    if len * self._scale < self.tolerance then
      cnt = trg
    else
      cnt = cnt + diff * math.min(1, self.speed * dt)
    end

    self.center = -cnt

    diff = self.scale - self._scale
    if math.abs(diff) / self.scale < self.scaletolerance then
      self._scale = self.scale
    else
      self._scale = self._scale + diff * math.min(1, self.scalespeed * dt)
    end

    if mouse then
      self:updateDrag(mouse)
    end
  end

  function Camera:finish()
    pop()
  end

  function Camera:screenToGame(v)
    return (v - self.vp2) / self._scale - self.center
  end

  function Camera:gameToScreen(v)
    return self._scale * (v + self.center) + self.vp2
  end

  function Camera:startDrag(mouse)
    if not self.drag.active then
      self.drag.active = true
      self.drag.x = mouse.x
      self.drag.y = mouse.y
    end
  end

  function Camera:stopDrag()
    self.drag.active = false
  end

  function Camera:updateDrag(mouse)
    if self.drag.active then
      local s = self.scale
      local dx = mouse.x - self.drag.x
      local dy = mouse.y - self.drag.y
      self:move(vec(-dx / s, -dy / s))
      self.drag.x = mouse.x
      self.drag.y = mouse.y
    end
  end

  return Camera
end
