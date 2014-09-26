assert(summon, "SUMMON is not loaded.")

local Entity = summon.class("Entity")

local generateEntityId = summon.common.uti.idGenerator("entity")
local shallowCopy = summon.common.uti.shallowCopy

function Entity:initialize()
  self.id = generateEntityId()
  self.parameters = {}
  self.rules = {}
  self.actions = {}
end

function Entity:cloneState()
  local c = {
    id = self.id,
    parameters = {},
    rules = {},
    actions = {}
  }
  
  for k,v in pairs(self.parameters) do
    c.parameters[k] = v:clone()
  end
  
  shallowCopy(self.rules, c.rules)
  shallowCopy(self.actions, c.actions)
  
  return c
end

function Entity:swapState(state)
  self.parameters = state.parameters
  self.actions = state.actions
  self.rules = state.rules
end

return Entity