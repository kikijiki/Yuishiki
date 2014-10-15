assert(ys, "Yuishiki is not loaded.")

local BeliefBase = ys.common.class("BDI_BeliefBase")
local Event, Belief = ys.bdi.event, ys.bdi.Belief

function BeliefBase:initialize(agent) assert(agent)
  self.beliefs = {}
  self.agent = agent

  -- TODO: finish the interface (belief operators)
  self.interface = setmetatable({
    set = setmetatable({},{
      __index = function(t, k)
        local belief = self.beliefs[k]
        if not belief then
          belief = ys.bdi.Belief.Internal(k, nil)
          self:set(belief)
        end
        return function(x) belief:set(x) end
      end
    }),
  }, {
    __index = function(t, k)
      return self.beliefs[k]:get()
    end,
    __newindex = function(t, k)
      ys.log.w("Trying to modify an interface.")
      return ys.common.uti.null_interface
    end
  })
end

function BeliefBase:set(belief, path)
  if type(path) == "string" and path:len() > 0 then
    local bs = self:get(path, -1)
    bs:set(belief.na)
  else --root belief
    if self.beliefs[belief.name] then ys.log.i("Overwriting belief <"..belief.name..">.") end
    belief.dispatcher = self.agent.dispatcher
    self.beliefs[belief.name] = belief
  end
end

function BeliefBase:unset(name)
  self.beliefs[name] = nil
end

function BeliefBase:get(path) --TODO fix
  local belief = self.beliefs
  for k in string.gmatch(name, '([^.]+)') do
    belief = belief[k]
  end
  return belief
end

function BeliefBase:bind(name, data)
  self.beliefs[name]:bind(data)
end

return BeliefBase
