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
    local top = self.states:top()
    if state.onPush then state:onPush(self, top) end
    self.states:push(state)
    if state and state.onResume then state:onResume() end
  end

  function Game:pop()
    local state = self.states:pop()
    local top = self.states:top()
    if state.onPop then state:onPop(self, top) end
    if not top then return end
    if top.resize then top:resize() end
    if top.onResume then top:onResume() end
  end

  return Game
end
