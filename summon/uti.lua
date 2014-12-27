local Uti

return function(loader)
  if Uti then return Uti end

  local fs      = loader.require "filesystem"
  local sandbox = loader.require "sandbox"

  Uti = {}

  function Uti.idGenerator(tag)
    local counter = 0
    local prefix = tag.."_"
    return function ()
      local Id = prefix..counter
      counter = counter + 1
      return Id
    end
  end

  function Uti.clamp(v, min, max)
    if min and v < min then v = min return v end
    if max and v > max then v = max return v end
    return v
  end

  function Uti.split(str, sep)
    local fields = {}
    sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
  end

  function Uti.lines(str)
    local lines = {}
    if str then
      for line in str:gmatch("[^\r\n]+") do table.insert(lines, line) end
    end
    return lines
  end

  function Uti.shallowCopy(source, dest, MT)
    if type(source) == "table" then
      for k,v in pairs(source) do dest[k] = v end
    else dest = source end

    if MT then
      setmetatable(dest, getmetatable(source))
    end
  end

  function Uti.makeMetaIndex(f, ...)
    local args = {...}
    return setmetatable({}, {
      __index = function(t, k)
        return f(k, table.unpack(args))
      end
    })
  end

  function Uti.foreach(data, f)
    if type(data) == "table" then
      for _,v in pairs(data) do f(v) end
    else
      f(data)
    end
  end

  function Uti.runSandboxed(path, error_handler, options)
    local data = fs.load(path)
    if not data then return nil, "Error loading "..path.."." end
    if errf then
      return xpcall(sandbox.run, error_handler, data, options)
    else
      return pcall(sandbox.run, data, options)
    end
  end

  return Uti
end
