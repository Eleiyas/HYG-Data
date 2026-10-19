local M = G.Class("CropGrowthPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CropGrowth/CropGrowthPage"
  self.config.type = EUIType.Page
  self._cur_level = 0
  self._view_level = 0
  self._max_level = 0
  self._task_items = {}
  self._rights_items = {}
  self._reward_items = {}
  self._is_upgrading = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._cur_level = crop_growth_module:get_cur_level()
  self._max_level = crop_growth_module:get_max_level()
  self._view_level = crop_growth_module:get_display_level()
  self._red_point_next:ShowRedPoint(RedPointType.None)
  self:_refresh_all()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnCropGrowthLevelChanged, function(new_level)
    self:_on_level_changed(new_level)
  end)
  self:add_evt_listener(EventID.OnMainSceneCropDataUpdate, function()
    self:_refresh_max_crop_num()
  end)
end

function M:_on_level_changed(new_level)
  self._cur_level = crop_growth_module:get_cur_level()
  self._max_level = crop_growth_module:get_max_level()
  if self._cur_level > self._max_level then
    self._view_level = self._max_level
  else
    self._view_level = self._cur_level - 1
    self._red_point_next:ShowRedPoint(RedPointType.NewRp)
  end
  self:_refresh_all()
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_help, pack(self, M._on_help_click))
  self:bind_callback(self._btn_next, pack(self, M._on_next_click))
  self:bind_callback(self._btn_last, pack(self, M._on_last_click))
  self:bind_callback(self._btn_finish, pack(self, M._on_finish_click))
end

function M:_refresh_all()
  local level = self._view_level
  UIUtil.set_text(self._txt_level, tostring(level))
  self:_refresh_task_list(level)
  self:_refresh_rights_list(level)
  self:_refresh_reward_list(level)
  self:_refresh_finish_btn(level)
  self:_refresh_page_btn(level)
  self:_refresh_max_crop_num()
end

function M:_refresh_task_list(level)
  local issue_id_list = crop_growth_module:get_issue_id_list(level)
  local count = #issue_id_list
  for i = 1, count do
    local item = self._task_items[i]
    if item == nil then
      local go = self._list_task:AddItem(0)
      item = self:add_panel("UI/CropGrowth/CropGrowthTaskItem", go)
      self._task_items[i] = item
    end
    item:refresh(issue_id_list[i], level)
  end
  for i = count + 1, #self._task_items do
    self._task_items[i]:set_active(false)
  end
end

function M:_refresh_rights_list(level)
  local unlocked = self:_is_unlocked(level)
  local rights_id_list = crop_growth_module:get_rights_id_list(level)
  local count = #rights_id_list
  for i = 1, count do
    local item = self._rights_items[i]
    if item == nil then
      local go = self._list_right:AddItem(0)
      item = self:add_panel("UI/CropGrowth/CropGrowthRightsItem", go)
      self._rights_items[i] = item
    end
    item:refresh(rights_id_list[i], unlocked)
  end
  for i = count + 1, #self._rights_items do
    self._rights_items[i]:set_active(false)
  end
end

function M:_refresh_reward_list(level)
  local reward_list = crop_growth_module:get_reward_item_list(level)
  local count = #reward_list
  for i = 1, count do
    local reward = reward_list[i]
    local item = self._reward_items[i]
    if item == nil then
      local go = self._list_reward:AddItem(0)
      item = self:add_panel(item_module.item_v2_panel_cls_name, go)
      self._reward_items[i] = item
    end
    item:set_active(true)
    item:set_item_data(reward.id, reward.num, nil)
    item:bind_item_info_btn(reward.id, false)
  end
  for i = count + 1, #self._reward_items do
    self._reward_items[i]:set_active(false)
  end
end

function M:_refresh_finish_btn(level)
  local is_finished = self:_is_unlocked(level)
  self._ui_state_group_finish:SetState(is_finished and 1 or 0)
  if is_finished then
    self._state_group_finish_btn:SetState(2)
    self._red_point:ShowRedPoint(RedPointType.None)
    return
  end
  local all_done = crop_growth_module:is_level_issues_all_done(level)
  if all_done then
    self._state_group_finish_btn:SetState(1)
    self._red_point:ShowRedPoint(RedPointType.GiftRP)
  else
    self._state_group_finish_btn:SetState(0)
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_refresh_page_btn(level)
  UIUtil.set_active(self._btn_last, 1 < level)
  local next_level = level + 1
  local has_next = next_level <= self._max_level
  UIUtil.set_active(self._btn_next, has_next)
  if has_next then
    self._ui_state_group_next:SetState(self:_can_view(next_level) and 0 or 1)
  end
end

function M:_refresh_max_crop_num()
  if not GameSceneUtility.GetCurrentSceneId() == 2 or not player_module:is_local_player_scene_owner() then
    UIUtil.set_active(self._txt_max_crop_num, false)
    return
  end
  UIUtil.set_active(self._txt_max_crop_num, true)
  local max_crop_num = CsWorldInfoLuaBridgeUtil.GetMaxCropNum()
  UIUtil.set_text_by_id(self._txt_max_crop_num, "CropManagement_PlantMax_Num", tostring(max_crop_num))
end

function M:_on_help_click()
  tutorial_module:open_tutorial_handbook_page_with_tutorial_id(6, 1, 1)
end

function M:_on_next_click()
  local next_level = self._view_level + 1
  if next_level > self._max_level then
    return
  end
  if not self:_can_view(next_level) then
    UIUtil.show_tips_by_text_id("PlantGrowth_NextLockTip")
    return
  end
  self._view_level = next_level
  self._red_point_next:ShowRedPoint(RedPointType.None)
  self:_refresh_all()
end

function M:_on_last_click()
  if self._view_level <= 1 then
    return
  end
  self._view_level = self._view_level - 1
  self:_refresh_all()
end

function M:_on_finish_click()
  if self._is_upgrading then
    return
  end
  if not self:_is_current_level(self._view_level) then
    return
  end
  if not crop_growth_module:is_can_upgrade() then
    return
  end
  local level = self._view_level
  self._is_upgrading = true
  crop_growth_module:do_upgrade(function(success)
    self:_on_upgrade_result(level, success)
  end)
end

function M:_on_upgrade_result(level, success)
  self._is_upgrading = false
  if not success then
    return
  end
  local reward_list = crop_growth_module:get_reward_item_list(level)
  if 0 < #reward_list then
    common_ui_module:show_reward_dialog(nil, nil, reward_list)
  end
end

function M:_can_view(level)
  return level <= crop_growth_module:get_display_level()
end

function M:_is_unlocked(level)
  return level < self._cur_level
end

function M:_is_current_level(level)
  return level == self._cur_level
end

return M
