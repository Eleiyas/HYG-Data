memo_module = memo_module or {}

function memo_module:add_event()
  memo_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function memo_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function memo_module:get_memo_groupings_by_tab_type(tab_type)
  local groups = list_to_table(CsMemoManagerUtil.GetMemoGroupingsByTabType(tab_type))
  local ret_groups = {}
  for _, group in ipairs(groups) do
    table.insert(ret_groups, memo_module:init_memo_grouping(tab_type, group))
  end
  return ret_groups
end

function memo_module:init_memo_grouping(tab_type, group)
  return {
    is_open = true,
    icon = group.icon,
    tab_type = tab_type,
    sort_id = group.sortId,
    group_id = group.groupId,
    group_title = group.groupTitle,
    group_type = group.groupingType,
    nodes = memo_module:get_memo_grouping_nodes(group, tab_type)
  }
end

function memo_module:get_memo_grouping_nodes(group, tab_type)
  local ret_nodes = {}
  local nodes = list_to_table(group.nodes)
  for i, node in ipairs(nodes) do
    table.insert(ret_nodes, {
      index = i,
      desc = node.desc,
      title = node.title,
      tab_type = tab_type,
      is_favor = node.isFavor,
      group_id = group.groupId,
      reward_id = node.rewardId,
      source_id = node.sourceId,
      scene_info = node.sceneInfo,
      source_type = node.sourceType,
      group_type = group.groupingType,
      is_crossing_day = node.isCrossingDay,
      is_show_award_tips_bubble = node.isShowAwardTipsBubble,
      display_reward_items = list_to_table(node.displayRewardItems or {}),
      tracking_tree = tracking_module:parse_tracking_tree(node.trackingNodeTree),
      is_tracking = tracking_module:is_tracking_by_track_type(tracking_module.track_type.memo, node.sourceType, node.sourceId)
    })
  end
  return ret_nodes
end

function memo_module:get_top_memo_node_data()
  return CsMemoManagerUtil.GetTopMemoNodeData()
end

return memo_module
