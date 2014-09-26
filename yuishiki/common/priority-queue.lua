assert(ys, "Yuishiki is not loaded.")

local PriorityQueue = ys.common.class("PriorityQueue")

function PriorityQueue:initialize(compare, content)
  self.cmp = compare or (function(a, b) return a < b end)
  self.data = {}
  self.size = 0
  
  if content then
    for _,v in pairs(content) do self:push(v) end
  end
end

function PriorityQueue:push(element)
  assert(self, [[Use ":" not "."!]])
  
  local data, cmp = self.data, self.cmp
  
  table.insert(data, element)
  
  if #data == 1 then
    self.size = self.size + 1
    return
  end
  
  local i = #data
  local j = #data - 1
  while j > 0 do
    if cmp(data[i], data[j]) then
      data[i], data[j] = data[j], data[i]
      i = i - 1
      j = j - 1
    else break end
  end
  
  self.size = self.size + 1
end

function PriorityQueue:pop()
  assert(self, [[Use ":" not "."!]])
  
  if(self.size > 0) then
    self.size = self.size - 1
  end
  
  return table.remove(self.data)
end

function PriorityQueue:isEmpty()
  assert(self, [[Use ":" not "."!]])
  
  return self.size == 0
end

return PriorityQueue;