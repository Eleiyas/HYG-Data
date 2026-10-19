local M = G.Class("SpringFestivalLanternRiddlesTogglePanel", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalTogglePanelBase")

function M:on_selected(index)
  self._holder:on_toggle_selected(index)
end

function M:refresh()
  if self._slot_index == 0 or self._holder == nil then
    return
  end
  if not is_null(self._txt_title) then
    local text_id = self._holder:get_tab_title_text_id(self._slot_index)
    if string.is_valid(text_id) then
      UIUtil.set_text_by_id(self._txt_title, text_id)
    end
  end
  self:_refresh_red_dot()
end

function M:_refresh_red_dot()
  if is_null(self._redpoint) then
    return
  end
  local red_dot_type = spring_festival_activity_module:get_lantern_tab_red_dot_type(self._slot_index)
  self._redpoint:ShowRedPoint(red_dot_type)
end

return M
