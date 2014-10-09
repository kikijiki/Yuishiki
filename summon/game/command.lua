assert(summon, "SUMMON is not loaded.")

local vec = summon.vec

--[[Commands list

- Idle       Do nothing and use the idle animation.
- Turn       Change direction.
- Animation  Change animation.
- Wait       Let time pass.
- Speak      Produce a speech bubble.
- Translate  Move linearly.
- Walk       Look towards the destination, use the walk animation and move.
- Jump       Look to the destination and jump using the jump animation.
- Step       Walk to an adjacent tile in a certain direction.
]]

--[[COMMAND BASE CLASS]]--

local Command = summon.class("Command")
local export = {}

function Command:initialize(name)
  self.name = name
  self.status = "inactive"
  self.elapsed = 0
end

function Command:bind(character, callback)
  self.character = character
  self.sprite = character.sprite
  self.callback = callback
end

function Command:push(command, callback)
  self.character:pushCommand(command, callback)
end

function Command:pop()
  self.character:popCommand()
end

function Command:append()
  self.character:appendCommand(command, callback)
end

function Command:execute()
  self.status = "executing"
end

function Command:update(dt)
  self.elapsed = self.elapsed + dt
end

function Command:finish()
  if self.callback then self.callback(self.sprite) end
  self.status = "finished"
end

function Command:onPop()
end

export.class = Command

--[[CONCRETE COMMANDS]]--

--[[Idle]]---------------------------------------------------------------------
local IdleCommand = summon.class("IdleCommand", Command)

function IdleCommand:initialize()
  Command.initialize(self, "Idle")
end

function IdleCommand:execute()
  Command.execute(self)
  self.sprite:setAnimation("idle")
  self:finish()
end

export.IdleCommand = IdleCommand

--[[Turn]]---------------------------------------------------------------------
local TurnCommand = summon.class("TurnCommand", Command)

function TurnCommand:initialize(direction)
  Command.initialize(self, "Turn")
  self.direction = direction
end

function TurnCommand:execute()
  Command.execute(self)
  self.sprite:setDirection(self.direction)
  self:finish()
end

export.TurnCommand = TurnCommand

--[[Animation]]----------------------------------------------------------------
local AnimationCommand = summon.class("AnimationCommand", Command)

function AnimationCommand:initialize(animation)
  Command.initialize(self, "Animation")
  self.animation = animation
end

function AnimationCommand:execute()
  Command.execute(self)
  self.sprite:setAnimation(self.animation)
  self:finish()
end

export.AnimationCommand = AnimationCommand

--[[Wait]]---------------------------------------------------------------------
local WaitCommand = summon.class("WaitCommand", Command)

function WaitCommand:initialize(time)
  Command.initialize(self, "Wait")
  self.time = time
end

function WaitCommand:execute()
  Command.execute(self)
end

function WaitCommand:update(dt)
  Command.update(self, dt)
  if self.elapsed > self.wait then
    self:finish()
    return self.elapsed - self.wait
  end
end

export.WaitCommand = WaitCommand

--[[Speak]]--------------------------------------------------------------------
local SpeakCommand = summon.class("SpeakCommand", Command)

function SpeakCommand:initialize(message, duration)
  Command.initialize(self, "Speak")
  self.message = message
  self.duration = duration
end

function SpeakCommand:execute()
  Command.execute(self)
  summon.speechRenderer.add(self.sprite, self.message, self.duration, self.sprite.getSpeakPoint)
  self:finish()
end

export.SpeakCommand = SpeakCommand

--[[Translate]]----------------------------------------------------------------

local TranslateCommand = summon.class("TranslateCommand", Command)

function TranslateCommand:initialize(destination, z, speed)
  Command.initialize(self, "Translate")

  self.destination = {pos = destination, z = z}
  self.speed = speed
  self.progress = 0
end

function TranslateCommand:execute()
  Command.execute(self)

  local diff = self.destination.pos - self.sprite.position

  self.distance = diff:len()
  self.duration = self.distance / self.speed
  self.versor = diff:normalize_inplace()

  if self.destination.z then self.sprite.z = math.min(self.destination.z, self.sprite.z) end
end

function TranslateCommand:update(dt)
  Command.update(self, dt)

  local d = dt * self.speed
  self.progress = self.progress + d

  if self.progress > self.distance then
    self.sprite:setPosition(self.destination.pos, self.destination.z)
    self:finish()
    return (self.progress - self.distance) / self.speed
  else
    self.sprite:move(self.versor * d)
  end
