theme_season_module = theme_season_module or {}

local function _make_merged_sender(event_type)
  return FuncMergeUtil.new(function()
    lua_event_module:send_event(event_type)
  end, {
    same_frame = true,
    leading = false,
    scene_independent = true
  })
end

function theme_season_module:add_event()
  theme_season_module:remove_event()
  local evt = lua_event_module.event_type
  self._send_season_data_changed, self._season_data_changed_ctrl = _make_merged_sender(evt.on_theme_season_data_changed)
  self._send_npc_goods_exchanged, self._npc_goods_exchanged_ctrl = _make_merged_sender(evt.on_npc_goods_exchanged)
  self._events = {}
  self._events[EventID.OnThemeSeasonInfoNotify] = pack(self, theme_season_module._on_season_info_notify)
  self._events[EventID.OnThemeBpGraduateExchangeRsp] = pack(self, theme_season_module._on_graduate_exchange_rsp)
  self._events[EventID.OnThemeBpPurchaseNotify] = pack(self, theme_season_module._on_bp_purchase_notify)
  self._events[EventID.OnThemeBpItemPurchaseRsp] = pack(self, theme_season_module._on_bp_item_purchase_rsp)
  self._events[EventID.OnNpcGoodsExchangeInfoNotify] = pack(self, theme_season_module._on_npc_goods_exchange_notify)
  self._events[EventID.OnNpcGoodsExchangeRsp] = pack(self, theme_season_module._on_npc_goods_exchange_rsp)
  self._events[EventID.OnThemeSeasonStoryRewardClaimRsp] = pack(self, theme_season_module._on_story_reward_claim_rsp)
  self._events[EventID.OnSeasonDailyMissionNotify] = pack(self, theme_season_module._on_daily_mission_notify)
  self._events[EventID.OnClaimSeasonDailyMissionRewardRsp] = pack(self, theme_season_module._on_claim_daily_reward_rsp)
  self._events[EventID.OnSeasonDailyMissionUpdateNotify] = pack(self, theme_season_module._on_daily_mission_update)
  self._events[EventID.OnActivityDataChanged] = pack(self, theme_season_module._on_activity_data_changed)
  self._events[EventID.OnActivityDataAdded] = pack(self, theme_season_module._on_activity_data_changed)
  self._events[EventID.OnActivityListChanged] = pack(self, theme_season_module._on_activity_list_changed)
  self._events[EventID.OnActivityRemoved] = pack(self, theme_season_module._on_activity_list_changed)
  self._events[EventID.OnThemeSeasonExpiredTaskRecordNotify] = pack(self, theme_season_module._on_expired_task_record_notify)
  self._events[EventID.LuaOpenStateNotify] = pack(self, theme_season_module._on_open_state_notify)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function theme_season_module:remove_event()
  if self._season_data_changed_ctrl then
    self._season_data_changed_ctrl:dispose()
    self._season_data_changed_ctrl = nil
    self._send_season_data_changed = nil
  end
  if self._npc_goods_exchanged_ctrl then
    self._npc_goods_exchanged_ctrl:dispose()
    self._npc_goods_exchanged_ctrl = nil
    self._send_npc_goods_exchanged = nil
  end
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function theme_season_module:_on_season_info_notify(notify)
  self:update_from_notify(notify)
  self:update_season_time_state()
  if notify and notify.ExpiredSeasonTaskIdList then
    self:update_expired_season_task_ids(notify.ExpiredSeasonTaskIdList)
  end
  self._send_season_data_changed()
end

function theme_season_module:_on_graduate_exchange_rsp(rsp)
  if rsp == nil then
    return
  end
  if rsp.Retcode == 0 and 0 < rsp.GraduateConfigId then
    self:add_exchanged_graduate(rsp.GraduateConfigId)
    lua_event_module:send_event(lua_event_module.event_type.on_theme_bp_graduate_exchanged)
  end
end

function theme_season_module:_on_bp_purchase_notify(notify)
  if notify == nil then
    return
  end
  if notify.ProductId > 0 then
    self:add_purchased_product(notify.ProductId)
    self:invalidate_npc_goods_cache()
    lua_event_module:send_event(lua_event_module.event_type.on_theme_bp_purchased)
    self:open_bp_purchase_success_dialog(notify.ProductId)
  end
end

function theme_season_module:_on_bp_item_purchase_rsp(rsp)
  if rsp == nil then
    return
  end
  if rsp.Retcode == 0 and 0 < rsp.ProductId then
    self:add_purchased_product(rsp.ProductId)
    self:invalidate_npc_goods_cache()
    lua_event_module:send_event(lua_event_module.event_type.on_theme_bp_purchased)
    self:open_bp_purchase_success_dialog(rsp.ProductId)
  else
    Logger.LogWarning("[ThemeSeason] BpItemPurchase failed, retcode=" .. tostring(rsp.Retcode))
  end
end

function theme_season_module:_on_npc_goods_exchange_notify(notify)
  if notify == nil then
    return
  end
  self:update_npc_exchange_data(notify)
  self._send_npc_goods_exchanged()
end

