assert(ys, "Yuishiki is not loaded.")

local BeliefBase = ys.common.class("BDI_BeliefBase")
local Event, Belief = ys.bdi.event, ys.bdi.Belief

function BeliefBase:initialize(agent) assert(agent)
  self.beliefs = Belief.Set()
  self.agent = agent

  -- TODO: finish the interface (belief operators), use path!
  self.interface = setmetatable({
    set = setmetatable({},{
      __index = function(t, k)
        local belief = self.beliefs[k]
        if belief then
          if belief.class.name == "Beliefset" then return belief
          else
            return setmetatable({}, {
              __call = function(...)
                belief:set(...)
              end
            })
          end
        else
          return setmetatable({}, {
            __call = function(...)
              t:set(...)
            end
          })
        end
        if not belief then
          belief = ys.bdi.Belief.Internal(k, nil)
          self:set(belief)
        end
        return function(x) belief:set(x) end
      end
    }),
  }, {
    __index = function(t, k)
      local belief = self.beliefs[k]
      if belief.class.name == "Beliefset" then return belief
      else return belief:get() end
    end,
    __newindex = function(t, k)
      ys.log.w("Trying to modify an interface.")
      return ys.common.uti.null_interface
    end
  })
end

-- Index = [-1, x]
function BeliefBase:resolve(path, index)
  local belief = self.beliefs
  local last
  local i = 1

  for token in string.gmatch(path, '([^.]+)') do
    last = token
    belief = belief[token]
    i = i + 1
    if index > 0 and i >= index then break end
  end

  return belief, last
end

function BeliefBase:set(path, name, belief)
  assert(belief)
  assert(type(path) == "string" and path:len() > 0)

  local bs self:resolve(path)
  bs:set(name, belief)

  belief.dispatcher = self.agent.dispatcher
end

return BeliefBase