end

export.TranslateCommand = TranslateCommand

--[[Walk]]---------------------------------------------------------------------

local WalkCommand = summon.class("WalkCommand", Command)

function WalkCommand:initialize(destination, map)
  Command.initialize(self, "Walk")
  self.destination = destination
  self.map = map
end

function WalkCommand:execute()
  Command.execute(self)

  local sprite = self.sprite

  if not self.map:containsTile(self.destination) then
    self:finish()
    return
  end

  local data = self.map:getTilePixelCoordinates(self.destination)

  self:push(TranslateCommand(data.top, data.spriteZ, sprite.speed.movement))

  sprite:setAnimation("walk", false)
  sprite:setDirection(self.map:getFacingDirection(self.character.status.position:get(), self.destination))
  self:finish()
end

function WalkCommand:onPop()
  self.character.status.position:set(self.destination)
  --self.sprite:setAnimation("idle", false)
end

export.WalkCommand = WalkCommand

--[[Jump]]---------------------------------------------------------------------

local JumpCommand = summon.class("JumpCommand", Command)

function JumpCommand:initialize(destination, map, jumpFactor)
  Command.initialize(self, "Jump")
  self.destination = destination
  self.map = map
  self.jumpFactor = jumpFactor
  self.progress = 0
end

function JumpCommand:execute()
  Command.execute(self)

  if not self.map:containsTile(self.destination) then
    self:finish()
    return
  end

  if self.destination == self.character.status.position then
    self:finish()
    return
  end

  local from = self.map:getTilePixelCoordinates(self.character.status.position:get())
  local to = self.map:getTilePixelCoordinates(self.destination)
  local h = to.height - from.height

  local dstbase = to.top + vec(0, h)
  local diff = dstbase - from.top
  self.from = from
  self.to = to
  self.distance = diff:len()
  self.versor = diff:normalize_inplace()

  local j = math.max(h * 1.2, self.jumpFactor * math.sqrt(h*h + self.distance * self.distance))
  self.a = -2 * math.sqrt(j*(j-h)) + h - 2 * j -- magic
  self.b = h - self.a

  local g = 1000
  self.duration = math.sqrt((4*j - h)/g) -- more magic

  self.speed = self.distance / self.duration

  self.sprite:setAnimation("jump")
  self.sprite:setDirection(self.map:getFacingDirection(self.character.status.position:get(), self.destination))
end

function JumpCommand:update(dt)
  Command.update(self, dt)
  local sprite = self.sprite

  self.progress = self.elapsed * self.speed

  if self.progress > self.distance / 2 then
    sprite.z = self.to.spriteZ
  end

  if self.progress > self.distance then
    self:finish()
    return (self.progress - self.distance) / self.speed
  else
    local x = self.progress / self.distance
    local y = x^2 * self.a + x * self.b
    local tra = self.versor * self.progress + self.from.top

    tra.y = tra.y - y
    self.sprite:setPosition(tra)
  end
end

function JumpCommand:onPop()
  self.sprite:setPosition(self.to.top, self.to.spriteZ)
  self.character.status.position:set(self.destination)
end

export.JumpCommand = JumpCommand

--[[Step]]---------------------------------------------------------------------

local StepCommand = summon.class("StepCommand", Command)

function StepCommand:initialize(destination, map, duration, jumpFactor)
  Command.initialize(self, "Step")
  self.destination = destination
  self.map = map
  self.duration = duration
  self.jumpFactor = jumpFactor
end

function StepCommand:execute()
  Command.execute(self)

  if type(self.destination) == "string" then
    self.destination = self.map.directions[self.destination] + self.character.status.position:get()
  end
  if not self.map:containsTile(self.destination) then
    self:finish()
    return
  end

  local from = self.map:getTilePixelCoordinates(self.character.status.position:get())
  local to = self.map:getTilePixelCoordinates(self.destination)

  if from.heightM == to.heightM then
    self:push(WalkCommand(self.destination, self.map))
  else
    self:push(JumpCommand(self.destination, self.map, self.duration or 0.5, self.jumpFactor or 0.8))
  end

  self:finish()
end

function StepCommand:onPop()
  self.sprite:setAnimation("idle", false)
end

export.StepCommand = StepCommand

--[[Module export]]--

return export
