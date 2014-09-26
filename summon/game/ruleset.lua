assert(summon, "SUMMON is not loaded.")

local Ruleset = summon.class("Ruleset")

local ext = ".rule"

function Ruleset:initialize(data, path, name)
  self.parameters = {}
  self.rules = {}
  self.actions = {}
  self.loaded = {}
  self.globals = {rules={}, actions={}, parameters={}}
  
  self:import(data, path, name)
end

function Ruleset.load(path, base, name)
  local include_path = path.."/"..name..ext
  local data = summon.AssetLoader.loadRaw(include_path)
  return Ruleset(data, path, name)
end

function Ruleset:import(data, path, name)
  if self.loaded[name] then return end
  
  if data.preLoad then data.preLoad(self) end
  
  -- actual loading
  if data.parameters then
    for _,v in pairs(data.parameters) do
      local param = summon.game.Parameter(v)
      self.parameters[v.name] = param
      if v.scope == "global" then self.globals.parameters[v.name] = param end
    end
  end
  
  if data.rules then
    for _,v in pairs(data.rules) do
      self.rules[v.name] = v
      if v.scope == "global" then self.globals.rules[v.name] = v end
    end
  end

  if data.actions then
    for _,v in pairs(data.actions) do
     self.actions[v.name] = v
     if v.scope == "global" then self.globals.actions[v.name] = v end
    end
  end

  if data.include then
    for _,inc in pairs(data.include) do
      local include_path = path.."/"..inc..ext
      local include_data = summon.AssetLoader.loadRaw(include_path)
      self:import(include_data, path, inc)
    end
  end
  
  if data.postLoad then data.postLoad(self) end
  
  self.loaded[name] = true
end

function Ruleset:instanceParameter(name)
  local prototype = self.parameters[name]
  if prototype == nil then error("The parameter "..name.." is not defined and cannot be instantiated.") end
  return summon.game.Parameter(prototype)
end

return Ruleset