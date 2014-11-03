local log

return function(loader)
  if log then return log end

  local ansicolors = loader.require "ansicolors".noReset

  log = {
    Verbosity = {verbose = 3, normal = 2, minimal = 1, none = 0},
    showInfo = true,
    showTime = true,
    useAnsiColors = false,
    verbosity = 3
  }

  local outputs = {
    full = {},
    raw = {print}
  }

  local colors = {
    reset = ansicolors("%{reset}"),
    source = "",
    arrow = "",
    name = ansicolors("%{bright yellow}"),
    line = ansicolors("%{bright cyan}"),
    message = ""
  }

  local tags = {
    p = {
      normal = "",
      color = "",
      level = 3,
      die = false},
    i = {
      normal = "[INF]",
      color = ansicolors("%{bright green}[INF]%{reset}"),
      level = 3,
      die = false},
    d = {
      normal = "[DBG]",
      color = ansicolors("%{bright black}[DBG]%{reset}"),
      level = 2,
      die = false},
    w = {
      normal = "[WRN]",
      color = ansicolors("%{bright yellow}[WRN]%{reset}"),
      level = 2,
      die = false},
    e = {
      normal = "[ERR]",
      color = ansicolors("%{bright red}[ERR]%{reset}"),
      level = 1,
      die = false},
    f = {
      normal = "[FAT]",
      color = ansicolors("%{bright red}[FAT]%{reset}"),
      level = 0,
      die = true}
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

  local function writeToLog(tag_name, ...)
    local tag = tags[tag_name]
    if tag.level > log.verbosity then return end

    local data = {}
    data.tag = tag_name
    data.msg = buildBuffer(...)
    data.time = os.date("*t", os.time())
    data.info = debug.getinfo(3)

    local timestamp
    if log.showTime then
      timestamp = "["..data.time.hour..":"..data.time.min..":"..data.time.sec.."]"
    else
      timestamp = ""
    end

    if log.useAnsiColors then
      tag = tag.color
      data.meta = {
        timestamp,
        colors.source, (data.info.source or "[unknown]"), colors.reset,
        colors.arrow, "->", colors.reset,
        colors.name, (data.info.name or "[unknown]"), colors.reset,
        "(", colors.line, tostring(data.info.currentline), colors.reset, ") ",
        colors.message}
    else
      tag = tag.normal
      data.meta = {
        timestamp,
        (data.info.source or "[unknown]"),
        "->", (data.info.name or "[unknown]"),
        "(", tostring(data.info.currentline), ") "}
    end

    data.meta = table.concat(data.meta)

    local buffer
    if log.showInfo then
      buffer = tag..data.info..data.msg
    else
      buffer = tag..data.msg
    end

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

  function log.p(...)       writeToLog("p", ...) end
  function log.fp(fmt, ...) writeToLog("p", string.format(fmt, ...)) end

  function log.i(...)       writeToLog("i", ...) end
  function log.fi(fmt, ...) writeToLog("i", string.format(fmt, ...)) end

  function log.d(...)       writeToLog("d", ...) end
  function log.fd(fmt, ...) writeToLog("d", string.format(fmt, ...)) end

  function log.w(...)       writeToLog("w", ...) end
  function log.fw(fmt, ...) writeToLog("w", string.format(fmt, ...)) end

  function log.e(...)       writeToLog("e", ...) end
  function log.fe(fmt, ...) writeToLog("e", string.format(fmt, ...)) end

  function log.f(...)       writeToLog("f", ...) end
  function log.ff(fmt, ...) writeToLog("f", string.format(fmt, ...)) end

  function log.check(value, ...)
    if not value then writeToLog("e", 1, true, ...) end
  end

  function log.fcheck(value, fmt, ...)
    if not value then writeToLog("e", 1, true, string.format(fmt, ...)) end
  end

  return log
end
