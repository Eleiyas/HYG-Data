luca_heart_module = luca_heart_module or {}
luca_heart_module._cname = "luca_heart_module"
lua_module_mgr:require("UI/LucaHeart/LucaHeartUI")

function luca_heart_module:init()
  self:add_event()
end

function luca_heart_module:close()
  self:remove_event()
end

function luca_heart_module:add_event()
  score_system_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowDreamIn] = pack(self, luca_heart_module._on_enter_luca_heart)
  self._events[EventID.LuaLucaHeartClickTrack] = pack(self, luca_heart_module._on_click_track)
  self._events[EventID.LuaLucaHeartClickSlot] = pack(self, luca_heart_module._on_click_slot)
  self._events[EventID.LuaResetLucaSlot] = pack(self, luca_heart_module._on_reset_slot_luca)
  self._events[EventID.LuaShowLucaEditPage] = pack(self, luca_heart_module._on_show_edit_page)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function luca_heart_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function luca_heart_module:clear_on_disconnect()
end

function luca_heart_module:_on_enter_luca_heart()
  self:enter_luca_heart()
end

function luca_heart_module:_on_show_edit_page()
  UIManagerInstance:open("UI/LucaHeart/LucaHeartEditPage")
end

function luca_heart_module:_on_click_track(track_index)
  Logger.Log("露卡点了了Track" .. tostring(track_index))
end

function luca_heart_module:_on_click_slot(click_info)
  Logger.Log("露卡点了了Slot" .. tostring(click_info.TrackIndex) .. " " .. tostring(click_info.SlotIndex))
end

return luca_heart_module
