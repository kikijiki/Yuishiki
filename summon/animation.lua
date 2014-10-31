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
      local mdir = assert(a.mirror and a.mirror[dir], "Direction "..dir.." is missing.")
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

  function Animation.static.updateState(self, dt, direction)
    local frames = self.frames
    local length = self.length
    local elapsed = self.elapsed
    local index = self.index

    if self.paused then
      if direction then return frames[index][direction]
      else return frames[index] end
    end

    elapsed = elapsed + dt
    local nextframe = frames[index].dt

    if nextframe > 0 then
      while elapsed > nextframe do
        elapsed = elapsed - nextframe
        index = index + 1
        if index > length then
          if self.loop > 0 then
            if self.loops < self.loop then
              index = 1
              self.loops = self.loops + 1
              if self.loops == self.loop then
                index = length
                self.paused = true
              end
            end
          else
            index = 1
          end
        end
        if self.tags and self.callback then
          for tag, callback in pairs(self.callbacks) do
            local cindex = self.tags[tag]
            if cindex and cindex == index then
              callback()
            end
          end
        end
        if index and index <= #frames then
          nextframe = frames[index].dt
        end
      end
    end

    self.index = index
    self.elapsed = elapsed

    if index > length then index = length end

    if direction then return frames[index][direction]
    else return frames[index] end
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
  end

  function Animation.static.parse(name, data, ss, stateless)
    local a = Animation(data.directions)

    a.name = name
    a.height = data.height
    a.mirror = data.mirror
    a.loop = data.loop or -1
    a.loops = 0
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
    self.loops = 0
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
