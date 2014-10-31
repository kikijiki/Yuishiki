local Log

return function(loader)
  if Log then return Log end

  Log = {
    Verbosity = {verbose = 3, normal = 2, minimal = 1, none = 0}
  }

  Log.verbosity = Log.Verbosity.normal

  local function buildBuffer(buf, ...)
    local n = select("#", ...)
    for i=1, n do
      local s = tostring(select(i, ...))
      table.insert(buf, s)
      if i ~= n then table.insert(buf, "\t") end
    end
  end

  local function writeToLog(tag, level, die, ...)
    local info = debug.getinfo(3)
    local loginfo = {
      "[", tag, "] ", (info.source or "[unknown]"), "/", (info.name or "[unknown]"),
      "(", tostring(info.currentline), ")>"
    }

    local msg = {}
    buildBuffer(msg, ...)

    if die then
      error(table.concat(msg), 3)
    else
      if level <= Log.verbosity then
        io.write(table.concat(loginfo))
        io.write(table.concat(msg))
        io.write("\n")
      end
    end
  end

  Log.i = function(...)
    writeToLog("INF", 3, false, ...)
  end

  Log.d = function(...)
    writeToLog("DBG", 2, false, ...)
  end

  Log.w = function(...)
    writeToLog("WRN", 2, false, ...)
  end

  Log.e = function(...)
    writeToLog("ERR", 1, true, ...)
  end

  Log.check = function(value, ...)
    if not value then writeToLog("ERR", 1, true, ...) end
  end

  return Log
end
