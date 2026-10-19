local M = G.Class("SpringFestivalCalendarDayItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._data = nil
  self._applied_time_type = nil
  self._applied_now_state = nil
end

function M:refresh(data, is_today)
  if data == nil then
    self:set_active(false)
    return
  end
  self._data = data
  self:set_active(true)
  self:_apply_time_type(data.time_type)
  self:_apply_now_state(is_today)
  self:_refresh_date_text()
  self:_refresh_lunar_text()
end

function M:_refresh_date_text()
  if is_null(self._text_today) then
    return
  end
  UIUtil.set_text(self._text_today, string.format("%02d", self._data.day))
end

function M:_refresh_lunar_text()
  if is_null(self._text_lunarcalendar) then
    return
  end
  local text_id = self._data.lunar_text_id
  local has_lunar_name = string.is_valid(text_id)
  UIUtil.set_active(self._text_lunarcalendar, has_lunar_name)
  if has_lunar_name then
    UIUtil.set_text_by_id(self._text_lunarcalendar, text_id)
  end
end

function M:_apply_time_type(time_type)
  if is_null(self._state_timetype) then
    Logger.LogWarning("[SpringFestivalCalendarDayItem] _state_timetype is missing on prefab.")
    return
  end
  if self._applied_time_type == time_type then
    return
  end
  self._applied_time_type = time_type
  self._state_timetype:SetState(time_type)
end

function M:_apply_now_state(is_today)
  local now_enum = spring_festival_activity_module.calendar_now_state
  local now_state = is_today and now_enum.today or now_enum.normal
  if is_null(self._state_daynow) then
    Logger.LogWarning("[SpringFestivalCalendarDayItem] _state_daynow is missing on prefab.")
    return
  end
  if self._applied_now_state == now_state then
    return
  end
  self._applied_now_state = now_state
  self._state_daynow:SetState(now_state)
end

return M
