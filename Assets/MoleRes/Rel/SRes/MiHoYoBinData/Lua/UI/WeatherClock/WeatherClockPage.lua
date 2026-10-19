local M = G.Class("WeatherClockPage", G.UIWindow)
local base = G.UIWindow
local hour_item_cls = "UI/WeatherClock/WeatherClockHourItem"
local day_item_cls = "UI/WeatherClock/WeatherClockDayItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/WeatherClock/WeatherClockPage"
  self.config.type = EUIType.Page
  self._hour_items = {}
  self._day_items = {}
end

function M:on_create()
  base.on_create(self)
  UIUtil.set_active(self._obj_day_item, false)
  UIUtil.set_active(self._obj_hour_item, false)
  self._txt_des_tb = {}
  UIUtil.set_active(self._obj_des, false)
  for i = 1, weather_clock_module.max_description_num do
    local obj = UIUtil.load_prefab_set_parent(self._obj_des, self._trans_des_parent)
    self._txt_des_tb[i] = UIUtil.find_text(obj.transform)
  end
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self._time_elapsed = 0
  self._last_min = -1
  self._clock_guid = weather_clock_module:get_clock_entity_guid()
  if 0 < self._clock_guid then
    local clock_entity = EntityUtil.get_entity(self._clock_guid)
    CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByEntity("WeatherClock", clock_entity, clock_entity)
  end
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
  if self._clock_guid > 0 then
    CsGameplayUtilitiesCameraUtil.PopState("WeatherClock")
  end
end

