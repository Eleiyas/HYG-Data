activity_center_module = activity_center_module or {}

function activity_center_module:has_activity(activity_id)
  return CsActivityCenterModuleUtil.HasActivity(activity_id)
end

function activity_center_module:get_activity_by_id(activity_id)
  return CsActivityCenterModuleUtil.GetActivityById(activity_id)
end

function activity_center_module:get_activity_state(activity_id)
  local data = self:get_activity_by_id(activity_id)
  if data == nil then
    return self.activity_state.None
  end
  return data.State
end

function activity_center_module:get_logic_cfg(activity_id)
  local data = self:get_activity_by_id(activity_id)
  if data == nil or not data.HasLogicCfg then
    return nil
  end
  return data.LogicCfg
end

function activity_center_module:get_ui_cfg(activity_id)
  local data = self:get_activity_by_id(activity_id)
  if data == nil or not data.HasUICfg then
    return nil
  end
  return data.UICfg
end

function activity_center_module:get_prefab_path(activity_id)
  local ui_cfg = self:get_ui_cfg(activity_id)
  if ui_cfg == nil then
    return ""
  end
  return ui_cfg.uiprefab
end

function activity_center_module:is_tracker_reached(tracker_id)
  if tracker_id == nil or tracker_id == 0 then
    return true
  end
  local goal = self:get_tracker_goal(tracker_id)
  if goal <= 0 then
    return false
  end
  local tracker_data = CsTrackerModuleUtil.GetTrackerDataByCfgId(tracker_id)
  if tracker_data == nil or tracker_data.Condition == nil then
    return false
  end
  return goal <= (tracker_data.Condition.TriggerCount or 0)
end

function activity_center_module:is_open_tracker_satisfied(activity_id)
  return self:is_tracker_reached(self:get_open_tracker_id(activity_id))
end

function activity_center_module:is_finish_tracker_satisfied(activity_id)
  local finish_tracker_id = self:get_finish_tracker_id(activity_id)
  if finish_tracker_id == 0 then
    return false
  end
  return self:is_tracker_reached(finish_tracker_id)
end

function activity_center_module:get_visible_activity_ids()
  local cs_list = CsActivityCenterModuleUtil.GetVisibleActivityIds()
  return list_to_table(cs_list)
end

function activity_center_module:get_ids_by_category(category)
  local cs_list = CsActivityCenterModuleUtil.GetActivitiesByTabCategory(category)
  local count = cs_list ~= nil and cs_list.Count or 0
  if count == 0 then
    return {}
  end
  local filtered = {}
  for i = 0, count - 1 do
    local data = cs_list[i]
    if data ~= nil and data.HasUICfg then
      table.insert(filtered, {
        id = data.Id,
        priority = data.UICfg.priority or 0
      })
    end
  end
  table.sort(filtered, function(a, b)
    if a.priority ~= b.priority then
      return a.priority > b.priority
    end
    return a.id < b.id
  end)
  local ret = {}
  for _, e in ipairs(filtered) do
    table.insert(ret, e.id)
  end
  return ret
end

function activity_center_module:is_activity_list_host(activity_id)
  if activity_id == nil or activity_id <= 0 or not self:has_activity(activity_id) then
    return false
  end
  local category = self:get_category_by_activity_id(activity_id)
  local ids = self:get_ids_by_category(category)
  for _, id in ipairs(ids) do
    if id == activity_id then
      return true
    end
  end
  return false
end

function activity_center_module:get_category_by_activity_id(activity_id)
  local ui_cfg = self:get_ui_cfg(activity_id)
  if ui_cfg == nil then
    return activity_center_module.default_category
  end
  return ui_cfg.tab
end

function activity_center_module:get_red_dot_type(activity_id)
  return CsActivityCenterModuleUtil.GetRedDotType(activity_id)
end

function activity_center_module:get_any_red_dot_type_by_tab_category(category)
  return CsActivityCenterModuleUtil.GetAnyRedDotTypeByTabCategory(category)
end

function activity_center_module:get_any_red_dot_type()
  return CsActivityCenterModuleUtil.GetAnyRedDotType()
end

function activity_center_module:get_task_name_and_desc(task_id)
  if task_id == nil or task_id == 0 then
    return "", ""
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(task_id)
  if is_null(step_cfg) then
    return "", ""
  end
  return step_cfg.name_l10n:ToString(), step_cfg.desc_l10n:ToString()
end

local EMPTY_REWARD_ID_LIST = {}
local page_reward_item_ids_cache = {}
local page_reward_item_ids_by_order_cache = {}
local REWARD_CACHE_KEY_STRIDE = 1000

