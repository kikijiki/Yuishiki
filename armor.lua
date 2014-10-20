local class = require "lib.middleclass"
local Item = require "item"

local Armor = class("Armor", Item)

function Armor:initialize(data)
  Item.initialize(self, data.name, "armor", "armor")

  self.def = data.def
  self.mdef = data.mdef
  self.arm = data.arm
  self.marm = data.marm
  self.sarm = data.sarm or {}

  self:addTrigger(self.triggers)

  if data.initialize then data.initialize(self) end
end

return Armor
