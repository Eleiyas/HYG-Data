local Base = require("UI/Codex/Module/ListRenderer/CodexListRendererBase")
local M = G.Class("CodexFlatListRenderer", Base)

function M:render(init_position)
  local panel = self._panel
  local scroller = panel:get_flat_scroller()
  local scroll_rect = panel:get_flat_scroll_rect()
  local grouped_root = panel:get_grouped_root()
  UIUtil.set_active(scroll_rect, true)
  if not_null(grouped_root) then
    UIUtil.set_active(grouped_root, false)
  end
  local set_sr = panel:get_set_scroll_rect()
  if not_null(set_sr) then
    UIUtil.set_active(set_sr, false)
  end
  local count_group = panel._sub_type_controller:get_data_group_counts()
  scroller:Init(pack(self, M._on_item_refresh), count_group, pack(self, M._on_group_header))
  if not_null(scroll_rect) then
    scroll_rect.normalizedPosition = init_position or Vector2(0, 1)
  end
  scroller:RefreshCurrent()
end

function M:deactivate()
  UIUtil.set_active(self._panel:get_flat_scroll_rect(), false)
end

function M:stop_movement()
  local sr = self._panel:get_flat_scroll_rect()
  if not_null(sr) then
    sr:StopMovement()
  end
end

function M:record_position()
  local sr = self._panel:get_flat_scroll_rect()
  if not_null(sr) then
    return sr.normalizedPosition
  end
  return nil
end

function M:close()
  local scroller = self._panel:get_flat_scroller()
  if not_null(scroller) then
    scroller:Close()
  end
end

function M:scroll_to(position)
  local sr = self._panel:get_flat_scroll_rect()
  if not_null(sr) then
    sr.normalizedPosition = position
    sr:StopMovement()
    self._panel:get_flat_scroller():RefreshCurrent()
  end
end

function M:scroll_to_item_id(id)
  local panel = self._panel
  if not panel._sub_type_controller or not id then
    return false
  end
  local seq = panel._sub_type_controller:get_global_sequence_by_id(id)
  if not seq or seq <= 0 then
    return false
  end
  local scroller = panel:get_flat_scroller()
  local sr = panel:get_flat_scroll_rect()
  if is_null(scroller) or not scroller.MoveTo then
    return false
  end
  scroller:MoveTo(seq - 1)
  if not_null(sr) then
    sr:StopMovement()
  end
  if scroller.RefreshCurrent then
    scroller:RefreshCurrent()
  end
  return true
end

function M:_on_item_refresh(trans, index)
  self._panel:_refresh_item(trans, index)
end

function M:_on_group_header(trans, group_index)
  self._panel:_refresh_group_header(trans, group_index)
end

return M
