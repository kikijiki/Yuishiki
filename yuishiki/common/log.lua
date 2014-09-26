local Log = {
  Verbosity = {verbose = 3, normal = 2, minimal = 1, none = 0},
  color = ys.common.ansicolors
}

local inspect = ys.common.inspect
local ansicolors = ys.common.ansicolors.noReset

local outputs = {
  full = {},
  raw = {{f = print, color = true}}
}

local colors = {
  reset = ansicolors("%{reset}"),
  source = "",
  arrow = "",
  name = ansicolors("%{bright yellow}"),
  line = ansicolors("%{bright cyan}"),
  message = ""
}

Log.verbosity = Log.Verbosity.normal

local tags = {
  INF = {
    normal = "[INF]", 
    color = ansicolors("%{bright green}[INF]%{reset}"), 
    level = 3,
    die = false},
  DBG = {
    normal = "[DBG]", 
    color = ansicolors("%{bright black}[DBG]%{reset}"), 
    level = 2,
    die = false},
  WRN = {
    normal = "[WRN]", 
    color = ansicolors("%{bright yellow}[WRN]%{reset}"), 
    level = 2,
    die = false},
  ERR = {
    normal = "[ERR]", 
    color = ansicolors("%{bright red}[ERR]%{reset}"), 
    level = 1,
    die = true}
}

Log.showInfo = true
Log.showTime = true
Log.useAnsiColors = false

local function sendRawOutput(normal, colored)
  for _,out in pairs(outputs.raw) do
    if out.color then out.f(colored)
    else out.f(normal) end
  end
end

local function sendOutput(data)
  for _,out in pairs(outputs.full) do
    out(data)
  end
end

local function buildBuffer(buf, ...)
  local n = select("#", ...)
  for i=1, n do
    local s = tostring(select(i, ...))
    table.insert(buf, s)
    if i ~= n then table.insert(buf, "\t") end
  end  
end

local function writeToLog(tag_name, ...)
  local tag = tags[tag_name]
  if tag.level > Log.verbosity then return end
  
  local msg = {}
  local meta = {color = {}, normal = {}}
  local data = {}
  
  
  buildBuffer(msg, ...)
  local t = os.date("*t", os.time())
  local info = debug.getinfo(3)
  
  data.debug_info = info
  data.time = t
  data.msg = msg
  
  if Log.showTime then
    table.insert(meta, "["..t.hour..":"..t.min..":"..t.sec.."]")  
  end

  if Log.showInfo then
    local loginfoColor = {
      colors.source, (info.source or "[unknown]"), colors.reset,
      colors.arrow, "->", colors.reset, 
      colors.name, (info.name or "[unknown]"), colors.reset,
      "(", colors.line, tostring(info.currentline), colors.reset, ") ",
      colors.message}
      
    local loginfo = {
      (info.source or "[unknown]"), 
      "->", (info.name or "[unknown]"), 
      "(", tostring(info.currentline), ") "}
      
    table.insert(meta.normal, table.concat(loginfo))
    table.insert(meta.color, table.concat(loginfoColor))
  end
  
  local buffer = tag.normal..table.concat(meta.normal)..table.concat(msg)
  local buffer_color = tag.color..table.concat(meta.color)..table.concat(msg)
  
  sendOutput(data)
  sendRawOutput(buffer, buffer_color)
  if tag.die then error(table.concat(msg), 3) end
end

function Log.addRawOutput(out, useAnsiColor)
  table.insert(outputs.raw, {f = out, color = useAnsiColor})
end

function Log.addOutput(out)
  table.insert(outputs.full, out)
end

Log.i = function(...)
  writeToLog("INF", ...)
end

Log.d = function(...)
  writeToLog("DBG", ...)
end

Log.w = function(...)
  writeToLog("WRN", ...)
end

Log.e = function(...)
  writeToLog("ERR", ...)
end

Log.inspect = function(x)
  print(inspect(x))
end

Log.check = function(value, ...)
  if not value then writeToLog("ERR", 1, true, ...) end
end

return Log