local class = require "lib.middleclass"
local Action = class("Action")

function Action:initialize(data)
  self.body = data.body
  self.cost = data.cost
  self.condition = data.condition
end

function Action:canExecute(gm, c, ...)
  if self.condition and not self.condition(gm, c, ...) then return false end
  if self.cost and not gm:canPayCost(c, self.cost, ...) then return false end
  return true
end

function Action:execute(gm, c, ...)
  if self:canExecute(gm, c, ...) then
    gm:payCost(c, self.cost, ...)
    return self.body(gm, c, ...)
  else
    return false
  end
end

return Action
