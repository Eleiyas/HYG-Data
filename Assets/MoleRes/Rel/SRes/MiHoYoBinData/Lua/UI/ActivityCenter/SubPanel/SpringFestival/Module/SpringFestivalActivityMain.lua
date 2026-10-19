spring_festival_activity_module = spring_festival_activity_module or {}
local TRACKING_NAVIGATION_RESOLVER_KEY = "spring_festival"

function spring_festival_activity_module:register_tracking_navigation()
  activity_center_module:register_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY, function(source_activity_id)
    return self:resolve_tracking_navigation(source_activity_id)
  end)
end

function spring_festival_activity_module:unregister_tracking_navigation()
  activity_center_module:unregister_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY)
end

function spring_festival_activity_module:resolve_tracking_navigation(source_activity_id)
  if self:is_corner_tracking_activity_id(source_activity_id) then
    return {
      host_activity_id = self.main_activity_id
    }
  end
  local page_key = self:get_page_key_by_tracking_activity_id(source_activity_id)
  if page_key == nil then
    return nil
  end
  return {
    host_activity_id = self.main_activity_id,
    open_content = function()
      self:open_page(page_key)
    end
  }
end

function spring_festival_activity_module:open_page(page_key)
  local entry = self.page_entry_by_key[page_key]
  if entry == nil then
    Logger.LogWarning("[SpringFestivalActivity] open_page: invalid page_key = " .. tostring(page_key))
    return
  end
  if not self:is_page_enterable(page_key) then
    Logger.Log("[SpringFestivalActivity] open_page: page not enterable, page_key = " .. tostring(page_key))
    return
  end
  UIManagerInstance:open(entry.page_class, {
    activity_id = self:get_page_representative_activity_id(page_key),
    page_key = page_key
  })
end

function spring_festival_activity_module:switch_page(from_page, to_key)
  if from_page == nil then
    Logger.LogWarning("[SpringFestivalActivity] switch_page: from_page is nil")
    return
  end
  local entry = self.page_entry_by_key[to_key]
  if entry == nil then
    Logger.LogWarning("[SpringFestivalActivity] switch_page: invalid to_key = " .. tostring(to_key))
    return
  end
  if from_page:get_page_key() == to_key then
    return
  end
  UIManagerInstance:open(entry.page_class, {
    activity_id = self:get_page_representative_activity_id(to_key),
    page_key = to_key,
    pending_close_guid = from_page.guid
  })
end

function spring_festival_activity_module:open_prewarm_task_memo()
  local task_id = self:get_prewarm_task_id()
  if task_id == 0 then
    Logger.LogWarning("[SpringFestivalActivity] open_prewarm_task_memo: prewarm task not configured.")
    return
  end
  if not self:is_prewarm_task_navigable(task_id) then
    Logger.LogWarning("[SpringFestivalActivity] 活动未开启，无法导航到备忘录.")
    return
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(task_id)
  local grouping_type = memo_module.grouping_type.none
  if not_null(step_cfg) then
    grouping_type = step_cfg.GroupingType or memo_module.grouping_type.none
  end
  if grouping_type == memo_module.grouping_type.none then
    Logger.LogWarning("[SpringFestivalActivity] open_prewarm_task_memo: invalid grouping_type, task_id = " .. tostring(task_id))
    return
  end
  UIManagerInstance:close_all_stack_window_without_main_page()
  memo_module:open_memo_page(false, memo_module.tab_type.task, grouping_type, task_id)
end

function spring_festival_activity_module:open_calendar_dialog()
  UIManagerInstance:open(self.calendar_dialog_class_path)
end

function spring_festival_activity_module:go_activity(tracking_id)
  local target = activity_center_module:make_feature_tracking_target(tracking_id)
  if target == nil then
    Logger.LogWarning("[SpringFestivalActivity] go_activity: feature tracking not configured, tracking_id = " .. tostring(tracking_id))
    return
  end
  activity_center_module:toggle_tracking(target)
end

