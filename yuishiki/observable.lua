local class = require "lib.middleclass"

local Observable = class("Observable")

function Observable:initialize()
  self.observers = setmetatable({}, {__mode="k"})
end

function Observable:addObserver(l, c)
  self.observers[l] = c
end

function Observable:notify(...)
  for _,observer in pairs(self.observers) do
    listener(...)
  end
end
