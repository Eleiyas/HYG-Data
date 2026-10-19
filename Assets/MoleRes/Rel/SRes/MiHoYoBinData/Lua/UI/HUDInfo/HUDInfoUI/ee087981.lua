hud_info_module = hud_info_module or {}
hud_info_module._cname = "hud_info_module"

function hud_info_module:show_hud_info_ui(ui_type, ui_data)
  lua_event_module:send_event(lua_event_module.event_type.add_hud_info_ui, ui_type, ui_data)
end

function hud_info_module:remove_hud_info_ui(ui_type)
  lua_event_module:send_event(lua_event_module.event_type.remove_hud_info_ui, ui_type)
end

return hud_info_module or {}
