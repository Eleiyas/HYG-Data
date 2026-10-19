local M = G.Class("ActivityProgressRewardPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local CELL_CLS = "UI/ActivityCenter/SubPanel/ProgressReward/ActivityProgressRewardCell"

function M:init()
  base.init(self)
  self._reward_cells = {}
  self._need_auto_position = false
end

function M:on_enable()
  base.on_enable(self)
  self._need_auto_position = true
  self:refresh()
end

function M:refresh()
  base.refresh(self)
  local data = self:get_activity_data()
  if data == nil then
    return
  end
  self:_refresh_progress_text(data)
  local reward_count = data.RewardCount
  if is_null(self._reward_item_binder) then
    Logger.LogWarning("[ActivityProgressRewardPanel] _reward_item_binder is missing on prefab.")
    return
  end
  for index = 1, reward_count do
    local cell = self._reward_cells[index]
    if cell == nil then
      local obj = self._reward_item_binder:AddItem(0)
      if not_null(obj) then
        cell = self:add_panel(CELL_CLS, obj)
        cell:set_claim_callback(function(clicked_entry)
          self:_on_reward_clicked(clicked_entry)
        end)
        self._reward_cells[index] = cell
      end
    end
    if cell ~= nil then
      local entry = data:GetRewardEntry(index - 1)
      if entry ~= nil then
        cell:set_active(true)
        cell:refresh(entry)
      else
        cell:set_active(false)
      end
    end
  end
  for index = reward_count + 1, #self._reward_cells do
    self._reward_cells[index]:set_active(false)
  end
  self:_try_auto_position_once(data, reward_count)
end

function M:_try_auto_position_once(data, reward_count)
  if not self._need_auto_position or reward_count <= 0 or is_null(self._scroll_level) then
    return
  end
  local target_index = self:_find_first_untaken_index(data, reward_count)
  if not self:_apply_auto_position(target_index) then
    return
  end
  self._need_auto_position = false
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    local latest_data = self:get_activity_data()
    if latest_data == nil or latest_data.RewardCount <= 0 then
      return
    end
    local latest_target_index = self:_find_first_untaken_index(latest_data, latest_data.RewardCount)
    self:_apply_auto_position(latest_target_index)
  end)
end

function M:_find_first_untaken_index(data, reward_count)
  for index = 1, reward_count do
    local entry = data:GetRewardEntry(index - 1)
    if entry ~= nil and not entry.IsTaken then
      return index
    end
  end
  return reward_count
end

function M:_apply_auto_position(target_index)
  local target_cell = self._reward_cells[target_index]
  if target_cell == nil or is_null(target_cell.rect_trans) or is_null(self._scroll_level) then
    return false
  end
  local content = self._scroll_level.content
  local viewport = self._scroll_level.viewport
  if is_null(content) or is_null(viewport) then
    return false
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(content)
  local scrollable_width = content.rect.width - viewport.rect.width
  local normalized_position = 0
  if 0 < scrollable_width then
    local target_rect = target_cell.rect_trans
    local target_center_x = target_rect.anchoredPosition.x + (0.5 - target_rect.pivot.x) * target_rect.rect.width
    local target_offset = target_center_x - viewport.rect.width * 0.5
    normalized_position = math.max(0, math.min(1, target_offset / scrollable_width))
  end
  self._scroll_level:StopMovement()
  self._scroll_level.horizontalNormalizedPosition = normalized_position
  return true
end

function M:_on_reward_clicked(entry)
  if entry == nil then
    return
  end
  local data = self:get_activity_data()
  if data == nil or data:IsClaiming() then
    return
  end
  if not entry.CanClaim then
    if entry.PreviewItemId ~= 0 then
      item_module:open_item_info_dialog(entry.PreviewItemId, entry.PreviewItemCount)
    end
    return
  end
  data:RequestClaim(entry.ConfigId, function()
    if is_null(self.game_obj) then
      return
    end
    local rewards = {}
    for index = 0, data.ClaimRewardCount - 1 do
      table.insert(rewards, {
        id = data:GetClaimRewardItemId(index),
        num = data:GetClaimRewardItemCount(index)
      })
    end
    self:_show_reward_dialog(rewards)
  end)
end

function M:_refresh_progress_text(data)
  local label_text_key = data:GetCurrentValueLabelTextKey()
  if not is_null(self._title_level) and string.is_valid(label_text_key) then
    UIUtil.set_text_by_id(self._title_level, label_text_key)
  end
  local value_text_key = data:GetCurrentValueTextKey()
  if not is_null(self._level_number) and string.is_valid(value_text_key) then
    UIUtil.set_text_by_id(self._level_number, value_text_key, tostring(data:GetCurrentValue()))
  end
end

function M:_show_reward_dialog(items)
  if items == nil or #items == 0 then
    return
  end
  common_ui_module:show_reward_dialog(nil, nil, items)
end

return M
