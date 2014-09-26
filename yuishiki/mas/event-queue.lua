local EventQueue = ys.common.class("EventQueue", ys.common.PriorityQueue)

function EventQueue:initialize()
  ys.common.PriorityQueue.initialize(self,
    function(a, b)
      if a.priority and b.priority then
        return a.priority < b.priority
      else
        return false end
    end)
end

return EventQueue