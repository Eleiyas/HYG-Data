local M = G.Class("SpringFestivalFireworksPage", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalPageBase")
local base = G.SpringFestivalPageBase

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_FireworksPage"
  self._page_key = spring_festival_activity_module.page_key.fireworks
end

function M:on_enable()
  base.on_enable(self)
  self:_mark_running_phases_read()
end

function M:refresh()
  base.refresh(self)
  self:refresh_reward_list(self._layout_itemreward)
end

function M:_mark_running_phases_read()
  local module = spring_festival_activity_module
  local phases = module:get_red_dot_tracking_phases(self._page_key)
  for phase = 1, #phases do
    local slot_id = module:get_xieve_red_dot_slot(phase)
    if module:has_slot_red_dot(slot_id) then
      module:mark_slot_read(slot_id)
    end
  end
end

function M:on_time_tick()
  base.on_time_tick(self)
  self:_refresh_firework_time()
end

function M:_refresh_firework_time()
  if is_null(self._text_fireworktime) then
    return
  end
  local phase_enum = spring_festival_activity_module.time_phase
  local text_ids = spring_festival_activity_module.firework_time_text_id
  local visible_seconds = spring_festival_activity_module.corner_countdown_visible_seconds
  local phase, remain = spring_festival_activity_module:get_firework_phase()
  if phase == phase_enum.running then
    UIUtil.set_active(self._text_fireworktime, true)
    UIUtil.set_text_by_id(self._text_fireworktime, text_ids.ready)
    return
  end
  if phase == phase_enum.before_start and 0 < remain and visible_seconds >= remain then
    UIUtil.set_active(self._text_fireworktime, true)
    UIUtil.set_text_by_id(self._text_fireworktime, text_ids.remain, UIUtil.format_left_time(remain))
    return
  end
  UIUtil.set_active(self._text_fireworktime, false)
end

function M:get_tracking_target()
  local tracking_id = spring_festival_activity_module:get_actionable_tracking_id(self._page_key)
  return spring_festival_activity_module:make_tracking_target_by_id(tracking_id)
end

function M:_refresh_tracking()
  base._refresh_tracking(self)
  self:_refresh_cant_exchange()
end

function M:_refresh_cant_exchange()
  if is_null(self._text_cantexchange) then
    return
  end
  local text_id = spring_festival_activity_module.firework_cant_exchange_text_id[self:get_tracking_state()]
  if string.is_valid(text_id) then
    UIUtil.set_text_by_id(self._text_cantexchange, text_id)
  else
    UIUtil.set_text(self._text_cantexchange, "")
  end
end

function M:get_tracking_state()
  return spring_festival_activity_module:get_tracking_state_by_slot(self._page_key)
end

return M
