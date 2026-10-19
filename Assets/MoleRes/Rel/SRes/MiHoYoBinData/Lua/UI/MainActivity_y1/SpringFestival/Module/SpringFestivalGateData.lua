spring_festival_gate_module = spring_festival_gate_module or {}
local M = spring_festival_gate_module
local SPRING_NOTICE_TRACKER_ID = 8010
local FUKUBAG_CFG_ROW_ID = 1
M._drop_rate_up_activity_id_cache = nil

function M:_init_data()
  self._drop_rate_up_activity_id_cache = nil
end

local function _get_cfg_row()
  local fuku_cfg_type = not BFukuBagCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BFukuBagCfg
  if fuku_cfg_type == nil then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(fuku_cfg_type), FUKUBAG_CFG_ROW_ID)
end

function M:get_drop_rate_up_activity_id()
  if self._drop_rate_up_activity_id_cache ~= nil then
    return self._drop_rate_up_activity_id_cache
  end
  local row = _get_cfg_row()
  if row == nil then
    return 0
  end
  self._drop_rate_up_activity_id_cache = row.droprateuptime or 0
  return self._drop_rate_up_activity_id_cache
end

function M:get_activity_state(activity_id)
  activity_id = tonumber(activity_id) or 0
  if activity_id <= 0 then
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
  return tonumber(activity_data.State) or 0
end

function M:is_activity_opened(activity_id)
  activity_id = tonumber(activity_id) or 0
  if activity_id <= 0 then
    return false
  end
  return self:get_activity_state(activity_id) ~= 0
end

function M:is_activity_unlocked(activity_id)
  activity_id = tonumber(activity_id) or 0
  if activity_id <= 0 then
    return false
  end
  local state = self:get_activity_state(activity_id)
  return state == 2 or state == 3
end

function M:is_drop_rate_up_activity_opened()
  return self:is_activity_opened(self:get_drop_rate_up_activity_id())
end

function M:is_drop_rate_up_activity_unlocked()
  return self:is_activity_unlocked(self:get_drop_rate_up_activity_id())
end

function M:is_in_main_island()
  return level_module ~= nil and level_module.cur_level_is_main ~= nil and level_module:cur_level_is_main()
end

function M:is_common_notice_gate_open()
  return self:is_tracker_8010_pass() and self:is_drop_rate_up_activity_opened()
end

function M:is_tracker_8010_pass()
  if CsTrackerModuleUtil == nil then
    return false
  end
  local tracker_cfg = CsTrackerModuleUtil.GetTrackerCfgById(SPRING_NOTICE_TRACKER_ID)
  if tracker_cfg == nil then
    return false
  end
  local goal_progress_list = list_to_table(tracker_cfg.goalprogresslist)
  local target = goal_progress_list[1] or 0
  local tracker_data = CsTrackerModuleUtil.GetTrackerDataByCfgId(SPRING_NOTICE_TRACKER_ID)
  if tracker_data == nil or tracker_data.Condition == nil then
    return false
  end
  local current = tracker_data.Condition.TriggerCount or 0
  if target <= 0 then
    return false
  end
  return target <= current
end

return M
