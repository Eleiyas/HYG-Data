le_mi_achievement_module = le_mi_achievement_module or {}

function le_mi_achievement_module:add_event()
  le_mi_achievement_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOnSyncAchievementNotify] = pack(self, le_mi_achievement_module._handle_sync_achievement_notify)
  self._events[EventID.LuaUpdateAchieveNotify] = pack(self, le_mi_achievement_module._handle_update_achieve_notify)
  self._events[EventID.LuaLeMiFinishAchieveRsp] = pack(self, le_mi_achievement_module._handle_finish_achieve_rsp)
  self._events[EventID.LuaOnSyncBpInfoNotify] = pack(self, le_mi_achievement_module._handle_sync_bp_info_notify)
  self._events[EventID.LuaOnBpExpChangeNotify] = pack(self, le_mi_achievement_module._handle_bp_exp_change_notify)
  self._events[EventID.LuaOnTakeBpRewardRsp] = pack(self, le_mi_achievement_module._handle_take_bp_reward_rsp)
  self._events[EventID.LuaOnSyncDailyTaskNotify] = pack(self, le_mi_achievement_module._handle_sync_daily_task_notify)
  self._events[EventID.LuaOnLeMiUpdateDailyTaskNotify] = pack(self, le_mi_achievement_module._handle_daily_task_update_notify)
  self._events[EventID.LuaLeMiFinishDailyTaskRsp] = pack(self, le_mi_achievement_module._handle_finish_daily_task_rsp)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function le_mi_achievement_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function le_mi_achievement_module:_handle_sync_achievement_notify()
  self._all_achieve_data = dic_to_table(CsLeMiAchievementModuleUtil.GetAllAchievementData())
end

function le_mi_achievement_module:_handle_update_achieve_notify(achievement)
  if achievement then
    if self._all_achieve_data == nil then
      return
    end
    local new_data = achievement.value1
    local id = new_data.AchieveGroupId
    local old_is_can_get = le_mi_achievement_module:achieve_is_can_get(id)
    self._all_achieve_data[id] = new_data
    lua_event_module:send_event(lua_event_module.event_type.update_achieve_ntf, id, achievement.value2)
    lua_event_module:send_event(lua_event_module.event_type.refresh_le_mi_red_point)
    if not old_is_can_get and le_mi_achievement_module:achieve_is_can_get(id) then
      le_mi_achievement_module:add_achieve_tip(id)
    end
  end
end

function le_mi_achievement_module:_handle_finish_achieve_rsp(ret_code)
  lua_event_module:send_event(lua_event_module.event_type.finish_achieve_rsp, ret_code)
  lua_event_module:send_event(lua_event_module.event_type.refresh_le_mi_red_point)
end

function le_mi_achievement_module:_handle_sync_daily_task_notify(notify)
  self._all_daily_task = {}
  for k, data in pairs(dic_to_table(CsLeMiAchievementModuleUtil.GetAllDailyTaskData())) do
    self._all_daily_task[k] = le_mi_achievement_module:_init_daily_task_data(data, data.index)
  end
  lua_event_module:send_event(lua_event_module.event_type.sync_daily_task_notify)
  lua_event_module:send_event(lua_event_module.event_type.refresh_le_mi_red_point)
end

function le_mi_achievement_module:_handle_daily_task_update_notify(data)
  if data then
    local task = data.value1
    self._all_daily_task[task.MissionId] = le_mi_achievement_module:_init_daily_task_data(task, task.index)
    lua_event_module:send_event(lua_event_module.event_type.update_daily_task, task.MissionId, data.value2)
    lua_event_module:send_event(lua_event_module.event_type.refresh_le_mi_red_point)
  end
end

function le_mi_achievement_module:_handle_finish_daily_task_rsp(ret_code)
  self._all_daily_task = {}
  for k, data in pairs(dic_to_table(CsLeMiAchievementModuleUtil.GetAllDailyTaskData())) do
    self._all_daily_task[k] = le_mi_achievement_module:_init_daily_task_data(data, data.index)
  end
  lua_event_module:send_event(lua_event_module.event_type.finish_daily_task_rsp, ret_code)
  lua_event_module:send_event(lua_event_module.event_type.refresh_le_mi_red_point)
end

function le_mi_achievement_module:_handle_sync_bp_info_notify()
  le_mi_achievement_module:refresh_bp_level_and_exp()
end

function le_mi_achievement_module:_handle_bp_exp_change_notify()
  le_mi_achievement_module:refresh_bp_level_and_exp()
end

function le_mi_achievement_module:_handle_take_bp_reward_rsp()
  lua_event_module:send_event(lua_event_module.event_type.get_le_mi_battle_pass_award)
end

function le_mi_achievement_module:can_get_battle_pass_level()
  local level, exp = le_mi_achievement_module:get_cur_level_and_exp()
  local ret_level = 0
  for i, cfg in ipairs(le_mi_achievement_module:get_all_bp_cfg()) do
    local is_get = CsLeMiAchievementModuleUtil.BattlePassAwardIsGet(cfg.level)
    if not is_get and level >= cfg.level then
      ret_level = i
    end
  end
  return ret_level
end

return le_mi_achievement_module
