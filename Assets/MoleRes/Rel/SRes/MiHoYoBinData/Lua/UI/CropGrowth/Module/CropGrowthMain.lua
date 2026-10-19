crop_growth_module = crop_growth_module or {}

function crop_growth_module:add_event()
  crop_growth_module:remove_event()
  self._events = {}
  self._events[EventID.TrackerUpdateNotify] = pack(self, crop_growth_module._on_tracker_update)
  self._events[EventID.OnCropGrowthLevelChanged] = pack(self, crop_growth_module.mark_red_point_dirty)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function crop_growth_module:_on_tracker_update(tracker_id)
  tracker_id = tonumber(tracker_id)
  if tracker_id == nil or tracker_id <= 0 then
    return
  end
  local cur_level = self:get_cur_level()
  if cur_level > self:get_max_level() then
    return
  end
  local level_cfg = self:get_level_cfg(cur_level)
  if is_null(level_cfg) then
    return
  end
  for i = 0, level_cfg.issuelistLength - 1 do
    local issue_cfg = self:get_issue_cfg(tonumber(level_cfg:issuelist(i)))
    if issue_cfg ~= nil and issue_cfg.trackerid == tracker_id then
      self:mark_red_point_dirty()
      return
    end
  end
end

function crop_growth_module:mark_red_point_dirty()
  red_point_util:mark_mobile_red_point_state_dirty("crop_growth")
  EventCenter.Broadcast(EventID.RefreshPhoneRed, nil)
end

function crop_growth_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function crop_growth_module:open_page()
  if not UIManagerInstance:is_show("UI/CropGrowth/CropGrowthPage") then
    UIManagerInstance:open("UI/CropGrowth/CropGrowthPage", nil)
  end
end

function crop_growth_module:close_page()
  local page = UIManagerInstance:is_show("UI/CropGrowth/CropGrowthPage")
  if page ~= nil and page.is_active then
    UIManagerInstance:close(page.guid)
  end
end

function crop_growth_module:get_issue_progress(issue_cfg)
  local result = {
    trigger = 0,
    goal = 0,
    is_done = false
  }
  if issue_cfg == nil then
    return result
  end
  local tracker_id = issue_cfg.trackerid
  result.goal = issue_cfg.issuegoal or 0
  if tracker_id == nil or tracker_id <= 0 then
    return result
  end
  local tracker_data = CsTrackerModuleUtil.GetTrackerDataByCfgId(tracker_id)
  if is_null(tracker_data) then
    return result
  end
  if not_null(tracker_data.Condition) then
    result.trigger = tracker_data.Condition.TriggerCount or 0
    if issue_cfg.usetrackergoal == 1 then
      result.goal = tracker_data.Condition.GoalCount or result.goal
    end
  end
  result.is_done = issue_cfg.usetrackergoal == 1 and tracker_data.IsDone == true or 0 < result.goal and result.trigger >= result.goal
  return result
end

function crop_growth_module:is_level_issues_all_done(level)
  local issue_id_list = self:get_issue_id_list(level)
  if #issue_id_list == 0 then
    return false
  end
  for i = 1, #issue_id_list do
    local issue_cfg = self:get_issue_cfg(issue_id_list[i])
    local progress = self:get_issue_progress(issue_cfg)
    if not progress.is_done then
      return false
    end
  end
  return true
end

function crop_growth_module:do_upgrade(callback)
  CsCropGrowthModuleUtil.DoUpgrade(callback)
end

return crop_growth_module
