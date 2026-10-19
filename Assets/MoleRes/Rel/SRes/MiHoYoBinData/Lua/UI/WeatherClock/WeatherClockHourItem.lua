local M = G.Class("WeatherClockHourItem", G.UIBase)
local base = G.UIBase

function M:refresh(data)
  if data == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local exts = list_to_table(data.weather_data.extendTypes)
  if data.is_current then
    if 0 < #exts then
      self._state_group:SetState(2)
    else
      self._state_group:SetState(1)
    end
    UIUtil.set_text_by_id(self._txt_time, "WeatherClock_Time_Now")
  else
    self._state_group:SetState(0)
    local real_hour = weather_clock_module:hour_index_to_real_hour(data.hour_index)
    UIUtil.set_text(self._txt_time, string.format("%02d:00", real_hour))
  end
  if data.sun_type ~= nil then
    self._state_group:SetState(0)
    local sun = weather_clock_module.sun_icon[data.sun_type]
    UIUtil.set_image(self._img_weather_icon, sun.normal, self:get_load_proxy())
    local text_id = data.sun_type == "rise" and "WeatherClock_Sunrise" or "WeatherClock_Sunset"
    UIUtil.set_text_by_id(self._txt_time, text_id)
  elseif data.weather_data ~= nil then
    local icon_path = ""
    if 0 < #exts then
      local first_ext = exts[1]
      if first_ext and 0 < first_ext then
        local ext_pre_cfg = weather_clock_module:get_weather_extend_pre_cfg(first_ext)
        if ext_pre_cfg and ext_pre_cfg.hideicon ~= 1 then
          icon_path = ext_pre_cfg.icon
        end
      end
    end
    if icon_path == "" then
      local cfg = CsGameplayUtilitiesWeatherUtil.GetWeatherStateCfg(data.weather_data)
      if cfg then
        local real_hour = weather_clock_module:hour_index_to_real_hour(data.hour_index)
        if weather_clock_module:is_night_hour(real_hour) and string.is_valid(cfg.iconnight) then
          icon_path = cfg.iconnight
        else
          icon_path = cfg.icon or ""
        end
      end
    end
    if icon_path ~= "" then
      UIUtil.set_image(self._img_weather_icon, icon_path, self:get_load_proxy())
    end
  end
end

return M
