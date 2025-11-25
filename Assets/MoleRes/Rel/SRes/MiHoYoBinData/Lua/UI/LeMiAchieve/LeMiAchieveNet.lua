le_mi_achievement_module = le_mi_achievement_module or {}

function le_mi_achievement_module:register_cmd_handler()
  le_mi_achievement_module:un_register_cmd_handler()
  self._tbl_rep = {}
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function le_mi_achievement_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, _ in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function le_mi_achievement_module:finish_achieve_req(achieve_id)
  if achieve_id <= 0 then
    return false
  end
  if not le_mi_achievement_module:achieve_is_can_get(achieve_id) then
    return false
  end
  local data = {AchieveGroupId = achieve_id}
  NetHandlerIns:send_data(FinishAchieveReq, data)
  return true
end

function le_mi_achievement_module:finish_daily_task_req(task_id)
  local data = {DailyTaskId = task_id}
  NetHandlerIns:send_data(FinishDailyTaskReq, data)
end

function le_mi_achievement_module:regenerate_daily_task_req(task_id)
  local data = {TargetTaskId = task_id}
  NetHandlerIns:send_data(RegenerateDailyTaskReq, data)
end

return le_mi_achievement_module
