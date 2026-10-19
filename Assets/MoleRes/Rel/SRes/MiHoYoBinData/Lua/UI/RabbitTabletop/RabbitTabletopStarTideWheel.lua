local M = G.Class("RabbitTabletopStarTideWheel", G.UIPanel)
local base = G.UIPanel
local DEFAULT_SPIN_DURATION = 2.5
local SPIN_ROTATIONS = 3
local RESULT_ANGLE = {
  [rabbit_tabletop_module.star_tide_select.safe] = 0,
  [rabbit_tabletop_module.star_tide_select.star_tide] = 180
}

function M:on_create()
  base.on_create(self)
  self._cur_select = rabbit_tabletop_module.star_tide_select.none
  self._spin_timer = nil
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  self._spin_timer = nil
  self._post_spin_timer = nil
  self._spin_callback = nil
  self._on_post_spin_start = nil
end

function M:start_spin(result, on_complete, duration, on_post_spin_start)
  self._spin_result = result
  self._spin_callback = on_complete
  self._on_post_spin_start = on_post_spin_start
  self._spin_duration = duration or DEFAULT_SPIN_DURATION
  self._spin_timer = 0
  self._spin_total_angle = SPIN_ROTATIONS * 360 + RESULT_ANGLE[result]
  self:set_select_state(rabbit_tabletop_module.star_tide_select.none)
  self:set_arrow_angle(0)
  AudioManagerIns:play_sfx(WType.event.Play_ui_fb_rabbitTabletopMain_wheel1_start)
end

function M:tick_spin(deltaTime)
  self:_tick_post_spin(deltaTime)
  if not self._spin_timer then
    return
  end
  self._spin_timer = self._spin_timer + deltaTime
  local t = math.min(self._spin_timer / self._spin_duration, 1)
  local ease = 1 - (1 - t) ^ 4
  local angle = self._spin_total_angle * ease
  local cur_angle = angle % 360
  self:set_arrow_angle(cur_angle)
  self:_update_zone_highlight(cur_angle)
  if 1 <= t then
    self._spin_timer = nil
    self:set_arrow_angle(RESULT_ANGLE[self._spin_result])
    self:set_select_state(self._spin_result)
    self:hide_zone_highlight()
    self._post_spin_timer = 1
    if self._on_post_spin_start then
      local cb = self._on_post_spin_start
      self._on_post_spin_start = nil
      cb()
    end
  end
end

function M:_tick_post_spin(deltaTime)
  if not self._post_spin_timer then
    return
  end
  self._post_spin_timer = self._post_spin_timer - deltaTime
  if self._post_spin_timer <= 0 then
    self._post_spin_timer = nil
    self:set_active(false)
  end
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  if self._spin_callback then
    self._spin_callback()
    self._spin_callback = nil
  end
end

function M:_update_zone_highlight(angle)
  local in_safe = angle < 90 or 270 < angle
  UIUtil.set_active(self._trans_safe, in_safe)
  UIUtil.set_active(self._trans_hit, not in_safe)
end

function M:hide_zone_highlight()
  UIUtil.set_active(self._trans_safe, false)
  UIUtil.set_active(self._trans_hit, false)
end

function M:set_select_state(state)
  self._cur_select = state
  self._state_select:SetState(state)
end

function M:set_arrow_angle(angle)
  self._trans_arrow.localEulerAngles = CS.UnityEngine.Vector3(0, 0, angle)
end

return M
