local uti

return function(loader)
  if uti then return uti end

  uti = {}

  local null_metatable = {}
  local null_function = function() return setmetatable({}, null_metatable) end
  null_metatable.__index = null_function
  null_metatable.__newindex = null_function
  null_metatable.__call = null_function
  uti.null_interface = setmetatable({}, null_metatable)

  function defined(x)
    return x and x ~= null_metatable and x ~= null_function
  end

  function uti.makeIdGenerator(tag, sep)
    local counter = 0

    if tag then
      sep = sep or "-"
      local prefix = tag..sep

      return function()
        counter = counter + 1
        return prefix..tostring(counter)
      end
    else
      return function()
        counter = counter + 1
        return counter
      end
    end
  end

  function uti.camelToUnderscore(s, under)
    local ret = string.gsub(s, "([a-z])([A-Z])", "%1_%2")
    if under then return string.lower(ret)
    else return ret end
  end

  function uti.makeEnum(...)
    enum = {}
    for _,v in pairs({...}) do
      enum[v] = uti.camelToUnderscore(v, true) end
    return enum
  end

  function uti.startsWith(str, value)
    if not str then return false end
    if not value or string.len(value) == 0 then return true end
    return string.sub(str, 1, string.len(value)) == value
  end

  function uti.endsWith(str, value)
    if not str then return false end
    if not value or string.len(value) == 0 then return true end
    return value == '' or string.sub(str, -string.len(value)) == value
  end

  return uti
end
