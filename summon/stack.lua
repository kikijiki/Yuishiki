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
    if self.size == 0 then return nil end
    self.size = self.size - 1
    return table.remove(self.elements)
  end

  function Stack:top()
    return self.elements[self.size]
  end

  function Stack:insert(e, index)
    table.insert(self.elements, index or 1, e)
    self.size = self.size + 1
  end

  function Stack:empty()
    return self.size == 0
  end

  function Stack:__len()
    return self.size
  end

  return Stack
end