function M:update(deltaTime)
  self._time_elapsed = self._time_elapsed + deltaTime
  if self._time_elapsed < 1 then
    return
  end
  self._time_elapsed = 0
  local dt = os.date("!*t", LogicTime.LocalTimeSeconds)
  if dt.min == self._last_min then
    return
  end
  self._last_min = dt.min
  UIUtil.set_text(self._txt_now_time, string.format("%02d:%02d", dt.hour, dt.min))
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnWeatherChange, function()
    self:_refresh_view()
  end)
  self:add_evt_listener(EventID.OnForecastWeatherExtendUpdate, function()
    self:_refresh_day_extend_weather()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_refresh_view()
  self:_refresh_detail()
  self:_refresh_hour_items()
  self:_refresh_day_items()
  CsGameplayUtilitiesWeatherUtil.RefreshWeatherExtends(weather_clock_module.max_forecast_days)
end

function M:_refresh_detail()
  local name = CsGuideBoardLuaBridgeUtil.HostMainlandName
  UIUtil.set_text(self._txt_planet_name, name or "")
  local dt = os.date("!*t", LogicTime.LocalTimeSeconds)
  UIUtil.set_text(self._txt_now_time, string.format("%02d:%02d", dt.hour, dt.min))
  local cur_weather = CsGameplayUtilitiesWeatherUtil.GetCurWeather()
  local weather_cfg = CsGameplayUtilitiesWeatherUtil.GetWeatherStateCfg(cur_weather)
  if weather_cfg then
    local big_icon = weather_cfg.iconbig
    if weather_clock_module:is_now_night() and string.is_valid(weather_cfg.iconbignight) then
      big_icon = weather_cfg.iconbignight
    end
    UIUtil.set_image(self._img_now_weather_icon, big_icon, self:get_load_proxy())
  end
  self._state_group_now_weather:SetState(0)
  if cur_weather and cur_weather.extendTypes then
    local exts = list_to_table(cur_weather.extendTypes)
    local first_ext = exts[1]
    if first_ext and 0 < first_ext then
      local ext_pre_cfg = weather_clock_module:get_weather_extend_pre_cfg(first_ext)
      if ext_pre_cfg and ext_pre_cfg.hideicon ~= 1 and string.is_valid(ext_pre_cfg.iconbig) then
        UIUtil.set_image(self._img_now_weather_icon, ext_pre_cfg.iconbig, self:get_load_proxy())
      end
      if first_ext == weather_clock_module.extend_type.rainbow then
        self._state_group_now_weather:SetState(2)
      elseif first_ext == weather_clock_module.extend_type.meteor_shower or first_ext == weather_clock_module.extend_type.major_meteor_shower then
        self._state_group_now_weather:SetState(3)
      end
    end
  end
  local des_tb = weather_clock_module:get_description()
  for i = 1, weather_clock_module.max_description_num do
    if self._txt_des_tb[i] then
      local valid = string.is_valid(des_tb[i])
      UIUtil.set_active(self._txt_des_tb[i], valid)
      if valid then
        UIUtil.set_text(self._txt_des_tb[i], des_tb[i])
      end
    end
  end
end

function M:_get_or_create_hour_item(index)
  local item = self._hour_items[index]
  if item == nil then
    local go = UIUtil.load_prefab_set_parent(self._obj_hour_item, self._trans_hour_parent)
    item = self:add_panel(hour_item_cls, go.transform)
    self._hour_items[index] = item
  end
  return item
end

function M:_refresh_hour_items()
  local weathers = weather_clock_module:get_today_hourly_weathers()
  if weathers == nil then
    return
  end
  local weathers_tb = list_to_table(weathers)
  UIUtil.set_active(self._obj_hour_item, false)
  local cur_hour_index = CsGameplayUtilitiesWeatherUtil.GetCurHourIndex()
  local item_count = 0
  local cur_item_pos = 0
  for i, weather_data in ipairs(weathers_tb) do
    local hour_index = i - 1
    local real_hour = weather_clock_module:hour_index_to_real_hour(hour_index)
    if real_hour == weather_clock_module.sunrise_hour or real_hour == weather_clock_module.sunset_hour then
      item_count = item_count + 1
      local sun_item = self:_get_or_create_hour_item(item_count)
      sun_item:refresh({
        weather_data = weather_data,
        hour_index = hour_index,
        is_current = false,
        sun_type = real_hour == weather_clock_module.sunrise_hour and "rise" or "down"
      })
    end
    item_count = item_count + 1
    local item = self:_get_or_create_hour_item(item_count)
    item:refresh({
      weather_data = weather_data,
      hour_index = hour_index,
      is_current = cur_hour_index == hour_index
    })
    if cur_hour_index == hour_index then
      cur_item_pos = item_count - 1
    end
  end
  for i = item_count + 1, #self._hour_items do
    self._hour_items[i]:refresh(nil)
  end
  local item_width = self._rect_hour_item:GetWidth()
  local viewport_width = self._scroll_rect.transform:GetWidth()
  local content_width = item_count * item_width
  local scrollable = content_width - viewport_width
  if 0 < scrollable then
    local target = cur_item_pos * item_width - viewport_width / 2 + item_width
    target = math.max(0, math.min(target, scrollable))
    self._scroll_rect.horizontalNormalizedPosition = target / scrollable
  end
end

function M:_refresh_day_items()
  UIUtil.set_active(self._obj_day_item, false)
  local today_mode_id = weather_clock_module:get_today_mode_id()
  local valid_count = 0
  for day_index = 0, weather_clock_module.max_forecast_days - 1 do
    local mode_id
    if day_index == 0 then
      mode_id = today_mode_id
    else
      mode_id = weather_clock_module:get_forecast_mode_id(day_index - 1)
    end
    if mode_id == nil or mode_id == 0 then
      break
    end
    valid_count = valid_count + 1
    local item = self._day_items[valid_count]
    if item == nil then
      local go = UIUtil.load_prefab_set_parent(self._obj_day_item, self._trans_day_parent)
      item = self:add_panel(day_item_cls, go.transform)
      self._day_items[valid_count] = item
    end
    UIUtil.set_active(item.trans, true)
    item:refresh({mode_id = mode_id, day_index = day_index})
  end
  for i = valid_count + 1, #self._day_items do
    self._day_items[i]:refresh(nil)
  end
end

function M:_refresh_day_extend_weather()
  for i, item in ipairs(self._day_items) do
    local day_index = i - 1
    local extends = weather_clock_module:get_forecast_extend(day_index) or {}
    item:refresh_extends(extends)
  end
end

return M
