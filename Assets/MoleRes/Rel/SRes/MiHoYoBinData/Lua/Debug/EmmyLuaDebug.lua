local debug_cfg = CS.miHoYo.HYG.LuaBridge.CsLocalSaveDataUtil.GetDic(CS.miHoYo.HYG.LocalSaveID.LuaDebug)
local is_debug_connect = false
print(type(debug_cfg))
local _, debug_on = debug_cfg:TryGetValue("debugOn")
if debug_on == "true" then
  is_debug_connect = true
end
local _, path = debug_cfg:TryGetValue("debugDllPath")
if path == nil then
  path = ""
end
if is_debug_connect then
  package.cpath = package.cpath .. ";" .. path
  local dbg = require("emmy_core")
  dbg.tcpConnect("localhost", 9966)
end
