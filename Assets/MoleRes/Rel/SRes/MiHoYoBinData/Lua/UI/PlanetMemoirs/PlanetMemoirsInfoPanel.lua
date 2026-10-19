local M = G.Class("PlanetMemoirsInfoPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._fading = false
  self._fade_from = 0
  self._fade_to_alpha = 0
  self._fade_duration = 0
  self._fade_elapsed = 0
  self._fade_callback = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  self:stop_fade()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._fading then
    return
  end
  self._fade_elapsed = self._fade_elapsed + deltaTime
  local t = self._fade_elapsed / self._fade_duration
  if 1 <= t then
    t = 1
  end
  self._canvas_group.alpha = self._fade_from + (self._fade_to_alpha - self._fade_from) * t
  if 1 <= t then
    self._fading = false
    local cb = self._fade_callback
    self._fade_callback = nil
    if cb ~= nil then
      cb()
    end
  end
end

function M:refresh_view(cfg, alpha)
  if cfg == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local time_text = self:_format_tracker_time(cfg.trackerid)
  UIUtil.set_text(self._txt_time, time_text)
  UIUtil.set_text(self._txt_info, cfg.description or "")
  if string.is_valid(cfg.icon) then
    UIUtil.set_active(self._img, true)
    UIUtil.set_image(self._img, cfg.icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._img, false)
  end
  self:set_alpha(alpha or 0)
end

function M:set_alpha(alpha)
  self._fading = false
  self._fade_callback = nil
  if not_null(self._canvas_group) then
    self._canvas_group.alpha = alpha
  end
end

function M:fade_to(target_alpha, duration, on_complete)
  if is_null(self._canvas_group) then
    if on_complete ~= nil then
      on_complete()
    end
    return
  end
  if duration == nil or duration <= 0 then
    self._fading = false
    self._canvas_group.alpha = target_alpha
    self._fade_callback = nil
    if on_complete ~= nil then
      on_complete()
    end
    return
  end
  self._fade_from = self._canvas_group.alpha
  self._fade_to_alpha = target_alpha
  self._fade_duration = duration
  self._fade_elapsed = 0
  self._fade_callback = on_complete
  self._fading = true
end

function M:stop_fade()
  self._fading = false
  self._fade_callback = nil
end

function M:show(visible)
  self:set_active(visible)
  if visible then
    self:set_alpha(1)
  else
    self:set_alpha(0)
  end
end

function M:_format_tracker_time(tracker_id)
  if tracker_id == nil or tracker_id == 0 then
    return ""
  end
  local timestamp = CsGameplayUtilitiesTrackerUtil.GetTrackerTriggerFinishTime(tracker_id) or 0
  if timestamp == 0 then
    return ""
  end
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(timestamp)
  return TextMapFormatUtil.FormatDateYMD(date_time)
end

return M
