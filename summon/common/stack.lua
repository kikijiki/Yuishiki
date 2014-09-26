assert(summon, "SUMMON is not loaded.")

local Stack = summon.class("Stack")

function Stack:initialize()
  self.size = 0
  self.elements = {}
end

function Stack:push(e)
  table.insert(self.elements, e)
  self.size = self.size + 1
  return e
end

function Stack:pop()
  if self.size == 0 then return nil end
  self.size = self.size - 1
  return table.remove(self.elements)
end

function Stack:top()
  return self.elements[self.size]
end

function Stack:insert(e, index)
  table.insert(self.elements, index, e)
  self.size = self.size + 1
end

function Stack:empty()
  return self.size == 0
end

return Stack