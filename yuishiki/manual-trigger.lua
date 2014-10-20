return function(loader)
  local null = function() end
  local call = function(f, default_args)
    return function()
      if default_args then
        return f(table.unpack(default_args))
      else return f() end
    end
  end

  local MT = {
    __index = function(self, k)
      local t = rawget(self, "_triggers")[k]
      if t then return call(t, rawget(self, "_default_args"))
      else return null end
    end,

    __newindex = function(self, k, v)
      rawget(self, "_triggers")[k] = v
    end
  }

  return setmetatable({}, {
    __call = function(self, data)
      local t = { _triggers = {}}
      t.setDefaultArguments = function(...)
        rawset(t, "_default_args", {...})
      end
      t.default = function(x)
        return setmetatable({}, {
          __index = function(_, k)
            local trigger = rawget(t._triggers, k)
            if trigger then
              return call(trigger, rawget(t, "_default_args"))
            else
              return function() return x end
            end
          end
        })
      end
      if data then
        for k,v in pairs(data) do t._triggers[k] = v end
      end
      return setmetatable(t, MT)
    end
  })
end
