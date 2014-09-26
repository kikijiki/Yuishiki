assert(summon, "SUMMON is not loaded.")

local WorldInterface = {}

local makeMetaIndex = summon.common.uti.makeMetaIndex

local function makeParameterInterface(parameter, world, entity, f)
  return setmetatable({}, {
    __index = function(t, k)
      return setmetatable({}, {
        __call = function(t, ...)
          return f(world, entity, "parameter", {
              name = parameter,
              op = k,
              args = {...}
            })
        end
      })
    end
  })
end

local function makeActionInterface(action, world, entity, f)
  return setmetatable({}, {
    __call = function(t, ...)
      return f(world, entity, "action", {
          name = action,
          args = {...}
        })
    end
  })
end

local function makeEntityInterface(entity, world, f)
  return setmetatable({}, {
    __index = setmetatable({
        ["p"] = makeMetaIndex(makeParameterInterface, world, entity, f),
        ["a"] = makeMetaIndex(makeActionInterface, world, entity, f),
      }, {
        __index = function(t, k)
          return setmetatable({}, {
            __call = function(t, ...)
              return f(world, entity, "entity", {
                name = k,
                args = {...}
              })
            end
          })
        end
      });
  })
end

function WorldInterface.make(w)
  local world = w
  local wi = {try = {}}
  
  wi.entities = makeMetaIndex(makeEntityInterface, world, world.execute)
  wi.try.entities = makeMetaIndex(makeEntityInterface, world, world.try)
  wi.log = summon.log.extern
  
  return wi
end

return WorldInterface