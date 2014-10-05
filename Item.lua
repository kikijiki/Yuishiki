local Class = require "lib.middleclass"

local Item = Class("Item")

function Item:initialize(name, item_type, slot)
  self.name = name
  self.item_type = item_type
  self.slot = slot
end

return Item