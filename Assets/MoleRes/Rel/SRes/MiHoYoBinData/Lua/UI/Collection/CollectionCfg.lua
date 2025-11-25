collection_module = collection_module or {}

function collection_module:_init_cfg()
  self._tbl_time_dairy_cfgs = nil
  self._tbl_time_dairy_cfgs_by_task_id = nil
end

function collection_module:get_all_time_diary_config()
  if self._tbl_time_dairy_cfgs == nil then
    collection_module:_init_time_diary_config()
  end
  return self._tbl_time_dairy_cfgs or {}
end

function collection_module:_init_time_diary_config()
  self._tbl_time_dairy_cfgs = {}
  self._tbl_time_dairy_cfgs_by_task_id = {}
  local cfgs = LocalDataUtil.get_dic_table(typeof(CS.BTimeDiaryConfig))
  for k, v in pairs(cfgs) do
    self._tbl_time_dairy_cfgs[k] = list_to_table(v)
    for _, one_cfg in pairs(v) do
      self._tbl_time_dairy_cfgs_by_task_id[one_cfg.taskid] = one_cfg
    end
  end
end

function collection_module:get_time_diary_cfgs_by_step_id(step_id)
  local ret_cfg = {}
  local all_cfgs = collection_module:get_all_time_diary_config()
  for _, cfgs in pairs(all_cfgs) do
    for i, v in pairs(cfgs) do
      if v.stageid == step_id then
        table.insert(ret_cfg, v)
      end
    end
  end
  return ret_cfg
end

function collection_module:get_time_diary_config_by_group_id(group_id)
  if self._tbl_time_dairy_cfgs == nil then
    collection_module:_init_time_diary_config()
  end
  return self._tbl_time_dairy_cfgs[group_id] or {}
end

function collection_module:get_time_diary_config_by_task_id(task_id)
  if self._tbl_time_dairy_cfgs == nil then
    collection_module:_init_time_diary_config()
  end
  return self._tbl_time_dairy_cfgs_by_task_id[task_id]
end

function collection_module:get_time_diary_task_config_by_id(task_id)
  if task_id <= 0 then
    return {}
  end
  local cfgs = LocalDataUtil.get_dic_table(typeof(CS.BTimeDiaryTaskConfig))
  if not is_null(cfgs) then
    return list_to_table(cfgs[task_id] or {})
  end
  return {}
end

function collection_module:get_time_diary_level_config_by_step_id(step_id)
  if step_id <= 0 then
    return nil
  end
  return LocalDataUtil.get_value(typeof(CS.BTimeDiaryLevelConfig), step_id)
end

function collection_module:get_all_time_diary_level_config()
  return LocalDataUtil.get_dic_table(typeof(CS.BTimeDiaryLevelConfig))
end

return collection_module
