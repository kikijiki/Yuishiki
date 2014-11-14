local Animation

return function(loader)
  if Animation then return Animation end

  local vec = loader.require "vector"

  Animation = loader.class("Animation")

  function Animation.static.parseUnidirectional(a, data, ss)
    for _,v in pairs(data.frames) do
      local f = {}
      f.dt = v.dt / 1000

      local src = ss:getFrame(v[1])
      f.source = src
      f.quad = src.quad
      f.center = src.center

      table.insert(a.frames, f)
    end
    a.length = #a.frames
  end

  function Animation.static.parseDirection(a, f, v, ss, dir)
    local frame = {}

    if v[dir] then
      local src = ss:getFrame(v[dir])
      frame.source = src
      frame.quad = src.quad
      frame.center = src.center
      frame.tags = {}

      for k,tag in pairs(src.tags) do
        if tag.left then
          frame.tags[k] = {
            left = {
              z = tag.left.z,
              position = tag.left.position - frame.center
            },
            right = {
              z = tag.right.z,
              position = tag.right.position - frame.center
            }
          }
        else
          frame.tags[k] = {
            z = tag.z,
            position = tag.position - frame.center
          }
        end
      end
    else
      local mdir =
        assert(a.mirror and a.mirror[dir], "Direction "..dir.." is missing.")
      assert(v[mdir], "Mirrored direction "..mdir.." is missing.")

      local src = ss:getFrame(v[mdir])
      frame.mirror = true
      frame.source = src
      frame.quad = src.quad
      frame.center = src.center
      frame.tags = {}

      for k,tag in pairs(src.tags) do
        if tag.left then
          frame.tags[k] = {
            right = {
              z = tag.left.z,
              position = vec(
                frame.center.x - tag.left.position.x,
                tag.left.position.y - frame.center.y)
            },
            left = {
              z = tag.right.z,
              position = vec(
                frame.center.x - tag.right.position.x,
                tag.right.position.y - frame.center.y)
            }
          }
        else
          frame.tags[k] = {
            z = tag.z,
            position = vec(
              frame.center.x - tag.position.x,
              tag.position.y - frame.center.y)
          }
        end
      end
    end

    f[dir] = frame
  end

  function Animation.static.parseMultidirectional(a, data, ss)
    for _,v in pairs(data.frames) do
      local f = {}
      f.dt = v.dt / 1000
      Animation.parseDirection(a, f, v, ss, "NE")
      Animation.parseDirection(a, f, v, ss, "NW")
      Animation.parseDirection(a, f, v, ss, "SE")
      Animation.parseDirection(a, f, v, ss, "SW")
      table.insert(a.frames, f)
    end
    a.length = #a.frames
  end

  local function step(a, dt)
    a.elapsed = a.elapsed + dt

    local nextframe = a.frames[a.index].dt
    while a.elapsed > nextframe do
      a.elapsed = a.elapsed - nextframe
      a.index = a.index + 1
      if a.index > a.length then
        if a.loops > 0 then
          if a.loop_count < a.loops then
            a.index = 1
            a.loop_count = a.loop_count + 1
          end
          if a.loop_count >= a.loops then
            a.index = a.length
            a.paused = true
          end
        else
          a.loop_count = a.loop_count + 1
          a.index = 1
        end
      end

      if a.tags and a.callbacks then
        for tag, callback in pairs(a.callbacks) do
          local cindex = a.tags[tag]
          if cindex and cindex == a.index then
            callback()
          end
        end
      end

      nextframe = a.frames[a.index].dt
    end
  end

  local function getCurrentFrame(a, direction)
    if direction then return a.frames[a.index][direction]
    else return a.frames[a.index] end
  end

  function Animation.static.updateState(self, dt, direction)
    if self.paused then return getCurrentFrame(self, direction) end

    local frames = self.frames
    local length = self.length
    local index = self.index

    if length <= 1 and frames[index].dt <= 0 then
      return getCurrentFrame(self, direction)
    end

    step(self, dt)
    return getCurrentFrame(self, direction)
  end

  function Animation.static.updateStateless(self, dt, elapsed, index, direction)
    local frames = self.frames
    local length = self.length

    elapsed = elapsed + dt
    local nextframe = frames[index].dt

    if nextframe > 0 and length > 1 then
      while elapsed > nextframe do
        elapsed = elapsed - nextframe
        index = index + 1
        if index > length then index = 1 end
        nextframe = frames[index].dt
      end
    end

    if direction then return elapsed, index, frames[index][direction]
    else return elapsed, index, frames[index] end
  end

  function Animation:initialize(directions)
    self.directions = directions or false
    self.frames = {}
    self.callbacks = {}
  end

  function Animation.static.parse(name, data, ss, stateless)
    local a = Animation(data.directions)

    a.name = name
    a.height = data.height
    a.mirror = data.mirror
    a.loops = data.loops or -1
    a.loop_count = 0
    a.paused = false
    a.tags = data.tags

    if a.directions then
      Animation.parseMultidirectional(a, data, ss)
    else
      Animation.parseUnidirectional(a, data, ss)
    end

    if stateless then
      a.update = Animation.updateStateless
    else
      a.update = Animation.updateState
      a.index = 1
      a.elapsed = 0
    end

    return a
  end

  function Animation:pause()
    self.paused = true
  end

  function Animation:play()
    self.paused = false
  end

  function Animation:getFrame(index, direction)
    if direction then return self.frames[index]
    else return self.frames[index][direction] end
  end

  function Animation:reset()
    self.index = 1
    self.elapsed = 0
    self.loop_count = 0
    self.paused = false
  end

  function Animation:callOnTag(tag, callback)
    if not callback then return end
    self.callbacks[tag] = callback
  end

  function Animation:clearTags()
    self.callbacks = {}
  end

  return Animation
end
