tracking_module = tracking_module or {}

function tracking_module:add_event()
  tracking_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function tracking_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function tracking_module:is_tracking_by_track_type(track_type, source_type, tracking_id)
  return CsTrackingModuleUtil.IsTrackingByTrackType(track_type, source_type, tracking_id)
end

function tracking_module:set_tracking_by_track_type(track_type, source_type, tracking_id, is_tracking, is_show_point)
  CsTrackingModuleUtil.SetTrackingByOperation(track_type, source_type, tracking_id, is_tracking, is_show_point)
end

function tracking_module:set_cur_track_type(track_type)
  CsTrackingModuleUtil.SetCurTrackType(track_type)
end

function tracking_module:is_cur_track_type(track_type)
  return CsTrackingModuleUtil.IsCurTrackType(track_type)
end

function tracking_module:is_can_tracking(track_type)
  return CsTrackingModuleUtil.IsCanTracking(track_type)
end

function tracking_module:is_show_top()
  local top_data = memo_module:get_top_memo_node_data()
  return not is_null(top_data) and tracking_module:get_is_show_memo_top_item()
end

function tracking_module:get_cur_tracking_info()
  return CsTrackingModuleUtil.GetCurTrackingInfo()
end

function tracking_module:set_point_is_show_by_track_type(track_type, is_show)
  return CsTrackingModuleUtil.SetPointIsShowByTrackType(track_type, is_show)
end

function tracking_module:tracking_point_is_show(track_type)
  return CsTrackingModuleUtil.TrackingPointIsShow(track_type)
end

function tracking_module:get_is_show_memo_top_item()
  return CsTrackingModuleUtil.GetIsShowMemoTopItem()
end

function tracking_module:set_is_show_memo_top_item(is_show)
  return CsTrackingModuleUtil.SetIsShowMemoTopItem(is_show or false)
end

function tracking_module:get_int_cur_track_type()
  return CsTrackingModuleUtil.GetIntCurTrackType()
end

function tracking_module:get_manager_cur_track_type()
  return CsTrackingManagerUtil.GetManagerCurTrackType()
end

function tracking_module:item_in_tracking_black_list(item_id)
  return CsTrackingModuleUtil.ItemInTrackingBlackList(item_id)
end

function tracking_module:reset_cur_tracking()
  CsTrackingManagerUtil.ResetCurTracking()
end

function tracking_module:is_blurry_tracking(guid)
  return CsTrackingManagerUtil.IsBlurryTracking(guid)
end

function tracking_module:is_in_blurry_tracking_by_guid(guid)
  return CsTrackingManagerUtil.IsInBlurryTrackingByGuid(guid)
end

function tracking_module:is_in_blurry_tracking()
  return CsTrackingManagerUtil.IsInBlurryTracking()
end

function tracking_module:cur_track_failure_reason()
  return CsTrackingManagerUtil.CurTrackFailureReason
end

function tracking_module:get_track_data_by_track_type(track_type)
  local track_data = CsTrackingModuleUtil.GetTrackDataByTrackType(track_type)
  if is_null(track_data) then
    return nil
  end
  return tracking_module:create_lua_track_data(track_data, track_type)
end

function tracking_module:create_lua_track_data(track_data, track_type)
  if is_null(track_data) then
    return nil
  end
  return {
    data = track_data,
    track_type = track_type,
    title_str = track_data.titleStr,
    source_id = track_data.sourceId,
    source_type = track_data.sourceType,
    tracking_tree = tracking_module:parse_tracking_tree(track_data.trackingNodeTree)
  }
end

function tracking_module:parse_tracking_tree(tree)
  if is_null(tree) then
    return {
      is_and = true,
      node_infos = {}
    }
  end
  if is_null(tree.nodeInfos) then
    return tree
  else
    local node_infos = list_to_table(tree.nodeInfos)
    local ret_tree = {
      node_infos = {},
      is_and = tree.operation == 0
    }
    for _, node_info in ipairs(node_infos) do
      table.insert(ret_tree.node_infos, tracking_module:_parse_condition_des_tree(node_info))
    end
    return ret_tree
  end
end

function tracking_module:_parse_condition_des_tree(tree)
  if is_null(tree) then
    return {
      operation = 0,
      node_infos = {}
    }
  end
  if is_null(tree.nodeInfos) then
    return tree
  else
    local node_infos = list_to_table(tree.nodeInfos)
    local ret_tree = {
      operation = tree.operation,
      node_infos = {}
    }
    for _, node_info in ipairs(node_infos) do
      table.insert(ret_tree.node_infos, tracking_module:_parse_condition_des_tree(node_info))
    end
    return ret_tree
  end
end

function tracking_module:get_tracking_point_style(track_type, source_type, source_id)
  if track_type == tracking_module.track_type.memo then
    if source_type == tracking_module.data_source_type.npc_daily_event then
      return tracking_module.tracking_point_style.npc
    end
    local cfg = task_module:get_task_step_cfg_by_task_id(source_id)
    if cfg.GroupingType == memo_module.grouping_type.npc then
      return tracking_module.tracking_point_style.npc
    end
    return tracking_module.tracking_point_style.main_task
  elseif track_type == tracking_module.track_type.tutorial then
    return tracking_module.tracking_point_style.main_task
  end
  return tracking_module.tracking_point_style.feature
end

function tracking_module:get_npc_id_by_source_type_and_id(source_type, source_id)
  if source_type == tracking_module.data_source_type.task then
    return CsTrackingModuleUtil.GetNpcIdBySourceTypeAndId(source_type, source_id)
  else
    return source_id >> 32
  end
end

function tracking_module:condition_style_is_item(tracking_data)
  if is_null(tracking_data) then
    return false
  end
  return tracking_data.source_type == tracking_module.data_source_type.recipe or tracking_data.source_type == tracking_module.data_source_type.mitaicobuild or tracking_data.source_type == tracking_module.data_source_type.miyouzhu
end

function tracking_module:is_show_tracking_point_by_item_id(item_id, tracking_data)
  tracking_data = tracking_data or tracking_module:get_track_data_by_track_type(tracking_module:get_manager_cur_track_type())
  if is_null(tracking_data) then
    return false
  end
  return tracking_data.data:IsShowTrackingPointByItemId(item_id)
end

return tracking_module
