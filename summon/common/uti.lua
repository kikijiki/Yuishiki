assert(summon, "SUMMON is not loaded.")

local M = {}

function M.stepCode()
  require("mobdebug").start()
end

function M.idGenerator(tag)
  local counter = 0
  local prefix = tag.."_"
  return function ()
    local Id = prefix..counter
    counter = counter + 1
    return Id
  end
end

function M.clamp(v, min, max)
  if min and v < min then v = min return v end
  if max and v > max then v = max return v end
  return v
end

function M.split(str, sep)
  local fields = {}
  sep = sep or " "
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function M.shallowCopy(source, dest, MT)
  if type(source) == "table" then
    for k,v in pairs(source) do dest[k] = v end
  else dest = source end

  if MT then
    setmetatable(dest, getmetatable(source))
  end
end

function M.makeMetaIndex(f, ...)
  local args = {...}
  return setmetatable({}, {
    __index = function(t, k)
      return f(k, table.unpack(args))
    end
  })
end

function M.foreach(data, f)
  if type(data) == "table" then
    for _,v in pairs(data) do f(v) end
  else
    f(data)
  end
end

function M.runSandboxed(path, options)
  local data = love.filesystem.load(path)
  if not data then return nil, "Error loading "..path.."." end

  return pcall(summon.common.sandbox.run, data, options)
end


return M
