task_module = task_module or {}

function task_module:add_event()
  task_module:remove_event()
  self._events = {}
  self._events[EventID.OnTaskTerminate] = pack(self, task_module._handle_task_terminate)
  self._events[EventID.SetTaskGetItemTipsData] = pack(self, task_module.set_task_get_item_tips_data)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function task_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function task_module:get_cur_tracking_task_id()
  return task_module:get_task_data().TrackingTaskId
end

function task_module:is_tracking()
  return task_module:get_task_data().IsTracking
end

function task_module:task_is_finish(task_id)
  return task_module:get_task_data():GetTaskState(task_id) == NewTaskState.Complete
end

function task_module:task_is_ongoing(task_id)
  return task_module:get_task_data():GetTaskState(task_id) == NewTaskState.Ongoing
end

function task_module:get_task_red_point_state(task_id)
  local cfg = task_module:get_task_step_cfg_by_task_id(task_id)
  if is_null(cfg) then
    return
  end
  if not cfg.isshowintaskwindow then
    return false
  end
  return not red_point_module:is_recorded_with_id(red_point_module.red_point_type.task, task_id)
end

function task_module:set_task_red_point_state(task_id)
  red_point_module:record_with_id(red_point_module.red_point_type.task, task_id)
end

function task_module:get_track_info(task_id, is_cfg)
  return CsTaskModuleUtil.GetTrackInfo(task_id, is_cfg)
end

return task_module
