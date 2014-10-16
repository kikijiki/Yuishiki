return function(loader)
  local uti = {}

  local null_metatable = {}
  local null_function = function() return setmetatable({}, null_metatable) end
  null_metatable.__index = null_function
  null_metatable.__newindex = null_function
  null_metatable.__call = null_function
  uti.null_interface = setmetatable({}, null_metatable)

  function defined(x)
    return x and x ~= null_metatable and x ~= null_function
  end

  function uti.makeIdGenerator(tag, hex)
    local prefix = tag.."_"
    local counter = 0

    return function()
      counter = counter + 1
      if hex then return string.format("%s_%x", prefix, counter)
      else return prefix..tostring(counter) end
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

  return uti
end
