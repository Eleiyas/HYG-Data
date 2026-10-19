local M = G.Class("SpringFestival7DaysTogglePanel", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalTogglePanelBase")

function M:on_selected(day)
  self._holder:_on_toggle_selected(day)
end

function M:refresh()
  if self._slot_index == 0 then
    return
  end
  local module = spring_festival_activity_module
  local mission_state = module:get_seven_days_mission_state(self._slot_index)
  if not is_null(self._state_mission) then
    self._state_mission:SetState(mission_state)
  end
  if not is_null(self._txt_tognum) and (mission_state == module.seven_days_mission_state.new_unlocked or mission_state == module.seven_days_mission_state.unlocked) then
    UIUtil.set_text(self._txt_tognum, tostring(self._slot_index))
  else
  end
  if not is_null(self._redpoint) then
    local has_red_dot = module:has_slot_red_dot(module:get_seven_days_red_dot_slot(self._slot_index))
    self._redpoint:ShowRedPoint(has_red_dot and RedPointType.StrongRP or RedPointType.None)
  end
end

return M