local function append_unique_item_ids(target, added_item_ids, source)
  for index = 1, #source do
    local item_id = source[index]
    if not added_item_ids[item_id] then
      added_item_ids[item_id] = true
      target[#target + 1] = item_id
    end
  end
end

local function build_reward_item_ids(tool_ids, task_ids)
  local item_ids = {}
  local added_item_ids = {}
  if 0 < #tool_ids then
    append_unique_item_ids(item_ids, added_item_ids, tool_ids)
    return item_ids
  end
  if #task_ids == 0 then
    return EMPTY_REWARD_ID_LIST
  end
  local cfg_data = task_module:get_task_cfg_data()
  if is_null(cfg_data) then
    return item_ids
  end
  for index = 1, #task_ids do
    local reward_item_ids = list_to_table(cfg_data:GetTaskRewardItemIds(task_ids[index]))
    append_unique_item_ids(item_ids, added_item_ids, reward_item_ids)
  end
  return item_ids
end

function activity_center_module:get_page_reward_item_ids(page_id, image_id)
  image_id = image_id or 0
  local cache_key = page_id * REWARD_CACHE_KEY_STRIDE + image_id
  local cached = page_reward_item_ids_cache[cache_key]
  if cached ~= nil then
    return cached
  end
  local item_ids = build_reward_item_ids(self:get_sub_page_tool_ids(page_id, image_id), self:get_sub_page_tool_task_ids(page_id, image_id))
  page_reward_item_ids_cache[cache_key] = item_ids
  return item_ids
end

function activity_center_module:get_page_reward_item_ids_by_order(page_id, order_index)
  if order_index == nil then
    return EMPTY_REWARD_ID_LIST
  end
  local cache_key = page_id * REWARD_CACHE_KEY_STRIDE + order_index
  local cached = page_reward_item_ids_by_order_cache[cache_key]
  if cached ~= nil then
    return cached
  end
  local item_ids = build_reward_item_ids(self:get_page_tool_ids_by_order(page_id, order_index), self:get_page_tool_task_ids_by_order(page_id, order_index))
  page_reward_item_ids_by_order_cache[cache_key] = item_ids
  return item_ids
end

function activity_center_module:is_tracking_tasks_finished(tracking_id)
  local memo_ids = self:get_tracking_memo_ids(tracking_id)
  if #memo_ids == 0 then
    return false
  end
  for index = 1, #memo_ids do
    if not task_module:task_is_finish(memo_ids[index]) then
      return false
    end
  end
  return true
end

function activity_center_module:get_navigable_task_id_from_list(task_ids)
  if task_ids == nil or #task_ids == 0 then
    return 0
  end
  local task_data = task_module:get_task_data()
  if is_null(task_data) then
    return 0
  end
  for index = 1, #task_ids do
    local task_id = task_ids[index]
    if self.memo_navigable_task_states[task_data:GetTaskState(task_id)] then
      return task_id
    end
  end
  return 0
end

function activity_center_module:is_task_navigable(task_id)
  if task_id == nil or task_id == 0 then
    return false
  end
  local task_data = task_module:get_task_data()
  if is_null(task_data) then
    return false
  end
  return self.memo_navigable_task_states[task_data:GetTaskState(task_id)] == true
end

function activity_center_module:make_task_tracking_target(task_id)
  if task_id == nil or task_id == 0 then
    return nil
  end
  return {
    kind = self.tracking_kind.task,
    track_type = tracking_module.track_type.memo,
    source_type = tracking_module.data_source_type.task,
    tracking_id = task_id
  }
end

function activity_center_module:make_feature_tracking_target(tracking_cfg_id)
  if tracking_cfg_id == nil or tracking_cfg_id == 0 then
    return nil
  end
  local json_id = self:get_tracking_json_id(tracking_cfg_id)
  local activity_id = self:get_tracking_activity_id(tracking_cfg_id)
  if json_id == 0 or activity_id == 0 then
    return nil
  end
  return {
    kind = self.tracking_kind.feature,
    track_type = tracking_module.track_type.feature,
    source_type = tracking_module.data_source_type.activity,
    tracking_id = activity_id,
    tracking_cfg_id = tracking_cfg_id,
    json_id = json_id
  }
end

function activity_center_module:get_tracking_button_text(target)
  if target == nil or target.kind ~= self.tracking_kind.feature then
    return nil
  end
  local text = CsActivityCenterModuleUtil.GetTrackingButtonText(target.tracking_id)
  return string.is_valid(text) and text or nil
end

function activity_center_module:make_tracking_target_by_id(tracking_id)
  if tracking_id == nil or tracking_id == 0 then
    return nil
  end
  local task_id = self:get_navigable_task_id_from_list(self:get_tracking_memo_ids(tracking_id))
  if task_id ~= 0 then
    return self:make_task_tracking_target(task_id)
  end
  return self:make_feature_tracking_target(tracking_id)
end

function activity_center_module:is_tracking(target)
  if target == nil then
    return false
  end
  return tracking_module:is_tracking_by_track_type(target.track_type, target.source_type, target.tracking_id) == true
end

local activity_time_cache = {}

function activity_center_module:get_activity_time_range(activity_id)
  if activity_id == nil or activity_id == 0 then
    return nil
  end
  local cached = activity_time_cache[activity_id]
  if cached ~= nil then
    return cached
  end
  local data = self:get_activity_by_id(activity_id)
  if data == nil then
    return nil
  end
  local range = {
    start_time = data.StartTimeUtcSec,
    end_time = data.EndTimeUtcSec
  }
  activity_time_cache[activity_id] = range
  return range
end

function activity_center_module:clear_activity_time_cache()
  table.clear(activity_time_cache)
end

function activity_center_module:get_activity_time_phase(activity_id)
  local phase = self.activity_time_phase
  local range = self:get_activity_time_range(activity_id)
  if range == nil then
    return phase.none, 0
  end
  local start_time = range.start_time
  local end_time = range.end_time
  if start_time == 0 and end_time == 0 then
    return phase.none, 0
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  if start_time ~= 0 and start_time > now then
    return phase.before_start, start_time - now
  end
  if end_time == 0 then
    return phase.none, 0
  end
  if end_time <= now then
    return phase.ended, 0
  end
  return phase.running, end_time - now
end

function activity_center_module:get_activity_end_time_utc(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return 0
  end
  local activity_data
  if activity_center_module ~= nil and activity_center_module.get_activity_by_id ~= nil then
    activity_data = activity_center_module:get_activity_by_id(activity_id)
  elseif CsActivityCenterModuleUtil ~= nil and CsActivityCenterModuleUtil.GetActivityById ~= nil then
    activity_data = CsActivityCenterModuleUtil.GetActivityById(activity_id)
  end
  if activity_data == nil then
    return 0
  end
  return tonumber(activity_data.EndTimeUtcSec) or 0
end

return activity_center_module
