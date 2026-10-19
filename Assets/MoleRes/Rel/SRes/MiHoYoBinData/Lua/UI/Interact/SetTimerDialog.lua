local M = G.Class("SetTimerDialog", G.UIWindow)
local base = G.UIWindow
local TIME_SETTER_PANEL_PATH = "UI/Interact/SetTimerTimeSetterPanel"
local STATE_SETTER_PANEL_PATH = "UI/Interact/SetTimerStateSetterPanel"

local function parse_target_guid(extra_data)
  if type(extra_data) == "number" then
    return extra_data
  end
  if type(extra_data) == "table" then
    return extra_data.guid or extra_data.target_guid or extra_data.entity_guid
  end
  return nil
end

local function timestamp_to_hms(timestamp)
  local ts = tonumber(timestamp) or 0
  if ts <= 0 then
    return 0, 0, 0
  end
  local now_ts = tonumber(LogicTime and LogicTime.UtcTimeSeconds) or 0
  if 0 < now_ts and ts <= now_ts then
    return 0, 0, 0
  end
  local offset_seconds = tonumber(LogicTime and LogicTime.TimeZoneOffset and LogicTime.TimeZoneOffset.TotalSeconds) or 0
  local local_ts = ts + offset_seconds
  local seconds_in_day = local_ts % 86400
  if seconds_in_day < 0 then
    seconds_in_day = seconds_in_day + 86400
  end
  local hour = math.floor(seconds_in_day / 3600)
  local minute = math.floor(seconds_in_day % 3600 / 60)
  local second = math.floor(seconds_in_day % 60)
  return hour, minute, second
end

local function get_server_hms()
  local logic_time = LogicTime
  local local_time = logic_time and logic_time.LocalTime
  if local_time == nil then
    return 0, 0, 0
  end
  return local_time.Hour, local_time.Minute, local_time.Second
end

local function hms_to_alarm_timestamp(hour, minute, second)
  local h = math.max(0, math.min(23, tonumber(hour) or 0))
  local m = math.max(0, math.min(59, tonumber(minute) or 0))
  local s = math.max(0, math.min(59, tonumber(second) or 0))
  local now_ts = tonumber(LogicTime and LogicTime.UtcTimeSeconds) or 0
  local target_seconds_in_day = h * 3600 + m * 60 + s
  if now_ts <= 0 then
    return target_seconds_in_day
  end
  local offset_seconds = tonumber(LogicTime and LogicTime.TimeZoneOffset and LogicTime.TimeZoneOffset.TotalSeconds) or 0
  local local_now_ts = now_ts + offset_seconds
  local today_start_local = local_now_ts - local_now_ts % 86400
  local target_local_ts = today_start_local + target_seconds_in_day
  if local_now_ts >= target_local_ts then
    target_local_ts = target_local_ts + 86400
  end
  return target_local_ts - offset_seconds
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Interact/SetTimerDialog"
  self.config.type = EUIType.Page
  self._time_setter_panel = nil
  self._state_setter_panel = nil
  self._timer_enabled = false
  self._hour = 0
  self._minute = 0
  self._second = 0
  self._guid = nil
  self._has_initial_alarm = false
  self._has_confirmed_time = false
  self._is_showing_time_setter = false
  self._last_server_second = -1
end

function M:on_create()
  base.on_create(self)
  self._time_setter_panel = self:add_panel(TIME_SETTER_PANEL_PATH, self._trans_time_setter)
  self._state_setter_panel = self:add_panel(STATE_SETTER_PANEL_PATH, self._trans_state_setter)
  self._time_setter_panel:set_on_time_changed(pack(self, M._on_time_changed))
  self._time_setter_panel:set_on_confirm(pack(self, M._on_time_confirm))
  self._state_setter_panel:set_on_modify_click(pack(self, M._on_click_modify_time))
  self._state_setter_panel:set_on_switch_changed(pack(self, M._on_timer_switch_changed))
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_click_close))
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_alarm_data_from_entity()
  self._time_setter_panel:set_time(self._hour, self._minute, self._second)
  self._state_setter_panel:set_time(self._hour, self._minute, self._second)
  self._state_setter_panel:set_switch(self._timer_enabled)
  if self._has_initial_alarm then
    self:_show_state_setter()
  else
    self:_show_time_setter()
  end
  self:_refresh_server_time_text()
end

function M:update(delta_time)
  base.update(self, delta_time)
  self:_refresh_server_time_text()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self._time_setter_panel = nil
  self._state_setter_panel = nil
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_show_time_setter()
  UIUtil.set_active(self._trans_time_setter, true)
  UIUtil.set_active(self._trans_state_setter, false)
  self._is_showing_time_setter = true
end

function M:_show_state_setter()
  UIUtil.set_active(self._trans_time_setter, false)
  UIUtil.set_active(self._trans_state_setter, true)
  self._is_showing_time_setter = false
end

function M:_on_click_modify_time()
  self:_show_time_setter()
end

function M:_on_timer_switch_changed(is_on)
  self._timer_enabled = is_on == true
  self:_save_alarm_to_server()
end

function M:_on_time_changed(hour, minute, second)
  self._hour = hour or 0
  self._minute = minute or 0
  self._second = second or 0
  self._state_setter_panel:set_time(self._hour, self._minute, self._second)
end

function M:_on_time_confirm(hour, minute, second)
  self:_on_time_changed(hour, minute, second)
  self._timer_enabled = true
  self._state_setter_panel:set_switch(true)
  self._has_confirmed_time = true
  self:_save_alarm_to_server()
  self:_show_state_setter()
end

function M:_save_alarm_to_server()
  if not self._guid then
    return
  end
  local timestamp = hms_to_alarm_timestamp(self._hour, self._minute, self._second)
  CsUIUtil.SendSetFurnitureAlarmReq(self._guid, timestamp, self._timer_enabled == true)
end

function M:_refresh_server_time_text()
  if is_null(self._txt_time) then
    return
  end
  local hour, minute, second = get_server_hms()
  if self._last_server_second == second then
    return
  end
  self._last_server_second = second
  UIUtil.set_text(self._txt_time, string.format("%02d:%02d:%02d", hour, minute, second))
end

function M:_on_click_close()
  if self._is_showing_time_setter and not self._has_initial_alarm and not self._has_confirmed_time then
    self:close_self()
    return
  end
  if self._is_showing_time_setter then
    self:_show_state_setter()
    return
  end
  self:close_self()
end

function M:_init_alarm_data_from_entity()
  self._has_initial_alarm = false
  self._has_confirmed_time = false
  self._guid = parse_target_guid(self:get_extra_data())
  if not self._guid then
    return
  end
  local entity_data = GameplayUtilities_Entities.GetEntityData(self._guid)
  if not entity_data or not entity_data.FurnitureAlarmInfo then
    return
  end
  local alarm_info = entity_data.FurnitureAlarmInfo
  local timestamp = tonumber(alarm_info.AlarmTimestamp) or 0
  if timestamp <= 0 then
    return
  end
  self._hour, self._minute, self._second = timestamp_to_hms(timestamp)
  self._timer_enabled = alarm_info.IsEnabled == true
  self._has_initial_alarm = true
end

return M
