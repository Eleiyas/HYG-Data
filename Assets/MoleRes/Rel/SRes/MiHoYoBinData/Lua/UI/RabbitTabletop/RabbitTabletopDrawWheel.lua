local M = G.Class("RabbitTabletopDrawWheel", G.UIPanel)
local base = G.UIPanel
local PUNISH_CFG_ID = 2
local DEFAULT_SPIN_DURATION = 2.5
local SPIN_ROTATIONS = 3
local DIR_LEFT = 1
local DIR_RIGHT = 2
local DIR_TOP = 3
local DIR_BOTTOM = 4
local DIR_ANGLE = {
  [DIR_LEFT] = 90,
  [DIR_RIGHT] = 270,
  [DIR_TOP] = 0,
  [DIR_BOTTOM] = 180
}
local DIR_SELECT = {
  [DIR_TOP] = 1,
  [DIR_LEFT] = 2,
  [DIR_BOTTOM] = 3,
  [DIR_RIGHT] = 4
}
local DIR_TXT_KEY = {
  [DIR_TOP] = "_txt_top",
  [DIR_LEFT] = "_txt_left",
  [DIR_BOTTOM] = "_txt_bottom",
  [DIR_RIGHT] = "_txt_right"
}

function M:on_create()
  base.on_create(self)
  self._cur_select = 0
  self._spin_timer = nil
  self:_load_config()
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

function M:_load_config()
  self._txt_animators = {}
  local animator_type = typeof(CS.Febucci.UI.TextAnimator_TMP)
  for dir, txt_key in pairs(DIR_TXT_KEY) do
    self._txt_animators[dir] = self[txt_key].gameObject:GetComponent(animator_type)
  end
  local cfg = ExcelDataUtil.get_value(typeof(BUnoPunishCfg), PUNISH_CFG_ID)
  if is_null(cfg) then
    return
  end
  self._dir_values = {
    [DIR_LEFT] = cfg:num(0),
    [DIR_RIGHT] = cfg:num(1),
    [DIR_TOP] = cfg:num(2),
    [DIR_BOTTOM] = cfg:num(3)
  }
  UIUtil.set_text(self._txt_top, "+" .. tostring(self._dir_values[DIR_TOP]))
  UIUtil.set_text(self._txt_left, "+" .. tostring(self._dir_values[DIR_LEFT]))
  UIUtil.set_text(self._txt_bottom, "+" .. tostring(self._dir_values[DIR_BOTTOM]))
  UIUtil.set_text(self._txt_right, "+" .. tostring(self._dir_values[DIR_RIGHT]))
end

function M:start_spin(result_num, on_complete, duration, on_post_spin_start)
  local result_dir = self:_get_result_dir(result_num)
  self._spin_result = result_dir
  self._spin_callback = on_complete
  self._on_post_spin_start = on_post_spin_start
  self._spin_duration = duration or DEFAULT_SPIN_DURATION
  self._spin_timer = 0
  self._spin_total_angle = SPIN_ROTATIONS * 360 + DIR_ANGLE[result_dir]
  self:set_select_state(0)
  self:set_arrow_angle(0)
  AudioManagerIns:play_sfx(WType.event.Play_ui_fb_rabbitTabletopMain_wheel3_start)
end

function M:_get_result_dir(result_num)
  for dir, value in pairs(self._dir_values) do
    if value == result_num then
      return dir
    end
  end
  return DIR_TOP
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
    self:set_arrow_angle(DIR_ANGLE[self._spin_result])
    self:set_select_state(DIR_SELECT[self._spin_result])
    self:hide_zone_highlight()
    self:_update_bounce_text(self._spin_result)
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

local DIR_HIGHLIGHT_RANGE = {
  {
    min = 315,
    max = 360,
    dir = DIR_TOP
  },
  {
    min = 0,
    max = 45,
    dir = DIR_TOP
  },
  {
    min = 45,
    max = 135,
    dir = DIR_LEFT
  },
  {
    min = 135,
    max = 225,
    dir = DIR_BOTTOM
  },
  {
    min = 225,
    max = 315,
    dir = DIR_RIGHT
  }
}

function M:_update_zone_highlight(angle)
  local cur_dir = DIR_TOP
  for _, r in ipairs(DIR_HIGHLIGHT_RANGE) do
    if angle >= r.min and angle < r.max then
      cur_dir = r.dir
      break
    end
  end
  UIUtil.set_active(self._trans_top, cur_dir == DIR_TOP)
  UIUtil.set_active(self._trans_left, cur_dir == DIR_LEFT)
  UIUtil.set_active(self._trans_bottom, cur_dir == DIR_BOTTOM)
  UIUtil.set_active(self._trans_right, cur_dir == DIR_RIGHT)
end

function M:hide_zone_highlight()
  UIUtil.set_active(self._trans_top, false)
  UIUtil.set_active(self._trans_left, false)
  UIUtil.set_active(self._trans_bottom, false)
  UIUtil.set_active(self._trans_right, false)
end

function M:_update_bounce_text(cur_dir)
  if not self._dir_values then
    return
  end
  for dir, txt_key in pairs(DIR_TXT_KEY) do
    local val = "+" .. tostring(self._dir_values[dir])
    if dir == cur_dir then
      UIUtil.set_text(self[txt_key], "<bounce>" .. val .. "</bounce>")
    else
      UIUtil.set_text(self[txt_key], val)
    end
  end
end

function M:reset_all_text()
  if not self._dir_values then
    return
  end
  for dir, txt_key in pairs(DIR_TXT_KEY) do
    local animator = self._txt_animators and self._txt_animators[dir]
    if not is_null(animator) then
      animator:ResetState()
    end
    UIUtil.set_text(self[txt_key], "+" .. tostring(self._dir_values[dir]))
  end
end

function M:set_select_state(state)
  self._cur_select = state
  self._state_select:SetState(state)
end

function M:set_arrow_angle(angle)
  self._trans_arrow.localEulerAngles = CS.UnityEngine.Vector3(0, 0, angle)
end

return M
