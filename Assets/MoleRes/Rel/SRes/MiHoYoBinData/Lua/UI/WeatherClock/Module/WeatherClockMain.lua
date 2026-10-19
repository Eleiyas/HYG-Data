weather_clock_module = weather_clock_module or {}

function weather_clock_module:add_event()
  weather_clock_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function weather_clock_module:open_page()
  UIManagerInstance:open("UI/WeatherClock/WeatherClockPage", nil)
end

function weather_clock_module:hour_index_to_real_hour(hour_index)
  return math.floor(TimeUtil.CrossDayHourIndexToLocal(hour_index))
end

function weather_clock_module:is_night_hour(real_hour)
  return real_hour >= self.sunset_hour or real_hour < self.sunrise_hour
end

function weather_clock_module:is_now_night()
  local dt = os.date("!*t", LogicTime.LocalTimeSeconds)
  return self:is_night_hour(dt.hour)
end

function weather_clock_module:get_today_hourly_weathers()
  return CsGameplayUtilitiesWeatherUtil.GetAllDayWeathersFromNowXDay(0)
end

function weather_clock_module:get_today_mode_id()
  return CsGameplayUtilitiesWeatherUtil.GetCurWeatherId()
end

function weather_clock_module:get_forecast_mode_id(x)
  return CsGameplayUtilitiesWeatherUtil.GetWeatherModeIdFromNowXDay(x)
end

function weather_clock_module:get_forecast_extend(x)
  return list_to_table(CsGameplayUtilitiesWeatherUtil.GetForecastWeatherExtendListFromNowXDay(x))
end

function weather_clock_module:get_weather_mode_pre_cfg(mode_id)
  return CsGameplayUtilitiesWeatherUtil.GetWeatherModePreCfg(mode_id)
end

function weather_clock_module:get_weather_extend_pre_cfg(ext_type)
  return CsGameplayUtilitiesWeatherUtil.GetWeatherExtendPreCfg(ext_type)
end

function weather_clock_module:get_description()
  local seen = {}
  local candidates = {}
  for day = 0, self.max_forecast_days - 1 do
    local mode_id = day == 0 and self:get_today_mode_id() or self:get_forecast_mode_id(day - 1)
    local mode_pre_cfg = mode_id ~= 0 and self:get_weather_mode_pre_cfg(mode_id) or nil
    self:_try_add_desc(mode_pre_cfg, seen, candidates)
    local extends = self:get_forecast_extend(day)
    for _, ext in ipairs(extends) do
      local ext_pre_cfg = self:get_weather_extend_pre_cfg(ext)
      self:_try_add_desc(ext_pre_cfg, seen, candidates)
    end
  end
  table.sort(candidates, function(a, b)
    return a.p > b.p
  end)
  local result = {}
  for i = 1, math.min(#candidates, self.max_description_num) do
    result[i] = candidates[i].desc
  end
  return result
end

function weather_clock_module:get_clock_entity_guid()
  local guid_list = EntityUtil.get_entities_by_config_id(self.clock_config_id)
  local guids = list_to_table(guid_list)
  if 0 < #guids then
    return guids[1]
  end
  return 0
end

function weather_clock_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function weather_clock_module:_try_add_desc(pre_cfg, seen, candidates)
  if not pre_cfg then
    return
  end
  local priority = pre_cfg.descriptionpriority or 0
  local mode = pre_cfg.weathermode
  if 0 < priority and not seen[mode] and not seen[priority] then
    seen[mode] = true
    seen[priority] = true
    table.insert(candidates, {
      p = priority,
      desc = pre_cfg.description
    })
  end
end

return weather_clock_module
