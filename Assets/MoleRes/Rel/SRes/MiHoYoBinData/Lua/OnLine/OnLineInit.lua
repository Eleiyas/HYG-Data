on_line_module = on_line_module or {}
on_line_module._cname = "on_line_module"
lua_module_mgr:require("OnLine/OnLineNet")
lua_module_mgr:require("OnLine/OnLineData")
lua_module_mgr:require("OnLine/OnLineUI")
lua_module_mgr:require("OnLine/OnLineMain")

function on_line_module:init()
  self._events = nil
  on_line_module:reset_server_data()
  on_line_module:add_event()
  on_line_module:register_cmd_handler()
end

function on_line_module:close()
  on_line_module:remove_event()
  on_line_module:un_register_cmd_handler()
end

function on_line_module:reset_server_data()
  self._give_fish_data = nil
  self._is_change_give_fish_data = false
end

function on_line_module:clear_on_disconnect()
  on_line_module:reset_server_data()
end

return on_line_module
