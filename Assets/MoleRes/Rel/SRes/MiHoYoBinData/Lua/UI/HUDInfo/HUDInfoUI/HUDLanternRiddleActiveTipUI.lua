local M = G.Class("HUDLanternRiddleActiveTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local PROGRESS_TWEEN_TIME = 1.5
local DEFAULT_SHOW_TIME = 3.0
local add_info_cls = "UI/MainActivity_y1/SpringFestival/SpringFestivalDAUIncreaseAddInfo"
local ANIM_OUT_CLIP = "anim_springfestival_dauincreasedialog_out"
local ANIM_OUT_FALLBACK_TIME = 0.833
local ADD_INFO_LEAD_TIME = 0.8

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_DAUIncreaseDialog"
  self._progress_tween = nil
  self._need_lantern_fly = false
  self._add_info_coroutine = nil
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
  self:start_close_timer(DEFAULT_SHOW_TIME, function(ui)
    ui:_play_exit_then_close()
  end)
end

function M:on_disable()
  base.on_disable(self)
  self:_kill_tween()
  self:_kill_add_info_timer()
end

function M:_refresh_view()
  if self._extra_data == nil then
    return
  end
  local before_active = tonumber(self._extra_data.BeforeActive) or tonumber(self._extra_data.before_active) or 0
  local after_active = tonumber(self._extra_data.AfterActive) or tonumber(self._extra_data.after_active) or 0
  local max_active = tonumber(self._extra_data.MaxActive) or tonumber(self._extra_data.max_active) or 0
  local is_correct = self._extra_data.IsCorrect == true or self._extra_data.is_correct == true
  local is_full = self._extra_data.IsFull == true or self._extra_data.is_full == true
  if not_null(self._trans_highadd) then
    UIUtil.set_active(self._trans_highadd, false)
  end
  local text_id = "LanternRiddle_Riddle_SmallGrow"
  if is_full then
    text_id = "LanternRiddle_Riddle_Full"
  elseif is_correct then
    if not_null(self._trans_highadd) then
      UIUtil.set_active(self._trans_highadd, true)
    end
    text_id = "LanternRiddle_Riddle_BigGrow"
  end
  if not_null(self._text_title) then
    UIUtil.set_text_by_id(self._text_title, text_id)
  end
  if riddle_module ~= nil and riddle_module:is_stage_unlocked_by_active_change(before_active, after_active) then
    self._need_lantern_fly = true
  end
  if max_active <= 0 or is_null(self._slider_increace) then
    if not_null(self._slider_increace) then
      self._slider_increace.value = 0
    end
    return
  end
  self:_kill_tween()
  local from_val = math.max(0, math.min(1, before_active / max_active))
  local to_val = math.max(0, math.min(1, after_active / max_active))
  self._slider_increace.value = from_val
  self._progress_tween = UIUtil.dt_to_anim(from_val, to_val, PROGRESS_TWEEN_TIME, function(v)
    if not_null(self._slider_increace) then
      self._slider_increace.value = v
    end
  end)
end

function M:_play_exit_then_close()
  local from_position
  if self._need_lantern_fly then
    if is_null(self._trans_icon) then
      Logger.LogWarning("[HUDLanternRiddleActiveTipUI] _trans_icon is missing on prefab, skip lantern fly effect.")
    else
      local x, y, z = self._trans_icon:GetPosition()
      from_position = {
        x = x,
        y = y,
        z = z
      }
    end
  end
  self._need_lantern_fly = false
  if from_position ~= nil then
    local delay = math.max(0, self:_get_out_anim_time() - ADD_INFO_LEAD_TIME)
    self._add_info_coroutine = CsCoroutineManagerUtil.Invoke(delay, function()
      self._add_info_coroutine = nil
      UIManagerInstance:open(add_info_cls, {from_position = from_position})
    end)
  end
  self.binder:PlayExitAnim(function()
    self:close_self()
  end)
end

function M:_get_out_anim_time()
  local animation = UIUtil.find_cmpt(self.trans, nil, typeof(Animation))
  if not_null(animation) then
    local clip = animation:GetClip(ANIM_OUT_CLIP)
    if not_null(clip) and clip.length > 0 then
      return clip.length
    end
  end
  return ANIM_OUT_FALLBACK_TIME
end

function M:_kill_add_info_timer()
  if not_null(self._add_info_coroutine) then
    CsCoroutineManagerUtil.StopCoroutine(self._add_info_coroutine)
    self._add_info_coroutine = nil
  end
end

function M:play_exit_anim()
  self:exit_anim_call_back()
end

function M:_kill_tween()
  if self._progress_tween ~= nil then
    self._progress_tween:Kill(false)
    self._progress_tween = nil
  end
end

return M
