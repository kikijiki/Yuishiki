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
      setLT = function(...) return self:setLT(...)      end,
      setST = function(...) return self:setST(...)      end,
      get   = function(...) return self:getValue(...) end,

      isTrue         = function(   ...) return self:getValue(...) ==  true end,
      isFalse        = function(   ...) return self:getValue(...) == false end,
      isNil          = function(   ...) return self:getValue(...) ==   nil end,
      isDefined      = function(   ...) return self:getValue(...) ~=   nil end,
      isEqual        = function(x, ...) return self:getValue(...) ==     x end,
      isGreater      = function(x, ...) return self:getValue(...) >      x end,
      isGreaterEqual = function(x, ...) return self:getValue(...) >=     x end,
      isLess         = function(x, ...) return self:getValue(...) <      x end,
      isLessEqual    = function(x, ...) return self:getValue(...) <=     x end,

      --TODO more setters (increase, add, sub, mul, ...)
    }
  end

  function resolve(bb, path, create)
    if not path then
      return bb.beliefs
    end

    local belief = bb.beliefs
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

  function parsePath(...)
    local raw_path = {...}
    if #raw_path == 0 then return end

    local path = {}
    path.full = table.concat(raw_path, PATH_SEPARATOR)

    local from, to = path.full:find(PATH_SPLITTER_PATTERN)

    if from then
      path.base = path.full:sub(1, from - 1)
      path.name = path.full:sub(from + 1)
    else
      path.name = path.full
    end

    return path
  end

  function appendPath(a, b)
    return a..PATH_SEPARATOR..b
  end

  function raw_set(bb, belief)
    local path = belief.path

    bb.lookup[path.full] = belief
    local root = resolve(bb, path.base, true)
    root[path.name] = belief

    belief:addObserver(bb, bb.observer)
    bb:notify(Event.belief(belief, Belief.Status.new, belief:get()))

    return belief
  end

  function set(bb, source, retention, data, ...)
    local path = parsePath(...)
    local belief = bb.lookup[path.full]
    if belief then
      belief:set(data)
    else
      belief = Belief(data, path, retention, source)
      raw_set(bb, belief)
    end
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

  function BeliefBase:dump(level)
    level = level or "i"
    if not next(self.lookup) then
      self.log[level]("--[[BELIEF BASE EMPTY]]--")
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

    self.log[level]("--[[BELIEF BASE DUMP START]]--[["..#paths.." elements]]--")
    self.log[level]()
    for _,path in pairs(paths) do
      local belief = self.lookup[path]
      local source, storage
      if belief.source == "internal" then source = "I" else source = "E" end
      if belief.retention == "short" then storage = "S" else storage = "L" end
      local skip = longest - lengths[path] - 1
      self.log["f"..level]("[%s%s] %s %s %s",
        source, storage, path, string.rep(".", skip), tostring(belief))
    end
    self.log[level]()
    self.log[level]("--[[BELIEF BASE DUMP END]]--")
  end

  function BeliefBase:save()
    local data = {}
    for _, belief in pairs(self.lookup) do
      if belief.source == "internal" and belief.retention == "long" then
        table.insert(data, belief)
      end
    end
    return data
  end

  function BeliefBase:restore(data)
    for _, belief in pairs(data) do self.log.i("restoring", belief.path.full)
      belief:reset()
      raw_set(self, belief)
    end
  end

  return BeliefBase
end
