local M = G.Class("WeatherClockDayItem", G.UIPanel)
local base = G.UIPanel
local week_text = {
  "WeatherClock_Week_Sunday",
  "WeatherClock_Week_Monday",
  "WeatherClock_Week_Tuesday",
  "WeatherClock_Week_Wednesday",
  "WeatherClock_Week_Thursday",
  "WeatherClock_Week_Friday",
  "WeatherClock_Week_Saturday"
}

function M:init()
  base.init(self)
  self._icons = {}
end

function M:refresh(data)
  local time_str
  if data.day_index == 0 then
    time_str = "WeatherClock_Week_Today"
  else
    local cross_day_sec = LogicTime.CrossDayTimeSpan.TotalSeconds
    local base_sec = LogicTime.LocalTimeSeconds - cross_day_sec
    local future_sec = base_sec + data.day_index * 86400
    local dt = os.date("!*t", future_sec)
    time_str = week_text[dt.wday] or ""
  end
  UIUtil.set_text_by_id(self._txt_time, time_str)
  local mode_pre_cfg = weather_clock_module:get_weather_mode_pre_cfg(data.mode_id)
  if mode_pre_cfg and mode_pre_cfg.hideicon ~= 1 and string.is_valid(mode_pre_cfg.icon) then
    UIUtil.set_active(self._img_weather_icon, true)
    UIUtil.set_image(self._img_weather_icon, mode_pre_cfg.icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_weather_icon, false)
  end
end

function M:refresh_extends(extends)
  for _, icon_data in ipairs(self._icons) do
    UIUtil.set_active(icon_data.trans, false)
  end
  if extends == nil or #extends == 0 then
    self._state_group:SetState(0)
    return
  end
  self._state_group:SetState(1)
  for i, ext_type in ipairs(extends) do
    if self._icons[i] == nil then
      local go = UIUtil.load_prefab_set_parent(self._obj_extend_icon, self._trans_weather_icon_parent)
      local trans = go.transform
      local img = UIUtil.find_image(trans, "")
      self._icons[i] = {trans = trans, img = img}
    end
    local ext_pre_cfg = weather_clock_module:get_weather_extend_pre_cfg(ext_type)
    if ext_pre_cfg and ext_pre_cfg.hideicon ~= 1 then
      if string.is_valid(ext_pre_cfg.icon) then
        UIUtil.set_image(self._icons[i].img, ext_pre_cfg.icon, self:get_load_proxy())
        UIUtil.set_active(self._icons[i].trans, true)
      else
        UIUtil.set_active(self._icons[i].trans, false)
      end
    else
      UIUtil.set_active(self._icons[i].trans, false)
    end
  end
end

return M
