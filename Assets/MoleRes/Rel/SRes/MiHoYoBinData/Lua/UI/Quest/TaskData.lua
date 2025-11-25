task_module = task_module or {}

function task_module:_init_data()
  self._task_get_item_tips_data = nil
end

function task_module:get_task_cfg_data()
  return CsTaskModuleUtil.taskCfgData
end

function task_module:get_task_npc_data()
  return CsTaskModuleUtil.taskNpcData
end

function task_module:get_task_data()
  return CsTaskModuleUtil.taskData
end

function task_module:get_task_cfg_data()
  return CsTaskModuleUtil.taskCfgData
end

function task_module:get_finish_condition_des_tree_by_task_id(task_id)
  if task_id <= 0 then
    return {}
  end
  local tree = {
    operation = 0,
    node_infos = list_to_table(task_module:get_task_data():GetFinishConditionTrackingDesByTaskId(task_id))
  }
  return tree
end

function task_module:_parse_condition_des_tree(tree)
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
      table.insert(ret_tree.node_infos, task_module:_parse_condition_des_tree(node_info))
    end
    return ret_tree
  end
end

function task_module:_handle_task_terminate(task_id)
  if task_id ~= task_module:get_cur_tracking_task_id() then
    return
  end
  if self._lst_finish_task_ids == nil then
    self._lst_finish_task_ids = {}
  end
  local step_cfg = task_module:get_task_step_cfg_by_task_id(task_id)
  if is_null(step_cfg) or not step_cfg.isshowintaskwindow then
    return
  end
  self._lst_finish_task_ids[1] = task_id
end

function task_module:get_top_finish_task_id()
  if self._lst_finish_task_ids == nil or #self._lst_finish_task_ids <= 0 then
    return 0
  end
  return self._lst_finish_task_ids[1]
end

function task_module:remove_top_finish_task_id()
  if self._lst_finish_task_ids == nil or #self._lst_finish_task_ids <= 0 then
    return
  end
  table.remove(self._lst_finish_task_ids, 1)
end

function task_module:set_task_get_item_tips_data(data)
  if is_null(data) then
    return
  end
  local items = list_to_table(data.itemList)
  self._task_get_item_tips_data = {
    show_time = data.showTime,
    items = {}
  }
  for _, v in ipairs(items) do
    if v.configId > 0 then
      table.insert(self._task_get_item_tips_data.items, v)
    end
  end
end

function task_module:get_task_get_item_tips_data()
  return self._task_get_item_tips_data
end

return task_module or {}
