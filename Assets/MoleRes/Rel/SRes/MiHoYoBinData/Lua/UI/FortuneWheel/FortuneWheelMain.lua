fortune_wheel_module = fortune_wheel_module or {}

function fortune_wheel_module:add_event()
  fortune_wheel_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowFortuneWheelBubbleOverHint] = pack(self, self.on_show_lucky_number)
  self._events[EventID.LuaShowFortuneWheelBubbleFundingHint] = pack(self, self.on_funding_start)
  self._events[EventID.OnFortuneWheelRewardChange] = pack(self, self.update_reward)
  self._events[EventID.onPlayerCreateComplete] = pack(self, self.on_scene_changed)
  self._events[EventID.OnPrizeWheelInfoChanged] = pack(self, self.on_info_changed)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function fortune_wheel_module:on_scene_changed()
  self:init_config()
  local guid_list = EntityUtil.get_entities_by_config_id(self._fortune_wheel_config_id)
  local guids = list_to_table(guid_list)
  if 0 < #guids then
    self._cur_fortune_wheel_guid = guids[1]
  else
    self._cur_fortune_wheel_guid = 0
  end
end

function fortune_wheel_module:on_info_changed()
  local funding_info = CsPrizeWheelModuleUtil.GetFundingInfo()
  self._funding_start_time = funding_info.FundingStartTime
  self._funding_end_time = funding_info.FundingEndTime
end

function fortune_wheel_module:init_config()
  if self._is_init_config then
    return
  end
  local fortune_wheel_config = self:_get_fortune_wheel_config()
  self._fortune_wheel_funding_duration = 0
  self._lucky_number_show_duration = 0
  self._hint_hide_distance = 0
  self._reward_point_config_id = 0
  if fortune_wheel_config ~= nil then
    self._fortune_wheel_funding_duration = fortune_wheel_config.accrualtime
    self._lucky_number_show_duration = fortune_wheel_config.gzimouidisplaytime
    self._hint_hide_distance = fortune_wheel_config.gzimouidisplayrange
    self._reward_point_config_id = fortune_wheel_config.prizecollectionid
    self._fortune_wheel_config_id = 10315
    self._is_init_config = true
  else
    Logger.LogError("fortune wheel config icon is null!")
  end
end

function fortune_wheel_module:update_reward()
  local reward = CsPrizeWheelModuleUtil.GetPlayerRewardInfo()
  if reward.LuckyNumber == 0 then
    return
  end
  self._player_reward = reward
end

function fortune_wheel_module:get_reward_point_guid()
  local guid_list = EntityUtil.get_entities_by_config_id(self._reward_point_config_id)
  local guids = list_to_table(guid_list)
  if 0 < #guids then
    return guids[1]
  end
  return 0
end

function fortune_wheel_module:get_player_reward()
  return self._player_reward
end

function fortune_wheel_module:get_fortune_wheel_guid()
  if self._cur_fortune_wheel_guid == nil then
    self._cur_fortune_wheel_guid = 0
  end
  return self._cur_fortune_wheel_guid
end

function fortune_wheel_module:get_hide_distance()
  return self._hint_hide_distance
end

function fortune_wheel_module:on_show_lucky_number(guid)
  self._cur_fortune_wheel_guid = guid
  self._is_showing_lucky_number = true
  self._lucky_number_show_cur_time = 0
end

function fortune_wheel_module:on_funding_start(guid)
  self._cur_fortune_wheel_guid = guid
  self._is_showing_lucky_number = false
  local funding_info = CsPrizeWheelModuleUtil.GetFundingInfo()
  self._funding_start_time = funding_info.FundingStartTime
  self._funding_end_time = funding_info.FundingEndTime
end

function fortune_wheel_module:is_funding()
  local current_time = TimeUtil.ServerUtcTimeSeconds
  return current_time < self._funding_end_time + 1
end

function fortune_wheel_module:need_update_lucky_number_state()
  return self._is_showing_lucky_number
end

function fortune_wheel_module:get_remain_time()
  local current_time = TimeUtil.ServerUtcTimeSeconds
  local remaining_time = 0
  if current_time < self._funding_end_time then
    remaining_time = self._funding_end_time - current_time
  end
  return remaining_time
end

function fortune_wheel_module:update_lucky_number_state(delta_time)
  self._lucky_number_show_cur_time = self._lucky_number_show_cur_time + delta_time
  if self._lucky_number_show_cur_time > self._lucky_number_show_duration then
    self._is_showing_lucky_number = false
  end
  return self._is_showing_lucky_number
end

function fortune_wheel_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return fortune_wheel_module
