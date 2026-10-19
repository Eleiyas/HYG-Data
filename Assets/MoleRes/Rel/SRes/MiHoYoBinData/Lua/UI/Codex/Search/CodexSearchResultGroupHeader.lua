local M = G.Class("CodexSearchResultGroupHeader", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._is_refreshing = false
  self._scroller = nil
  self._node_index = nil
  self._on_expanded_changed = nil
  if not_null(self._tog_dropdown) then
    self:bind_callback(self._tog_dropdown, pack(self, M._on_toggle_changed))
  end
end

function M:refresh(data)
  self:set_active(true)
  self._scroller = data.scroller
  self._node_index = data.node_index
  self._on_expanded_changed = data.on_expanded_changed
  local title = data.title or ""
  if not_null(self._txt_title) then
    UIUtil.set_text(self._txt_title, title)
  elseif not_null(self._txt_group_name) then
    UIUtil.set_text(self._txt_group_name, title)
  end
  local count_text = tostring(data.count or 0)
  if not_null(self._txt_progress_num) then
    UIUtil.set_text(self._txt_progress_num, count_text)
  elseif not_null(self._txt_group_count) then
    UIUtil.set_text(self._txt_group_count, count_text)
  end
  self:refresh_expanded_state(data.is_expanded)
end

function M:refresh_expanded_state(is_expanded)
  if is_null(self._tog_dropdown) then
    return
  end
  self._is_refreshing = true
  self._tog_dropdown.isOn = is_expanded == true
  self._is_refreshing = false
end

function M:_on_toggle_changed()
  if self._is_refreshing then
    return
  end
  if is_null(self._scroller) or self._node_index == nil then
    return
  end
  self._scroller:ToggleNode(self._node_index, 0.15)
  if self._on_expanded_changed then
    self._on_expanded_changed(not self._scroller:IsNodeCollapsed(self._node_index))
  end
end

return M
