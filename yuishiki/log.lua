local log

return function(loader)
  if log then return log end

  local ansicolors = loader.require "ansicolors".noReset

  log = {
    Verbosity     = {all = 3, debug = 2, errors = 1, disabled = 0},
    showInfo      = true,
    showTime      = true,
    useAnsiColors = false,
    verbosity     = 3
  }

  local outputs = {
    full = {},
    raw = {print}
  }

  local colors = {
    reset   = ansicolors("%{reset}"),
    source  = "",
    arrow   = "",
    name    = ansicolors("%{bright yellow}"),
    line    = ansicolors("%{bright cyan}"),
    message = ""
  }

  local severities = {
    p = {
      normal = "",
      color  = "",
      level  = 3,
      die    = false},
    i = {
      normal = "[INF]",
      color  = ansicolors("%{bright green}[INF]%{reset}"),
      level  = 3,
      die    = false},
    d = {
      normal = "[DBG]",
      color  = ansicolors("%{bright black}[DBG]%{reset}"),
      level  = 2,
      die    = false},
    w = {
      normal = "[WRN]",
      color  = ansicolors("%{bright yellow}[WRN]%{reset}"),
      level  = 2,
      die    = false},
    e = {
      normal = "[ERR]",
      color  = ansicolors("%{bright red}[ERR]%{reset}"),
      level  = 1,
      die    = false},
    f = {
      normal = "[FAT]",
      color  = ansicolors("%{bright red}[FAT]%{reset}"),
      level  = 0,
      die    = true}
  }

  local function sendRawOutput(data)
    for _,out in pairs(outputs.raw) do
      out(data)
    end
  end

  local function sendOutput(data)
    for _,out in pairs(outputs.full) do
      out(data)
    end
  end

  local function buildBuffer(...)
    local buffer = {}
    for _,data in pairs({...}) do table.insert(buffer, tostring(data)) end
    return table.concat(buffer, " ")
  end

  local function writeToLog(severity_name, tag, ...)
    local severity = severities[severity_name]
    if severity.level > log.verbosity then return end

    local data = {}
    data.severity = severity_name
    data.tag = tag
    data.msg = buildBuffer(...)
    data.time = os.date("*t", os.time())
    data.info = debug.getinfo(3)

    local timestamp = ""
    if log.showTime then
      timestamp = "["..data.time.hour..":"..data.time.min..":"..data.time.sec.."]"
    end

    local tagstamp = ""
    if type(tag) == "string" then tagstamp = "["..tag.."]" end

    if log.useAnsiColors then
      severity = severity.color
      data.meta = {
        timestamp, tagstamp,
        colors.source, (data.info.source or "[unknown]"), colors.reset,
        colors.arrow, "->", colors.reset,
        colors.name, (data.info.name or "[unknown]"), colors.reset,
        "(", colors.line, tostring(data.info.currentline), colors.reset, ") ",
        colors.message}
    else
      severity = severity.normal
      data.meta = {
        timestamp, tagstamp,
        (data.info.source or "[unknown]"),
        "->", (data.info.name or "[unknown]"),
        "(", tostring(data.info.currentline), ") "}
    end

    data.meta = table.concat(data.meta)

    local buffer = timestamp..severity..tagstamp.." "
    if log.showInfo then
      buffer = buffer..data.meta..data.msg
    else
      buffer = buffer..data.msg
    end

    data.full = buffer

    sendOutput(data)
    sendRawOutput(buffer)

    if tag.die then error(msg, 3) end
  end

  function log.addRawOutput(out, useAnsiColor)
    table.insert(outputs.raw, {f = out, color = useAnsiColor})
  end

  function log.addOutput(out)
    table.insert(outputs.full, out)
  end

  function log.p(tag, ...)       writeToLog("p", tag, ...) end
  function log.fp(tag, fmt, ...) writeToLog("p", tag, string.format(fmt, ...)) end

  function log.i(tag, ...)       writeToLog("i", tag, ...) end
  function log.fi(tag, fmt, ...) writeToLog("i", tag, string.format(fmt, ...)) end

  function log.d(tag, ...)       writeToLog("d", tag, ...) end
  function log.fd(tag, fmt, ...) writeToLog("d", tag, string.format(fmt, ...)) end

  function log.w(tag, ...)       writeToLog("w", tag, ...) end
  function log.fw(tag, fmt, ...) writeToLog("w", tag, string.format(fmt, ...)) end

  function log.e(tag, ...)       writeToLog("e", tag, ...) end
  function log.fe(tag, fmt, ...) writeToLog("e", tag, string.format(fmt, ...)) end

  function log.f(tag, ...)       writeToLog("f", tag, ...) end
  function log.ff(tag, fmt, ...) writeToLog("f", tag, string.format(fmt, ...)) end

  function log.check(tag, value, ...) if not value then log.e(tag, ...) end end
  function log.fcheck(tag, value, fmt, ...) if not value then log.fe(tag, fmt, ...) end end

  function log.tag(tag)
    return setmetatable({}, {
      __index = function(t, k)
        return function(...) log[k](tag, ...) end
      end
    })
  end

  return log
end
