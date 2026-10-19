lua_event_module = lua_event_module or {}
lua_event_module._cname = "lua_event_module"
lua_module_mgr:require("LuaEvent/LuaEventCommon")
lua_module_mgr:require("LuaEvent/LuaEventMain")
lua_event_module.require_names = {
  "LuaEvent/LuaEventCommon",
  "LuaEvent/LuaEventMain"
}

function lua_event_module:init()
  self._listeners = {}
end

function lua_event_module:close()
  close_tbl(self._listeners)
end

return lua_event_module
