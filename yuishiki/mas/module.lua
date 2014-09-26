assert(ys, "Yuishiki is not loaded.")

local Module = ys.common.class("Module")

function Module:initialize(name)
  self.name = name
  self.components = {}
  self.functions = {}
  self.before = ys.common.ManualTrigger()
  self.after  = ys.common.ManualTrigger()
end

function Module:add(x) assert(x)
  local ys_type = x.getYsType()
  if not self.components[ys_type] then self.components[ys_type] = {} end
  table.insert(self.components[ys_type], x)
end

-- TODO: functions, bdi_functions
function Module:set(name, f) assert(name) assert(f)
  self.functions[name] = f
end

return Module