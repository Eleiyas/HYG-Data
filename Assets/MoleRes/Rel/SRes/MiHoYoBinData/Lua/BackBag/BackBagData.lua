back_bag_module = back_bag_module or {}

function back_bag_module:_init_data()
  self._temporary_bag_item = nil
  self._delivery_task_step_id = nil
  self._replace_item_type = back_bag_module.replace_item_type.none
end

function back_bag_module:get_packet_data()
  return CsPacketModuleUtil.packetData
end

function back_bag_module:get_coin(coin_type)
  return back_bag_module:get_packet_data():GetCoinCountById(coin_type)
end

function back_bag_module:get_item_num(item_id)
  return back_bag_module:get_packet_data():GetItemNum(item_id) or 0
end

function back_bag_module:get_item_num_by_tag(tag)
  return back_bag_module:get_packet_data():GetItemNumByTag(tag) or 0
end

function back_bag_module:get_item_stack_num(cfg_id)
  return back_bag_module:get_packet_data():GetItemStackNum(cfg_id)
end

function back_bag_module:get_item_num_by_guid(item_guid)
  if item_guid == nil or item_guid <= 0 then
    return 0
  end
  local item_data = back_bag_module:get_packet_data():GetItemByGUID(item_guid)
  if is_null(item_data) then
    return 0
  end
  return item_data.Count
end

function back_bag_module:get_all_equip_clothes()
  local guids = EntityUtil.get_all_equip_clothe_guids_by_guid(player_module:get_player_guid())
  local ret_tbl = {}
  for _, make_id in ipairs(guids) do
    local item_data = item_module:get_item_by_make_id(make_id)
    if not is_null(item_data) and item_data.cfg.isshowinpage == 0 then
      table.insert(ret_tbl, item_data)
    end
  end
  return ret_tbl
end

function back_bag_module:get_item_guids(bag_show_type, back_pack_types, filter_data)
  filter_data = filter_data or {}
  return list_to_table(CsPacketModuleUtil.GetItemGuids(bag_show_type, back_pack_types, filter_data.tags))
end

function back_bag_module:check_ingredient_compatibility(item, info)
  return CsPacketModuleUtil.CheckIngredientCompatibility(item, info)
end

function back_bag_module:set_submit_item_conditions(conditions)
  CsPacketModuleUtil.SetSubmitItemCondition(conditions or {})
end

function back_bag_module:init_tracking_task_filter_lists()
  CsPacketModuleUtil.InitTrackingTaskFilterLists()
end

function back_bag_module:set_replace_item_type(state)
  self._replace_item_type = state or back_bag_module.replace_item_type.none
end

function back_bag_module:check_replace_item_type(state)
  return self._replace_item_type == state
end

function back_bag_module:get_replace_item_type()
  return self._replace_item_type
end

function back_bag_module:get_temporary_bag_item()
  return self._temporary_bag_item
end

function back_bag_module:set_delivery_task_step_id(step_id)
  self._delivery_task_step_id = step_id or 0
  back_bag_module:get_packet_data():SetSubmitTaskId(step_id)
end

function back_bag_module:get_delivery_task_step_id()
  return self._delivery_task_step_id or 0
end

function back_bag_module:get_delivery_task_conditions()
  return list_to_table(CsTaskManagerUtil.GetTaskFinishConsumeItemCondition(back_bag_module:get_delivery_task_step_id()) or {})
end

function back_bag_module:get_donate_task_conditions(step_id)
  return list_to_table(CsTaskManagerUtil.GetTaskFinishConditionDonate(step_id) or {})
end

function back_bag_module:get_submit_condition(condition_data)
  local condition = {
    temp_add_num = 0,
    cur_num = condition_data.curNumber,
    max_num = condition_data.needNumber,
    item_filter_list = condition_data.itemFilterList,
    txt = ""
  }
  if string.is_valid(condition_data.conditionName) then
    condition.txt = condition_data.conditionName
  elseif 0 < condition_data.itemId then
    condition.txt = item_module:get_item_name_by_id(condition_data.itemId)
  end
  return condition
end

function back_bag_module:item_filter_list_check(server_data, item_filter_list)
  if is_null(server_data) then
    return false
  end
  return back_bag_module:get_packet_data():ItemFilterListCheck(server_data, item_filter_list)
end

function back_bag_module:condition_item_is_lock(server_data, condition)
  if is_null(server_data) or is_null(condition) then
    return true
  end
  if back_bag_module:item_filter_list_check(server_data, condition.itemFilterList) then
    return condition.curNumber >= condition.needNumber
  end
  return true
end

function back_bag_module:get_condition_item_add_num(item_data, cur_add_num, tbl_condition)
  if is_null(item_data) then
    return 0
  end
  local ret_num = 0
  local add_num = 0
  local cur_need_num = 0
  local has_num = item_data.Count - cur_add_num
  for _, condition in ipairs(tbl_condition) do
    if back_bag_module:item_filter_list_check(item_data, condition.itemFilterList) then
      cur_need_num = condition.needNumber - condition.curNumber - condition.tempAddNum
      add_num = math.min(cur_need_num, has_num)
      condition.tempAddNum = condition.tempAddNum + add_num
      if ret_num < add_num then
        ret_num = add_num
      end
    end
  end
  return tbl_condition, ret_num + cur_add_num
end

function back_bag_module:get_condition_item_subtract_num(item_data, cur_add_num, tbl_condition)
  local ret_num = cur_add_num
  local subtract_num = 0
  for _, condition in ipairs(tbl_condition) do
    if 0 < condition.tempAddNum and back_bag_module:item_filter_list_check(item_data, condition.itemFilterList) then
      condition.tempAddNum = condition.tempAddNum - 1
      subtract_num = 1
    end
  end
  return tbl_condition, ret_num - subtract_num
end

function back_bag_module:donate_condition_item_select(item_data, tbl_condition)
  if is_null(item_data) then
    return 0
  end
  local add_num = 0
  for _, condition in ipairs(tbl_condition) do
    if condition.curNumber + condition.tempAddNum < condition.needNumber and back_bag_module:item_filter_list_check(item_data, condition.itemFilterList) then
      add_num = 1
      condition.tempAddNum = condition.tempAddNum + add_num
    end
  end
  return tbl_condition, 0 < add_num
end

function back_bag_module:donate_condition_item_unselect(item_data, tbl_condition)
  local subtract_num = 0
  for _, condition in ipairs(tbl_condition) do
    if 0 < condition.tempAddNum and back_bag_module:item_filter_list_check(item_data, condition.itemFilterList) then
      subtract_num = 1
      condition.tempAddNum = condition.tempAddNum - subtract_num
    end
  end
  return tbl_condition, 0 < subtract_num
end

return back_bag_module
