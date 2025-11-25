on_line_module = on_line_module or {}

function on_line_module:hide_give_fish_panel()
  lua_event_module:send_event(lua_event_module.event_type.set_give_fish_panel_show_state, false)
end

function on_line_module:open_quick_chat_dialog()
  UIManagerInstance:open("UI/OnLine/QuickChatDialog")
end

return on_line_module
