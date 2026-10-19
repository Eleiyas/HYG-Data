local Base = require("UI/Codex/Module/ListRenderer/CodexListRendererBase")
local M = G.Class("CodexSetFlatListRenderer", Base)

function M:render(init_position)
  local panel = self._panel
  local scroller = panel:get_set_scroller()
  local scroll_rect = panel:get_set_scroll_rect()
  if is_null(scroller) or is_null(scroll_rect) then
    return
  end
  UIUtil.set_active(scroll_rect, true)
  local flat_sr = panel:get_flat_scroll_rect()
  if not_null(flat_sr) then
    UIUtil.set_active(flat_sr, false)
  end
  local grouped_root = panel:get_grouped_root()
  if not_null(grouped_root) then
    UIUtil.set_active(grouped_root, false)
  end
  local count_group = panel._sub_type_controller:get_data_group_counts()
  scroller:Init(pack(self, M._on_item_refresh), count_group)
  scroll_rect.normalizedPosition = init_position or Vector2(0, 1)
  scroller:RefreshCurrent()
end

function M:deactivate()
  local sr = self._panel:get_set_scroll_rect()
  if not_null(sr) then
    UIUtil.set_active(sr, false)
  end
end

function M:stop_movement()
  local sr = self._panel:get_set_scroll_rect()
  if not_null(sr) then
    sr:StopMovement()
  end
end

function M:record_position()
  local sr = self._panel:get_set_scroll_rect()
  if not_null(sr) then
    return sr.normalizedPosition
  end
  return nil
end

function M:scroll_to(position)
  local sr = self._panel:get_set_scroll_rect()
  if not_null(sr) then
    sr.normalizedPosition = position
    sr:StopMovement()
    self._panel:get_set_scroller():RefreshCurrent()
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
  local scroller = panel:get_set_scroller()
  local sr = panel:get_set_scroll_rect()
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

function M:close()
  local scroller = self._panel:get_set_scroller()
  if not_null(scroller) then
    scroller:Close()
  end
end

function M:scroll_to_first_reward_package()
  local panel = self._panel
  local scroller = panel:get_set_scroller()
  local scroll_rect = panel:get_set_scroll_rect()
  if is_null(scroller) or is_null(scroll_rect) then
    return false
  end
  local controller = panel._sub_type_controller
  if not controller then
    return false
  end
  local count = controller:get_item_count()
  for i = 1, count do
    local data = controller:get_data_by_sequence(i)
    if data then
      local suite = data.ServerData and data.ServerData.Suite
      if not_null(suite) and suite.CompleteTime > 0 and not suite.IsCompleteRewardTaken then
        scroller:MoveTo(i - 1)
        scroll_rect:StopMovement()
        scroller:RefreshCurrent()
        return true
      end
    end
  end
  return false
end

function M:_is_item_claimable(i)
  local controller = self._panel._sub_type_controller
  if not controller then
    return false
  end
  local data = controller:get_data_by_sequence(i)
  if not data then
    return false
  end
  local suite = data.ServerData and data.ServerData.Suite
  return not_null(suite) and suite.CompleteTime > 0 and not suite.IsCompleteRewardTaken
end

function M:_estimate_item_position(i, count)
  local scroller = self._panel:get_set_scroller()
  local col = math.max(1, scroller.Col)
  local item_h = scroller.ItemSize.y
  local scroll_rect = self._panel:get_set_scroll_rect()
  local content_h = scroll_rect.content.rect.height
  local total_rows = math.ceil(count / col)
  local padding_total = math.max(0, content_h - total_rows * item_h)
  local padding_top = padding_total * 0.5
  local row = math.floor((i - 1) / col)
  local item_top = padding_top + row * item_h
  return item_top, item_h
end

function M:get_reward_directions()
  local scroll_rect = self._panel:get_set_scroll_rect()
  local scroller = self._panel:get_set_scroller()
  if is_null(scroll_rect) or is_null(scroll_rect.viewport) or is_null(scroller) then
    return false, false
  end
  local controller = self._panel._sub_type_controller
  if not controller then
    return false, false
  end
  local count = controller:get_item_count()
  if count <= 0 then
    return false, false
  end
  local view_top = scroll_rect.content.anchoredPosition.y
  local view_bottom = view_top + scroll_rect.viewport.rect.height
  local has_above, has_below = false, false
  for i = 1, count do
    if self:_is_item_claimable(i) then
      local item_top, item_h = self:_estimate_item_position(i, count)
      if view_top >= item_top + item_h * 0.15 then
        has_above = true
      elseif view_bottom <= item_top then
        has_below = true
      end
    end
    if has_above and has_below then
      break
    end
  end
  return has_above, has_below
end

function M:scroll_to_nearest_reward(direction)
  local scroller = self._panel:get_set_scroller()
  local scroll_rect = self._panel:get_set_scroll_rect()
  if is_null(scroller) or is_null(scroll_rect) or is_null(scroll_rect.viewport) then
    return false
  end
  local controller = self._panel._sub_type_controller
  if not controller then
    return false
  end
  local count = controller:get_item_count()
  if count <= 0 then
    return false
  end
  local view_top = scroll_rect.content.anchoredPosition.y
  local view_bottom = view_top + scroll_rect.viewport.rect.height
  local best_index
  for i = 1, count do
    if self:_is_item_claimable(i) then
      local item_top, item_h = self:_estimate_item_position(i, count)
      if direction == "above" and view_top >= item_top + item_h * 0.15 then
        best_index = i
      elseif direction == "below" and view_bottom <= item_top then
        best_index = i
        break
      end
    end
  end
  if best_index then
    scroller:MoveTo(best_index - 1)
    scroll_rect:StopMovement()
    scroller:RefreshCurrent()
    return true
  end
  return false
end

function M:_on_item_refresh(trans, index)
  self._panel:_refresh_item(trans, index)
end

return M
