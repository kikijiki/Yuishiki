local Game

return function(loader)
  if Game then return Game end

  local Stack = loader.load "stack"

  Game = loader.class("Game")

  function Game:initialize()
    self.states = Stack()
    self.on = setmetatable({}, {
      __index = function(t, k)
        return function(...)
          local top = self.states:top()
          if top and top[k] then top[k](top, ...) end
        end
      end
    })
  end

  function Game:push(state)
    state.game = self
    self.states:push(state)
    if state and state.onResume then state:onResume() end
  end

  function Game:pop()
    self.states:pop()
    local top = self.states:top()
    if top and top.onResume then top:onResume() end
  end

  return Game
end
