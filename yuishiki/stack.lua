local Stack

return function(loader)
  if Stack then return Stack end

  Stack = loader.class("Stack")

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
    if self.size > 0 then
      self.size = self.size - 1
      return table.remove(self.elements)
    end
  end

  function Stack:popn(n)
    local ret = {}
    for i = 1, n do
      table.insert(self:pop())
    end
    return ret
  end

  function Stack:top()
    return self.elements[self.size]
  end

  function Stack:bottom()
    return self.elements[1]
  end

  function Stack:insert(e, index)
    table.insert(self.elements, index, e)
    self.size = self.size + 1
  end

  function Stack:isEmpty()
    return self.size == 0
  end

  function Stack:pairs(start)
    local index = start or 1
    return function()
      if index <= self.size then
        local k = index
        local v = self.elements[index]
        index = index + 1
        return k, v
      end
    end
  end

  return Stack
end
