collection_module = collection_module or {}

function collection_module:add_event()
  collection_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function collection_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function collection_module:get_collection_step_up_task()
  return task_module:get_task_data():GetOngoingCollectionStepUpTaskId()
end

function collection_module:time_diary_task_is_finish(task_id)
  return collection_module:get_time_diary_task_group_done_time(task_id) > 0
end

function collection_module:get_time_diary_task_group_done_time(task_id)
  return CsCollectionModuleUtil.GetTimeDiaryTaskGroupDoneTime(task_id)
end

function collection_module:time_diary_tracker_is_finish_by_task_id(task_id)
  local cfgs = collection_module:get_time_diary_task_config_by_id(task_id)
  for _, cfg in pairs(cfgs) do
    if not collection_module:time_diary_tracker_is_finish(cfg.trackerid) then
      return false
    end
  end
  return true
end

function collection_module:time_diary_tracker_is_finish(tracker_id)
  local is_has, server_data = CsCollectionModuleUtil.TryGetTimeDiaryTask(tracker_id)
  if is_has then
    return server_data.IsDone
  end
  return false
end

function collection_module:get_time_diary_group_red_show_state(group_id)
  local server_data = CsCollectionModuleUtil.GetTimeDiaryGroupById(group_id)
  if is_null(server_data) then
    return false
  end
  local tbl_tracker_data = array_to_table(server_data.TaskList)
  for _, tracker_data in pairs(tbl_tracker_data) do
    if not tracker_data.IsDone then
      local condition = CsTrackerModuleUtil.GetConditionConsumeItemByTrackerId(tracker_data.TrackerId)
      if back_bag_module:get_packet_data():GetItemNumByItemFilterList(condition.itemFilterList) > 0 then
        return true
      end
    end
  end
  return false
end

return collection_module
