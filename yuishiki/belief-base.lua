local BeliefBase

return function(loader)
  if BeliefBase then return BeliefBase end

  local class = loader.require "middleclass"
  local log = loader.load "log"
  local Event = loader.load "event"
  local Belief = loader.load "belief"
  local Observable = loader.load "observable"

  local PATH_SEPARATOR = "."
  local PATH_TRAVERSER_PATTERN = '([^'..PATH_SEPARATOR..']+)'
  local PATH_SPLITTER_PATTERN = '%'..PATH_SEPARATOR..'([^%'..PATH_SEPARATOR..']*)$'

  BeliefBase = class("BeliefBase", Observable)

  function BeliefBase:initialize()
    Observable.initialize(self)

    self.lookup  = {} -- path  -> belief
    self.beliefs = {} -- table -> belief

    self.observer = function(belief, new, old, ...)
      local event = Event.Belief(belief, Belief.Status.changed, new, old, ...)
      self:notify(event)
    end

    -- TODO
    self.interface = {
      p = self.lookup,
      d = self.beliefs
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

  -- TODO check for overwrite?
  function BeliefBase:set(data, readonly, ...)
    local path = {...}
    local full_path = table.concat(path, ".")
    local base_path, name = BeliefBase.parsePath(full_path)

    local belief = Belief(data, name, full_path, readonly)
    belief:addObserver(self, self.observer)

    self.lookup[full_path] = belief
    local root = self:resolve(base_path, true)
    root[name] = belief
    
    local event = Event.Belief(belief, Belief.Status.new, belief:get())
    self:notify(event)

    return belief
  end

  function BeliefBase:unset(path)
    -- TODO
    local belief = self.lookup[path]
    local event = Event.Belief(belief, Belief.Status.deleted, belief:get())
    self:notify(event)
  end

  function BeliefBase:get(path)
    return self.lookup[path]
  end

  function BeliefBase:dump()
    if not next(self.lookup) then
      log.i("--[[BELIEF BASE EMPTY]]--")
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
    
    log.i("--[[BELIEF BASE DUMP START]]--[["..#paths.." elements]]--")
    log.i()
    for _,path in pairs(paths) do
      local skip = longest - lengths[path]
      log.fi("[%s] %s %s", path, string.rep(".", skip), tostring(self.lookup[path]))
    end
    log.i()
    log.i("--[[BELIEF BASE DUMP END]]--")
  end

  return BeliefBase
end