function theme_season_module:_on_npc_goods_exchange_rsp(rsp)
  if rsp == nil or rsp.Retcode ~= 0 then
    return
  end
  local id_list = rsp.GoodsConfigIdList
  if id_list == nil or 0 >= id_list.Count then
    return
  end
  local reward_items = {}
  for i = 0, id_list.Count - 1 do
    local config_id = id_list[i]
    local npc_id = self:get_npc_id_by_goods_config_id(config_id)
    if 0 < npc_id then
      self:add_npc_exchanged_goods(npc_id, config_id)
    end
    local goods_cfg = self:get_theme_season_npc_goods_cfg_by_id(config_id)
    local item_id = goods_cfg and goods_cfg.itemid or 0
    if 0 < item_id then
      reward_items[#reward_items + 1] = {
        id = item_id,
        num = goods_cfg.itemcount or 0
      }
    end
  end
  self:invalidate_npc_goods_cache()
  if 0 < #reward_items then
    common_ui_module:show_reward_dialog(nil, nil, reward_items)
  end
  self._send_npc_goods_exchanged()
end

function theme_season_module:_on_story_reward_claim_rsp(rsp)
  if rsp == nil then
    return
  end
  if rsp.Retcode == 0 and 0 < rsp.BpStoryId then
    self:add_claimed_story_reward(rsp.BpStoryId)
    local reward_items = self:get_story_reward_items(rsp.BpStoryId)
    if reward_items and 0 < #reward_items then
      common_ui_module:show_reward_dialog(nil, nil, reward_items)
    end
    self._send_season_data_changed()
  end
end

function theme_season_module:_on_activity_data_changed(activity_id)
  local season_activity_id = self:get_season_activity_id()
  if 0 < season_activity_id and season_activity_id == activity_id then
    self:update_season_time_state()
    self._send_season_data_changed()
    return
  end
  if self:is_season_story_chapter_activity(activity_id) then
    self._send_season_data_changed()
  end
end

function theme_season_module:_on_activity_list_changed()
  if self:get_cur_season_id() <= 0 then
    return
  end
  self:update_season_time_state()
  self._send_season_data_changed()
end

function theme_season_module:_on_open_state_notify(state_type)
  if state_type ~= OpenStateType.OpenStateThemeSeason then
    return
  end
  self:update_season_time_state()
  self._send_season_data_changed()
end

function theme_season_module:_on_daily_mission_notify(notify)
  local old_group_id = self:get_daily_group_id()
  local feature_type = tracking_module.track_type.feature
  local source_type = tracking_module.data_source_type.theme_season_daily_task
  local was_tracking = 0 < old_group_id and tracking_module:is_tracking_by_track_type(feature_type, source_type, old_group_id)
  self:update_from_daily_notify(notify)
  if was_tracking then
    local new_group_id = self:get_daily_group_id()
    if old_group_id == new_group_id then
      CsTrackingModuleUtil.RefreshDicTrackData(feature_type)
    else
      tracking_module:set_tracking_by_data_change(feature_type, source_type, old_group_id, false, false)
      if 0 < new_group_id then
        tracking_module:set_tracking_by_data_change(feature_type, source_type, new_group_id, true, true)
        CsTrackingModuleUtil.RefreshDicTrackData(feature_type)
      end
    end
  end
  lua_event_module:send_event(lua_event_module.event_type.on_season_daily_mission_changed)
end

function theme_season_module:_clear_daily_mission_tracking()
  local group_id = self:get_daily_group_id()
  if group_id <= 0 then
    return
  end
  local feature_type = tracking_module.track_type.feature
  local source_type = tracking_module.data_source_type.theme_season_daily_task
  if not tracking_module:is_tracking_by_track_type(feature_type, source_type, group_id) then
    return
  end
  tracking_module:set_tracking_by_data_change(feature_type, source_type, group_id, false, false)
end

function theme_season_module:_on_claim_daily_reward_rsp(rsp)
  if rsp == nil then
    return
  end
  if rsp.Retcode == 0 then
    self:apply_daily_reward_claimed(rsp.TrackerId)
    local mission_list = self:get_daily_mission_list()
    local all_reward_claimed = 0 < #mission_list
    for i = 1, #mission_list do
      if self:get_daily_mission_state(mission_list[i].tracker_id) ~= self.DAILY_MISSION_STATE.CLAIMED then
        all_reward_claimed = false
        break
      end
    end
    if all_reward_claimed then
      self:_clear_daily_mission_tracking()
    end
  else
    self:clear_reward_pending(rsp.TrackerId)
  end
  lua_event_module:send_event(lua_event_module.event_type.on_season_daily_mission_reward, rsp)
end

function theme_season_module:_on_daily_mission_update(notify)
  local tracker_id = notify and notify.TrackerId or 0
  local mission = self:get_daily_mission_by_tracker(tracker_id)
  local was_finished = mission and mission.is_finish
  local has_new_finished_mission = notify and notify.IsFinishConditionMet and not was_finished
  self:update_from_daily_mission_update(notify)
  if has_new_finished_mission then
    UIUtil.show_tips_by_text_id("ThemeSeasonDailyPage_text_Done_36")
  end
  lua_event_module:send_event(lua_event_module.event_type.on_season_daily_mission_update, tracker_id)
end

function theme_season_module:_on_expired_task_record_notify()
  local task_ids = CsThemeSeasonModuleUtil.GetExpiredSeasonTaskIds()
  self:update_expired_season_task_ids(task_ids)
  if task_ids then
    for _, task_id in ipairs(list_to_table(task_ids)) do
      CsMemoModuleUtil.RemoveTaskMemoNode(task_id)
    end
  end
  lua_event_module:send_event(lua_event_module.event_type.on_theme_season_expired_task)
end

return theme_season_module
