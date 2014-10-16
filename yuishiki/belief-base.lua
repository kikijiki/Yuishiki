return function(loader)
  local class = loader.require "middleclass"
  local Event = loader.load "event"
  local Belief = loader.load "belief"
  local Observable = loader.load "observable"

  local BeliefBase = class("BDI.BeliefBase", Observable)

  function BeliefBase:initialize()
    self.lookup = {}
    self.beliefs = {}

    self.observer = function(belief, new, old)
      local event = Event.Belief(belief, Belief.Status.changed, new, old)
      self:notify(event)
    end

    -- TODO
    interface = self
  end

  function BeliefBase:resolve(path, create)
    local belief = self.beliefs
    local last

    if path then
      for token in string.gmatch(path, '([^.]+)') do
        last = token
        if belief[token] then
          belief = belief[token]
        else
          if create then
            belief[token] = {}
            belief = belief[token]
          else
            return nil, last
          end
        end
      end
    end

    return belief, last
  end

  -- TODO check for overwrite?
  function BeliefBase:set(data, name, path, readonly)
    local belief = Belief(data, name, path, readonly)
    belief:addObserver(self, self.observer)

    self.lookup[belief.full_path] = belief
    local root = self:resolve(path, true)
    root[name] = belief

    local event = Event.Belief(belief, Belief.Status.new, belief:get())
    self:notify(event)

    return belief
  end

  function BeliefBase:unset(path)
    -- TODO
    local event = Event.Belief(belief, Belief.Status.deleted, belief:get())
    self:notify(event)
  end

  function BeliefBase:get(path)
    return self.lookup[path]
  end

  return BeliefBase
end
