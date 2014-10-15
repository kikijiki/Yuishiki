assert(ys, "Yuishiki is not loaded.")

local BeliefBase = ys.common.class("BDI_BeliefBase")
local Event, Belief = ys.bdi.event, ys.bdi.Belief

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
      if create and not belief[token] then
        belief[token] = {}
      else
        belief = belief[token]
      end
    end
  end

  return belief, last
end


function BeliefBase:add(data, name, path, getter, setter)
  local root = self:resolve(path, true)
  root[name] = data
  self.lookup[path.."."..name] = {
    data = data,
    getter = getter,
    setter = setter,
    internal = false -- TODO
  }
  -- TODO create and dispatch event for root change
end

function BeliefBase:get(path)
  local belief = self.lookup[path]
  if not belief then return end
  if belief.getter then return belief.getter(belief.data)
  else return belief.data end
end

function BeliefBase:set(path, ...)
  local belief = self.lookup[path]
  if not belief then return end

  local old = belief.data
  if belief.setter then
    belief.setter(belief.data, ...)
  else
    belief.data = select(1, ...)
  end

  --TODO create and dispatch event for belief change
end

return BeliefBase
