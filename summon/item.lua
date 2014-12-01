local Item

return function(loader)
  if Item then return Item end
  Item = loader.class("Item")

  function Item:initialize(name, item_type, slot)
    self.name      = name
    self.item_type = item_type
    self.slot      = slot
    self.mods      = {}
    self.triggers  = {}
  end

  function Item:__tostring()
    return "Item <"..self.item_type..">["..self.name.."]"
  end

  function Item:addMod(stat, name, value)
    self.mods[stat] = {name, value}
  end

  function Item:addTrigger(trigger, value)
    if type(trigger) == "table" then
      for k,v in pairs(trigger) do self.triggers[k] = v end
    else
      self.triggers[trigger] = value
    end
  end

  function Item:onEquip(c)
    for mod, v in pairs(self.mods) do
      c.status[mod]:setMod(v[1], v[2])
    end
  end

  function Item:onUnequip(c)
    for mod, v in pairs(self.mods) do
      c.status[mod]:unsetMod(v[1])
    end
  end

  return Item
end
