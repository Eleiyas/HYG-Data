le_mi_achievement_module = le_mi_achievement_module or {}

function le_mi_achievement_module:_init_data()
  self._all_achieve_data = {}
  self._all_daily_task = nil
  self._cur_coin_get_source = nil
  self._all_can_get_group_id = nil
  self._daily_task_refresh_num = 0
  self._cur_bp_level = 0
  self._cur_bp_exp = 0
  self._max_bp_level = 0
  self._last_bp_level_data = nil
  CsLuaManagerUtil.LuaFunctionRegister:SetIsLeMiAchieveDoneFunc(pack(self, le_mi_achievement_module.c_sharp_call_achieve_on_going))
end

function le_mi_achievement_module:achieve_is_hide(group_id)
  local cfg = le_mi_achievement_module:get_achieve_group_cfg_by_id(group_id)
  if cfg == nil or cfg.ishide == 0 then
    return false
  end
  local server_data = le_mi_achievement_module:get_cur_achieve_data_by_id(group_id)
  if server_data and server_data.GroupStepId <= 1 and not server_data.IsAllRewardTaken and not le_mi_achievement_module:achieve_is_can_get(group_id) then
    return true
  end
  return false
end

function le_mi_achievement_module:set_coin_get_source(data)
  self._cur_coin_get_source = data
end

function le_mi_achievement_module:get_coin_get_source()
  return self._cur_coin_get_source or {}
end

function le_mi_achievement_module:get_cur_achieve_data_by_id(achieve_id)
  return self._all_achieve_data[achieve_id]
end

function le_mi_achievement_module:c_sharp_call_achieve_on_going(achieve_id)
  local achieve = le_mi_achievement_module:get_cur_achieve_data_by_id(achieve_id)
  if is_null(achieve) then
    return false
  end
  CsLuaManagerUtil.LuaFunctionRegister.bLeMiAchieveDone = not achieve.IsAllRewardTaken
end

function le_mi_achievement_module:achieve_is_can_get(id)
  local server_data = le_mi_achievement_module:get_cur_achieve_data_by_id(id)
  if server_data then
    return server_data.CurrentProgress >= server_data.TargetProgress and not server_data.IsAllRewardTaken and server_data.IsDisplay
  end
  return false
end

function le_mi_achievement_module:get_all_daily_task_id()
  local ret_tbl = {}
  if self._all_daily_task then
    for i, v in pairs(self._all_daily_task) do
      table.insert(ret_tbl, {
        id = i,
        index = v.index
      })
    end
    table.sort(ret_tbl, function(a, b)
      return a.index < b.index
    end)
  end
  return ret_tbl
end

function le_mi_achievement_module:get_daily_task_by_id(id)
  return self._all_daily_task[id]
end

function le_mi_achievement_module:get_daily_task_refresh_num()
  return self._daily_task_refresh_num
end

function le_mi_achievement_module:get_le_mi_app_red_point_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateMilestone) then
    return false
  end
  return le_mi_achievement_module:get_achievement_red_point_state() or le_mi_achievement_module:get_daily_task_red_point_state()
end

function le_mi_achievement_module:get_achievement_red_point_state()
  local all_achieve_dict = le_mi_achievement_module:get_all_achieve_dict()
  for _, groupd_id2achieve_ids in pairs(all_achieve_dict) do
    for _, achieve_ids in pairs(groupd_id2achieve_ids) do
      for _, achieve_id in ipairs(achieve_ids) do
        if le_mi_achievement_module:achieve_is_can_get(achieve_id) then
          return true
        end
      end
    end
  end
  return false
end

function le_mi_achievement_module:get_daily_task_red_point_state()
  if le_mi_achievement_module:is_daily_bp_finish() then
    return false
  end
  for _, v in ipairs(le_mi_achievement_module:get_all_daily_task_id()) do
    local task_data = le_mi_achievement_module:get_daily_task_by_id(v.id)
    if task_data and task_data.state == le_mi_achievement_module.daily_task_state.can_get then
      return true
    end
  end
  return false
