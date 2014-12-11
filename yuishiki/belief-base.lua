local BeliefBase

return function(loader)
  if BeliefBase then return BeliefBase end

  local log = loader.load "log"
  local Event = loader.load "event"
  local Belief = loader.load "belief"
  local Observable = loader.load "observable"

  local PATH_SEPARATOR = "."
  local PATH_TRAVERSER_PATTERN = '([^'..PATH_SEPARATOR..']+)'
  local PATH_SPLITTER_PATTERN =
    '%'..PATH_SEPARATOR..'([^%'..PATH_SEPARATOR..']*)$'

  BeliefBase = loader.class("BeliefBase", Observable)

  function BeliefBase:initialize()
    Observable.initialize(self)

    self.lookup  = {} -- path  -> belief
    self.beliefs = {} -- table -> belief

    self.observer = function(belief, new, old, ...)
      local event = Event.belief(belief, Belief.Status.changed, new, old, ...)
      self:notify(event)
    end

    self.log = log.tag("BB")

    self.interface = {
      d = self.beliefs,
      set = function(...) return self:set(...) end,
      get = function(...) return self:getValue(...) end,

      isTrue         = function(   ...) return self:getValue(...) ==  true end,
      isFalse        = function(   ...) return self:getValue(...) == false end,
      isNil          = function(   ...) return self:getValue(...) ==   nil end,
      isDefined      = function(   ...) return self:getValue(...) ~=   nil end,
      isEqual        = function(x, ...) return self:getValue(...) == x end,
      isGreater      = function(x, ...) return self:getValue(...) >  x end,
      isGreaterEqual = function(x, ...) return self:getValue(...) >= x end,
      isLess         = function(x, ...) return self:getValue(...) <  x end,
      isLessEqual    = function(x, ...) return self:getValue(...) <= x end,
    }
  end

  function BeliefBase:resolve(path, create)
    if not path then return end

    local belief = self.beliefs
    local last
    for token in string.gmatch(path, PATH_TRAVERSER_PATTERN) do
      last = token
      if belief[token] then
        belief = belief[token]
      else
        if create then
          belief[token] = {}
          belief = belief[token]
        else
          return nil, last
        end
      end
    end

    return belief, last
  end

  function BeliefBase.static.parsePath(path)
    if not path then return end
    local from, to = path:find(PATH_SPLITTER_PATTERN)
    if from then
      return path:sub(1, from - 1), path:sub(from + 1)
    else
      return path
    end
  end

  function BeliefBase.static.appendPath(a, b)
    return a..PATH_SEPARATOR..b
  end

  function set(bb, source, retention, data, ...)
    local full_path = table.concat({...}, PATH_SEPARATOR)
    local base_path, name = BeliefBase.parsePath(full_path)

    local belief = Belief(data, name, full_path, retention, source)
    belief:addObserver(bb, bb.observer)

    bb.lookup[full_path] = belief
    local root = bb:resolve(base_path, true)
    root[name] = belief

    local event = Event.belief(belief, Belief.Status.new, belief:get())
    bb:notify(event)

    return belief
  end

  function raw_set(bb, path, belief)
    local base_path, name = BeliefBase.parsePath(path)
    local root = bb:resolve(base_path, true)

    root[name] = belief
    bb.lookup[path] = belief

    belief:addObserver(bb, bb.observer)
    bb:notify(Event.belief(belief, Belief.Status.new, belief:get()))

    return belief
  end

  function BeliefBase:set(retention, ...)
    return set(self, "internal", retention, ...)
  end

  function BeliefBase:setST(...)
    return set(self, "internal", "short", ...)
  end

  function BeliefBase:setLT(...)
    return set(self, "internal", "long", ...)
  end

  function BeliefBase:import(...)
    return set(self, "external", "short", ...)
  end

  function BeliefBase:unset(path)
    -- TODO
    local belief = self.lookup[path]
    local event = Event.belief(belief, Belief.Status.deleted, belief:get())
    self:notify(event)
  end

  function BeliefBase:get(path, p2, ...)
    if type(path) == "table" then path = table.concat(path, PATH_SEPARATOR) end
    if p2 then path = table.concat({path, p2, ...}, PATH_SEPARATOR) end
    return self.lookup[path]
  end

  function BeliefBase:getValue(...)
    local b = self:get(...)
    if b then return b:get() end
  end

  function BeliefBase:dump()
    if not next(self.lookup) then
      self.log.i("--[[BELIEF BASE EMPTY]]--")
      return
    end

    local paths = {}
    local lengths = {}
    local longest = 0

    for path,_ in pairs(self.lookup) do
      table.insert(paths, path)
      local length = string.len(path)
      lengths[path] = length
      if length > longest then longest = length end
    end

    table.sort(paths)

    self.log.i("--[[BELIEF BASE DUMP START]]--[["..#paths.." elements]]--")
    self.log.i()
    for _,path in pairs(paths) do
      local belief = self.lookup[path]
      local source, storage
      if belief.source == "internal" then source = "I" else source = "E" end
      if belief.retention == "short" then storage = "S" else storage = "L" end
      local skip = longest - lengths[path] - 1
      self.log.fi("[%s%s] %s %s %s",
        source, storage, path, string.rep(".", skip), tostring(belief))
    end
    self.log.i()
    self.log.i("--[[BELIEF BASE DUMP END]]--")
  end

  function BeliefBase:save()
    local data = {}
    for path, belief in pairs(self.lookup) do
      if belief.source == "internal" and belief.retention == "long" then
        data[path] = belief
      end
    end
    return data
  end

  function BeliefBase:restore(data)
    for path, belief in pairs(data) do print("restoring", path)
      raw_set(self, path, belief)
    end
  end

  return BeliefBase
end
