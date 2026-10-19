spring_festival_notice_module = spring_festival_notice_module or {}

local function _spring_notice_log(msg)
  if LogUtil and LogUtil.Log then
    LogUtil.Log(msg)
    return
  end
  Logger.Log(msg)
end

spring_festival_notice_module.scene_type = {main_page = 1, online_authority = 2}
spring_festival_notice_module.trigger_type = {
  on_enable = 1,
  login = 2,
  leave_house = 3,
  enter_other_planet = 4,
  special_btn = 5,
  daily_refresh = 6
}

function spring_festival_notice_module:_init_data()
  self._notice_data = {
    [self.scene_type.main_page] = {},
    [self.scene_type.online_authority] = {}
  }
  self._data_owner_uid = 0
end

function spring_festival_notice_module:mark_data_synced_for_current_scene(explicit_owner_uid)
  local owner_uid = tonumber(explicit_owner_uid) or 0
  if owner_uid == 0 and player_module ~= nil and player_module.get_scene_owner_uid ~= nil then
    owner_uid = player_module:get_scene_owner_uid() or 0
  end
  self._data_owner_uid = owner_uid
  _spring_notice_log(string.format("[SpringFestivalNoticeData] mark_data_synced_for_current_scene owner_uid=%s (explicit=%s)", tostring(owner_uid), tostring(explicit_owner_uid)))
  return owner_uid
end

function spring_festival_notice_module:try_consume_initial_sync_data()
  if CsSpringFestivalModuleUtil == nil or CsSpringFestivalModuleUtil.IsNull() or not CsSpringFestivalModuleUtil.HasSpringFestivalData then
    return
  end
  if (self._data_owner_uid or 0) ~= 0 then
    return
  end
  self:mark_data_synced_for_current_scene()
end

local function _apply_server_data(data, trigger_type, scene_type)
  if data == nil then
    return nil
  end
  local daily_red_envelope_receive_count = CsSpringFestivalModuleUtil.DailyRedEnvelopeReceiveCount
  local daily_up_lucky_bag_id = CsSpringFestivalModuleUtil.DailyUpLuckyBagId
  local daily_lucky_bag_group_id = CsSpringFestivalModuleUtil.DailyLuckyBagGroupId
  local daily_up_lucky_bag_icon = CsSpringFestivalModuleUtil.DailyUpLuckyBagIcon
  local daily_up_lucky_bag_name = CsSpringFestivalModuleUtil.DailyUpLuckyBagName
  local mainland_name = ""
  local world_info = CsPlayerVisitModuleUtil.GetWorldInfo()
  if world_info ~= nil then
    mainland_name = world_info.MainlandName or ""
  end
  if mainland_name == "" then
    mainland_name = CsGuideBoardLuaBridgeUtil.HostMainlandName or ""
  end
  if mainland_name == "" then
    local world_owner_info = CsWorldInfoLuaBridgeUtil.GetWorldOwnerInfo()
    if world_owner_info ~= nil then
      mainland_name = world_owner_info.MainlandName or ""
    end
  end
  data.daily_red_envelope_receive_count = daily_red_envelope_receive_count
  data.daily_up_lucky_bag_id = daily_up_lucky_bag_id
  data.daily_lucky_bag_group_id = daily_lucky_bag_group_id
  data.daily_up_lucky_bag_icon = daily_up_lucky_bag_icon
  data.daily_up_lucky_bag_name = daily_up_lucky_bag_name
  data.mainland_name = mainland_name
  if string.is_valid(daily_up_lucky_bag_icon) then
    data.icon_path = daily_up_lucky_bag_icon
  end
  if string.is_valid(daily_up_lucky_bag_name) then
    data.title = daily_up_lucky_bag_name
  else
    data.title = ""
  end
  data.show_subtitle_ex = trigger_type == spring_festival_notice_module.trigger_type.daily_refresh and scene_type == spring_festival_notice_module.scene_type.main_page
  data.subtitle_text_id = "SpringFestival_Notice_Content"
  data.subtitle_args = {
    mainland_name or ""
  }
  _spring_notice_log(string.format("[SpringFestivalNoticeData] up_id=%s group_id=%s icon=%s mainland=%s", tostring(daily_up_lucky_bag_id), tostring(daily_lucky_bag_group_id), tostring(daily_up_lucky_bag_icon), tostring(mainland_name)))
  return data
end

function spring_festival_notice_module:get_notice_data(scene_type, trigger_type)
  local data = self._notice_data and self._notice_data[scene_type] or nil
  return _apply_server_data(data, trigger_type, scene_type)
end

function spring_festival_notice_module:should_show_notice(trigger_type, scene_type)
  if CsSpringFestivalModuleUtil == nil then
    _spring_notice_log("[SpringFestivalNoticeData][Error] CsSpringFestivalModuleUtil is nil")
    return false
  end
  if CsSpringFestivalModuleUtil.IsNull() then
    return false
  end
  if not CsSpringFestivalModuleUtil.HasSpringFestivalData then
    return false
  end
  if self._notice_data == nil or self._notice_data[scene_type] == nil then
    return false
  end
  local activity_opened = spring_festival_gate_module ~= nil and spring_festival_gate_module.is_drop_rate_up_activity_opened ~= nil and spring_festival_gate_module:is_drop_rate_up_activity_opened() == true
  if not activity_opened then
    return false
  end
  local tracker_pass = spring_festival_gate_module ~= nil and spring_festival_gate_module.is_tracker_8010_pass ~= nil and spring_festival_gate_module:is_tracker_8010_pass() == true
  if not tracker_pass then
    return false
  end
  local data_owner_uid = self._data_owner_uid or 0
  local current_owner_uid = 0
  if player_module ~= nil and player_module.get_scene_owner_uid ~= nil then
    current_owner_uid = player_module:get_scene_owner_uid() or 0
  end
  if data_owner_uid == 0 or current_owner_uid == 0 or data_owner_uid ~= current_owner_uid then
    _spring_notice_log(string.format("[SpringFestivalNoticeData] owner mismatch skip data_owner=%s current_owner=%s trigger=%s scene=%s", tostring(data_owner_uid), tostring(current_owner_uid), tostring(trigger_type), tostring(scene_type)))
    return false
  end
  if trigger_type == self.trigger_type.special_btn then
    return true
  end
  return true
end

return spring_festival_notice_module