function spring_festival_activity_module:refresh_red_dot()
  local data = self:get_main_activity_data()
  if data == nil then
    return
  end
  self:try_request_corner_open_tips()
  self:_try_request_riddle_reward_info()
  local mask = self:build_unlocked_slot_mask()
  data:SetUnlockedSlotMask(mask)
  if self._last_reported_slot_mask == mask then
    return
  end
  self._last_reported_slot_mask = mask
  self:notify_red_dot_dirty()
end

spring_festival_activity_module._riddle_reward_info_requested = false

function spring_festival_activity_module:_try_request_riddle_reward_info()
  if riddle_module == nil or self._riddle_reward_info_requested then
    return
  end
  if riddle_module:has_activity_info() then
    return
  end
  local unlocked = false
  for tab_index, entry in ipairs(self.lantern_tab_entries) do
    if entry.has_riddle_reward and self:is_lantern_tab_content_unlocked(tab_index) then
      unlocked = true
      break
    end
  end
  if not unlocked then
    return
  end
  self._riddle_reward_info_requested = true
  riddle_module:request_activity_info_if_needed()
end

function spring_festival_activity_module:mark_slot_read(slot_id)
  local data = self:get_main_activity_data()
  if data == nil then
    return
  end
  data:MarkSlotRead(slot_id)
  self:notify_red_dot_dirty()
end

function spring_festival_activity_module:mark_lantern_tab_read(tab_index)
  local slots = self.lantern_tab_red_dot_slots[tab_index]
  if slots == nil then
    return
  end
  for index = 1, #slots do
    local slot_id = slots[index]
    if self:has_slot_red_dot(slot_id) then
      self:mark_slot_read(slot_id)
    end
  end
end

function spring_festival_activity_module:mark_lantern_card_tip_read()
  for index = 1, #self.lantern_card_tip_slots do
    local slot_id = self.lantern_card_tip_slots[index]
    if self:has_slot_red_dot(slot_id) then
      self:mark_slot_read(slot_id)
    end
  end
end

function spring_festival_activity_module:on_lantern_daily_open_notify(notify)
  if notify == nil then
    return
  end
  local is_open = notify.IsOpen == true
  local activity_id = notify.ActivityId or 0
  local begin_time = notify.BeginTime or 0
  local end_time = notify.EndTime or 0
  if CsSpringFestivalModuleUtil ~= nil then
    CsSpringFestivalModuleUtil.UpdateLanternDailyOpenState(is_open, activity_id, begin_time, end_time)
  end
  local changed = self:apply_lantern_daily_open_state(is_open, activity_id, begin_time, end_time)
  if not changed then
    return
  end
  self:refresh_red_dot()
end

function spring_festival_activity_module:request_corner_open_hud_tip()
  EventCenter.Broadcast(EventID.LuaShowSpringFestivalCornerOpenTip, nil)
end

function spring_festival_activity_module:try_request_corner_open_tips()
  for corner_index = 1, #self.corner_activity_entries do
    if self:is_corner_open_tip_pending(corner_index) then
      self:request_corner_open_hud_tip()
      return
    end
  end
end

function spring_festival_activity_module:show_pending_corner_open_tips()
  for corner_index = 1, #self.corner_activity_entries do
    self:show_corner_open_tip(corner_index)
  end
end

function spring_festival_activity_module:show_corner_open_tip(corner_index)
  if not self:is_corner_open_tip_pending(corner_index) then
    return
  end
  local entry = self.corner_activity_entries[corner_index]
  local tip_state = entry ~= nil and entry.open_tip_state or nil
  if tip_state == nil then
    Logger.LogWarning("[SpringFestivalActivity] show_corner_open_tip: 第 " .. tostring(corner_index) .. " 个小活动没配 open_tip_state，不弹提示。")
    return
  end
  self:mark_corner_open_tip_shown(corner_index)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.spring_festival_corner_open_tip, tip_state)
end

function spring_festival_activity_module:notify_red_dot_dirty()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

function spring_festival_activity_module:toggle_tracking(target)
  activity_center_module:toggle_tracking(target)
end

return spring_festival_activity_module
