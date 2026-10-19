local Logger = G.Class("Logger")

local function Log(msg)
  if ApplicationUtil.IsDebugMode() then
    print(debug.traceback(msg, 2))
  else
    CsLogUtil.Log(LogCat.Lua, debug.traceback(msg, 2))
  end
end

local function LogError(msg)
  if ApplicationUtil.IsDebugMode() then
    error(msg, 2)
  else
    CsLogUtil.LogError(LogCat.Lua, debug.traceback(msg, 2))
  end
end

local function LogWarning(msg)
  if ApplicationUtil.IsDebugMode() then
    CsLogUtil.LogWarning(LogCat.Lua, debug.traceback(msg, 2))
  else
    CsLogUtil.LogWarning(LogCat.Lua, debug.traceback(msg, 2))
  end
end

function event_err_handle(msg)
  LogError(msg)
end

Logger.Log = Log
Logger.LogError = LogError
Logger.LogWarning = LogWarning
return Logger