end

function le_mi_achievement_module:get_achievement_first_level_red_point_state(main_group_id)
  local all_achieve_dict = le_mi_achievement_module:get_all_achieve_dict()
  local groupd_id2achieve_ids = all_achieve_dict[main_group_id]
  for _, achieve_ids in pairs(groupd_id2achieve_ids) do
    for _, achieve_id in ipairs(achieve_ids) do
      if le_mi_achievement_module:achieve_is_can_get(achieve_id) then
        return true
      end
    end
  end
  return false
end

function le_mi_achievement_module:get_achievement_second_level_red_point_state(main_group_id, second_group_id)
  local all_achieve_dict = le_mi_achievement_module:get_all_achieve_dict()
  local achieve_ids = all_achieve_dict[main_group_id][second_group_id]
  for _, achieve_id in ipairs(achieve_ids) do
    if le_mi_achievement_module:achieve_is_can_get(achieve_id) then
      return true
    end
  end
  return false
end

function le_mi_achievement_module:_init_daily_task_data(data, index)
  local state, add_exp, exp_times
  if data.IsFinish then
    state = le_mi_achievement_module.daily_task_state.finish
    add_exp = 0
    exp_times = 0
  else
    if data.CurrentProgress >= data.TargetProgress then
      state = le_mi_achievement_module.daily_task_state.can_get
    else
      state = le_mi_achievement_module.daily_task_state.ongoing
    end
    add_exp = data.ExpNum * data.ExpTimes
    exp_times = data.ExpTimes
  end
  return {
    id = data.MissionId,
    index = index,
    state = state,
    add_exp = add_exp,
    exp_times = exp_times,
    cur_plan = data.CurrentProgress,
    max_plan = data.TargetProgress
  }
end

function le_mi_achievement_module:get_last_achieve_data()
  return CsLeMiAchievementModuleUtil.GetLastAchievementData()
end

function le_mi_achievement_module:get_daily_task_is_can_refresh()
  return CsLeMiAchievementModuleUtil.GetDailyTaskIsCanRefresh()
end

function le_mi_achievement_module:get_finish_daily_task()
  return CsLeMiAchievementModuleUtil.GetFinishDailyTask()
end

function le_mi_achievement_module:get_cur_bp_exp()
  return CsLeMiAchievementModuleUtil.CurBpExp or 0
end

function le_mi_achievement_module:refresh_bp_level_and_exp()
  if self._all_battle_pass_exp == nil then
    le_mi_achievement_module:_init_battle_pass_cfg()
  end
  self._cur_bp_exp = 0
  self._cur_bp_level = 0
  local all_exp = le_mi_achievement_module:get_cur_bp_exp()
  for i, v in ipairs(le_mi_achievement_module:get_all_bp_cfg()) do
    if all_exp >= v.reachneedexp then
      all_exp = all_exp - v.reachneedexp
      self._cur_bp_level = v.level
    end
    self._cur_bp_exp = all_exp
    self._max_bp_level = v.level
  end
end

function le_mi_achievement_module:get_cur_level_and_exp()
  return self._cur_bp_level or 0, self._cur_bp_exp or 0
end

function le_mi_achievement_module:get_max_bp_level()
  return self._max_bp_level or 0
end

function le_mi_achievement_module:get_last_bp_level_data()
  if self._last_bp_level_data == nil then
    self._last_bp_level_data = {level = 0, exp = 0}
  end
  return self._last_bp_level_data
end

function le_mi_achievement_module:is_daily_bp_finish()
  local bp_cfgs = dic_to_list_table(LocalDataUtil.get_table(typeof(CS.BLeMiDailyBattlePassCfg)))
  local last_bp_cfg = 0 < #bp_cfgs and bp_cfgs[#bp_cfgs] or nil
  if last_bp_cfg then
    return le_mi_achievement_module:get_cur_bp_exp() >= last_bp_cfg.needexp
  else
    return false
  end
end

return le_mi_achievement_module
