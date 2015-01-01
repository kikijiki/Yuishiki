local Game

return function(loader)
  if Game then return Game end

  local Stack = loader.load "stack"

  Game = loader.class("Game")

  function Game:initialize()
    self.states = Stack()
    self.locales = {}
    self.defaultLocale = "en"
    self.locale = self.defaultLocale
    self.on = setmetatable({}, {
      __index = function(t, k)
        return function(...)
          local top = self.states:top()
          if top and top[k] then top[k](top, ...) end
        end
      end
    })
  end

  function Game:addLocale(locale)
    if type(locale == "table") then
      for _,l in pairs(locale) do table.insert(self.locales, l) end
    else
      table.insert(self.locales, locale)
    end
    self.locale = self.locale or self.locales[1]
  end

  function Game:setLocale(locale)
    if locale then
      for _,v in pairs(self.locales) do
        if v == locale then self.locale = locale end
      end
    else
      local index = 0
      for k,v in pairs(self.locales) do
        if v == self.locale then index = k break end
      end
      index = index + 1
      if index > #self.locales then index = 1 end
      self.locale = self.locales[index]
      return self.locale
    end
  end

  local function localize(s, l, d)
    if type(s) == "table" then
      if s[l] then return s[l]
      elseif s[d] then return s[d]
      elseif next(s, nil) then return select(2, next(s, nil))
      else return "" end
    else
      return s
    end
  end

  function Game:getLocalizedString(s1, s2, ...)
    if s2 then
      local ret = {}
      for _,s in pairs({s1, s2, ...}) do
        table.insert(ret, localize(s, self.locale, self.defaultLocale))
      end
      return table.unpack(ret)
    else
      return localize(s1, self.locale, self.defaultLocale)
    end
  end

  function Game:push(state) print(state, state.onPush)
    local top = self.states:top()
    state.game = self
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

  function Game:quit()
    love.event.push("quit")
  end

  return Game
end
