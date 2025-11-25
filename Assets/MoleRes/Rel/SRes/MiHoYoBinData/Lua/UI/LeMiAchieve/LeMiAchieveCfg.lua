le_mi_achievement_module = le_mi_achievement_module or {}

function le_mi_achievement_module:_init_cfg_data()
  self._all_achieve_dict = nil
  self._all_achieve_group_cfg = nil
  self._all_achieve_cfg = nil
  self._all_daily_task_cfg = nil
  self._all_battle_pass_cfg = nil
  self._all_battle_pass_exp = nil
end

function le_mi_achievement_module:get_all_achieve_dict()
  if self._all_achieve_dict == nil then
    self:_load_achieve_group_cfg()
  end
  return self._all_achieve_dict
end

function le_mi_achievement_module:get_achieve_group_cfg_by_id(group_id)
  if self._all_achieve_group_cfg == nil then
    self:_load_achieve_group_cfg()
  end
  if group_id == nil or group_id <= 0 then
    return
  end
  return self._all_achieve_group_cfg[group_id]
end

function le_mi_achievement_module:_load_achieve_group_cfg()
  local cfg = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BLeMiGroupCfg)))
  self._all_achieve_group_cfg = {}
  self._all_achieve_dict = {}
  for k, v in pairs(cfg) do
    local group_id = tonumber(k)
    local group_cfgs = dic_to_list_table(v)
    local main_group_id = group_cfgs[1].maingroup
    self._all_achieve_dict[main_group_id] = self._all_achieve_dict[main_group_id] or {}
    self._all_achieve_dict[main_group_id][group_id] = self._all_achieve_dict[main_group_id][group_id] or {}
    table.sort(group_cfgs, function(a, b)
      return a.achieveid < b.achieveid
    end)
    for _, vv in ipairs(group_cfgs) do
      table.insert(self._all_achieve_dict[main_group_id][group_id], vv.achieveid)
      self._all_achieve_group_cfg[vv.achieveid] = vv
    end
  end
end

function le_mi_achievement_module:get_achieve_cfg_list_by_id(cfg_id)
  if self._all_achieve_cfg == nil then
    le_mi_achievement_module:_load_all_achieve_cfg()
  end
  if self._all_achieve_cfg[cfg_id] == nil then
    Logger.LogError("achieve_cfg_list is null !!! cfg_id = " .. cfg_id)
    return nil
  end
  return self._all_achieve_cfg[cfg_id]
end

function le_mi_achievement_module:get_achieve_cfg_by_id_index(cfg_id, index)
  local cfgs = le_mi_achievement_module:get_achieve_cfg_list_by_id(cfg_id)
  if cfgs == nil then
    Logger.LogError("achieve_cfg is null !!! cfg_id = " .. cfg_id)
    return nil
  end
  if cfgs[index] == nil then
    index = #cfgs
  end
  return cfgs[index]
end

function le_mi_achievement_module:_load_all_achieve_cfg()
  local cfg = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BLeMiAchieveCfg)))
  self._all_achieve_cfg = {}
  for k, v in pairs(cfg) do
    self._all_achieve_cfg[tonumber(k)] = dic_to_list_table(v)
    table.sort(self._all_achieve_cfg[tonumber(k)], function(a, b)
      return a.id < b.id
    end)
  end
end

function le_mi_achievement_module:get_daily_task_cfg_by_id(cfg_id)
  if cfg_id == nil or cfg_id <= 0 then
    Logger.LogError("cfg_id is null !!! cfg_id = ")
    return
  end
  if self._all_daily_task_cfg == nil then
    self:_load_all_daily_task_cfg()
  end
  return self._all_daily_task_cfg[cfg_id]
end

function le_mi_achievement_module:_load_all_daily_task_cfg()
  self._all_daily_task_cfg = {}
  local cfg = dic_to_table(LocalDataUtil.get_table(typeof(CS.BLeMiDailyMissionCfg)))
  for _, v in pairs(cfg) do
    self._all_daily_task_cfg[v.id] = v
  end
end

function le_mi_achievement_module:get_all_bp_cfg()
  if self._all_battle_pass_cfg == nil then
    le_mi_achievement_module:_init_battle_pass_cfg()
  end
  local ret_tbl = {}
  for _, v in pairs(self._all_battle_pass_cfg) do
    table.insert(ret_tbl, v)
  end
  table.sort(ret_tbl, function(a, b)
    return a.level < b.level
  end)
  return ret_tbl
end

function le_mi_achievement_module:_init_battle_pass_cfg()
  local cfg = dic_to_table(LocalDataUtil.get_table(typeof(CS.BLeMiBattlePassCfg)))
  self._all_battle_pass_exp = {}
  self._all_battle_pass_cfg = {}
  local sort_tbl = {}
  for k, v in pairs(cfg) do
    self._all_battle_pass_cfg[tonumber(k)] = v
    table.insert(sort_tbl, v)
  end
  table.sort(sort_tbl, function(a, b)
    return a.level < b.level
  end)
  local exp = 0
  for _, v in ipairs(sort_tbl) do
    exp = exp + v.reachneedexp
    self._all_battle_pass_exp[v.level] = exp
  end
end

function le_mi_achievement_module:get_battle_pass_cfg_by_level(level)
  if level == nil or level <= 0 then
    return nil
  end
  if self._all_battle_pass_cfg == nil then
    le_mi_achievement_module:_init_battle_pass_cfg()
  end
  return self._all_battle_pass_cfg[level]
end

function le_mi_achievement_module:get_battle_pass_exp_by_level(level)
  if level == nil or level <= 0 then
    return 0
  end
  if self._all_battle_pass_exp == nil then
    le_mi_achievement_module:_init_battle_pass_cfg()
  end
  return self._all_battle_pass_exp[level] or 0
end

return le_mi_achievement_module
