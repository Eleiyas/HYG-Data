on_line_module = on_line_module or {}

function on_line_module:add_event()
  on_line_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOnGiveFish] = pack(self, on_line_module._handle_give_fish)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function on_line_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function on_line_module:_handle_give_fish(data)
  on_line_module:set_give_fish_data(data)
  on_line_module:set_is_change_give_fish_data_state(true)
  lua_event_module:send_event(lua_event_module.event_type.set_give_fish_panel_show_state, true)
end

return on_line_module
