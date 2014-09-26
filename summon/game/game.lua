local Game = {}

local Camera, World, SpriteBatch, SpeechRenderer

function Game.initialize(ruleset)
  Camera = summon.graphics.Camera
  World = summon.game.World
  SpriteBatch = summon.graphics.sprite.SpriteBatch
  SpeechRenderer = summon.graphics.SpeechRenderer

  Game.camera = Camera()
  Game.world = World("r0")
end

function Game.update(dt)
  Game.camera:update(dt)
  Game.world:update(dt)
  SpeechRenderer.update(dt)
end

function Game.draw()
  SpriteBatch.clear()
  Game.camera:begin()
  
  Game.world:draw()
  
  SpriteBatch.draw()
  Game.camera:finish()
  
  SpeechRenderer.draw(Game.camera)
end

return Game