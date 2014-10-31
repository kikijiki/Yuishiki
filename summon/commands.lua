local Commands

return function(loader)
  if Commands then return Commands end
  Commands = {}

  local vec = loader.require "vector"

--[[Commands list

- Wait       Wait.
- Turn       Change direction.
- LookAt     Change direction.
- Animation  Change animation.
- Wait       Let time pass.
- Speak      Produce a speech bubble.
- Translate  Move linearly.
- Walk       Look towards the destination, use the walk animation and move.
- Jump       Look to the destination and jump using the jump animation.
- Step       Walk to an adjacent tile in a certain direction.
- Fade       Lerp on alpha.
]]

  Commands.wait = function(delay, f)
    return function(dt, char)
      local elapsed = dt
      while elapsed < delay do
        elapsed = elapsed + coroutine.yield()
      end
      if f then f() end
      return elapsed - delay
    end
  end

  Commands.turn = function(direction)
    return function(dt, char)
      char.sprite:setDirection(direction)
      return dt
    end
  end

  Commands.lookAt = function(target)
    return function(dt, char)
      local direction = char.world.map:getFacingDirection(
        char.status.position:get(),
        target.status.position:get())
        char.sprite:setDirection(direction)
    end
  end

  Commands.animation = function(animation, param)
    return function(dt, char)
      local reset = not param or param.reset ~= false
      local idle = not (param and param.idle == false)

      local ani = char.sprite:setAnimation(animation, reset)
      local skip = (param and param.skip) or ani.loops < 0

      if not ani then return dt end

      if param and param.tags then
        for tag, callback in pairs(param.tags) do
          char.sprite:callOnTag(tag, callback)
        end
      end

      if skip then return dt end

      while not char.sprite:paused() do
        coroutine.yield()
      end

      char.sprite:clearTags()
      if idle then char.sprite:setAnimation("idle") end
    end
  end

  Commands.speak = function(message, duration)
    return function(dt, char)
      char:speak(message, duration)
      return dt
    end
  end

  Commands.translate = function (destination, z, speed)
    return function(dt, char)
      local progress = 0
      local diff = destination - char.sprite.position

      local distance = diff:len()
      local duration = distance / speed
      local versor = diff:normalize_inplace()

      if z then char.sprite.z = math.min(z, char.sprite.z) end

      local d = dt * self.speed
      progress = progress + d

      if progress > distance then
        char.sprite:setPosition(destination, z)
        return (progress - distance) / speed
      else
        char.sprite:move(versor * d)
        dt = coroutine.yield()
      end
    end
  end

  Commands.walk = function(destination)
    return function(dt, char)
      local sprite = char.sprite
      local map = char.world.map

      if not map:containsTile(destination) then return end
      local data = map:getTilePixelCoordinates(destination)

      sprite:setAnimation("walk", {reset = false})
      sprite:setDirection(map:getFacingDirection(char.status.position:get(), destination))

      dt = char:pushCommand(Commands.translate(data.top, data.spriteZ, sprite.speed.movement))
      coroutine.yield()

      char.status.position:set(destination)
      return dt
    end
  end

  Commands.jump = function(destination, jumpFactor)
    return function(dt, char)
      local map = char.world.map

      if not map:containsTile(destination) then return end
      if destination == char.status.position then return end

      local from = map:getTilePixelCoordinates(char.status.position:get())
      local to = map:getTilePixelCoordinates(destination)
      local h = to.height - from.height
      local dstbase = to.top + vec(0, h)
      local diff = dstbase - from.top
      local dist = diff:len()
      local versor = diff:normalize_inplace()
      local j = math.max(h * 1.2, jumpFactor * math.sqrt(h*h + dist * dist))
      local g = 1000
      local a = -2 * math.sqrt(j*(j-h)) + h - 2 * j -- magic
      local b = h - a
      local duration = math.sqrt((4*j - h)/g) -- more magic
      local speed = dist / duration

      sprite:setAnimation("jump")
      sprite:setDirection(
        map:getFacingDirection(char.status.position:get(), destination))

      local progress = 0
      local elapsed = dt
      while progress < distance do
        progress = elapsed * speed
        if progress > distance / 2 then sprite.z = to.spriteZ end

        local x = progress / distance
        local y = x^2 * a + x * b
        local tra = versor * progress + from.top
        sprite:setPosition(tra)
        elapsed = elapsed + coroutine.yield()
      end

      sprite:setPosition(to.top, to.z)
      char.status.position:set(destination)
      return (progress - distance) / speed
    end
  end

  Commands.step = function(destination, duration, jumpFactor)
    return function(dt, char)
      local map = char.world.map

      if type(destination) == "string" then
        destination = map.directions[destination] + char.status.position:get()
      end
      if not map:containsTile(destination) then return dt end

      local from = map:getTilePixelCoordinates(char.status.position:get())
      local to = map:getTilePixelCoordinates(destination)

      if from.heightM == to.heightM then
        dt = char:pushCommand(command.walk(destination))
      else
        dt = char:pushCommand(
          command.jump(destination,
          duration or 0.5,
          jumpFactor or 0.8))
      end

      char.sprite:setAnimation("idle", {wait = false})
      return dt
    end
  end

  Commands.fade = function(duration, to, from)
    return function(dt, char)
      duration = duration or 1
      to = to or 0
      from = from or char.sprite.alpha
      local elapsed = dt

      while elapsed < duration do
        char.sprite.alpha = from + (elapsed / duration) * (to - from)
        elapsed = elapsed + coroutine.yield()
      end

      char.sprite.alpha = to

      return elapsed - duration
    end
  end

  return Commands
end
