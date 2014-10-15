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


function BeliefBase:set(data, name, path)
  local root = self:resolve(path, true)
  root[name] = data
  self.lookup[path.."."..name] = data
  -- TODO create and dispatch event for root change
end

return BeliefBase
