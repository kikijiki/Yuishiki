return function(loader)
  local class = loader.require "middleclass"
  local Event = loader.load "event"
  local Belief = loader.load "belief"

  local BeliefBase = class("BDI.BeliefBase")

  function BeliefBase:initialize(agent) assert(agent)
    self.agent = agent

    self.lookup = {}
    self.beliefs = {}

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

  -- TODO create and dispatch event for root change
  -- TODO check for overwrite?
  function BeliefBase:set(data, name, path, readonly)
    local belief = Belief(data, name, path, readonly)
    local root = self:resolve(path, true)

    root[name] = belief
    self.lookup[belief.full_path] = belief
  end

  function BeliefBase:get(path)
    return self.lookup[path]
  end

  return BeliefBase
end
