local M = G.Class("BirthdayBlowPage", G.UIWindow)
local base = G.UIWindow
local CANDLE_STATE = {
  opening = 1,
  sway = 2,
  close = 3,
  closing = 4
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PlayerBirthday/BirthdayBlowPage"
  self.config.type = EUIType.Page
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = false,
      camera = false,
      ability = false
    },
    ui_cfg = {
      player_ctrl = false,
      ability = false,
      tip = false
    }
  }
end

function M:on_create()
  base.on_create(self)
  self:_bind_ui()
end

function M:on_enable()
  base.on_enable(self)
  local args = self:get_extra_data() or {}
  self._hold_full_seconds = args.HoldFullSeconds or 3.0
  self._blow_speed_per_sec = args.BlowSpeedPerSec or 0.5
  self._blow_rms_threshold = args.BlowRmsThreshold or 0.08
  self._tip_text_map = args.TipText
  self._fill = 0
  self._is_holding = false
  self._is_blow_visual_active = false
  self._clear_delay_seconds = 0.5
  self._inactive_seconds = 0
  self._completed = false
  self._has_close_result_sent = false
  self._blow_detect_started = false
  self._candle_guids = args.CandleGuids
  self._candle_state = nil
  self._was_active_input = false
  if not_null(self._progress) then
    self._progress.fillAmount = 0
  end
  self:_dispatch_candle_state(CANDLE_STATE.opening)
  local application = CS.UnityEngine.Application
  local runtime_platform = CS.UnityEngine.RuntimePlatform
  local platform = application.platform
  if platform == runtime_platform.Android then
    local sdk = CS.MiHoYo.SDK.MiHoYoSDK.Instance()
    if not_null(sdk) then
      local permission_result = sdk:InvokeReturn(MHYSDKC.Launch.IS_PERMISSION_OPEN, "android.permission.RECORD_AUDIO")
      self._blow_detect_started = permission_result == "true"
    end
  else
    self._blow_detect_started = true
  end
  if self._blow_detect_started then
    CsBirthdayModuleUtil.StartBlowDetect(self._blow_rms_threshold)
  end
  self:_refresh_tips_text()
end

function M:on_before_close()
  base.on_before_close(self)
  if self._has_close_result_sent then
    return
  end
  self._has_close_result_sent = true
  if self._completed then
    self:_dispatch_candle_state(CANDLE_STATE.closing)
    EventCenter.Broadcast(EventID.LuaExitBirthdayBlowComplete)
  else
    self:_dispatch_candle_state(CANDLE_STATE.opening)
    EventCenter.Broadcast(EventID.LuaExitBirthdayBlowAbort)
  end
end

function M:on_disable()
  base.on_disable(self)
  self._is_holding = false
  self._inactive_seconds = 0
  self._was_active_input = false
  self:_set_blow_visual_active(false)
  if self._blow_detect_started then
    CsBirthdayModuleUtil.StopBlowDetect()
    self._blow_detect_started = false
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.ControllerUIChange, function()
    self:_refresh_tips_text()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.F, pack(self, M._on_blow_press_down), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.F, pack(self, M._on_blow_press_up), ActionType.EType.ButtonReleased)
end

function M:update(deltaTime)
  if not self.is_active or self._completed then
    return
  end
  local gain = 0
  local is_holding = self:_is_holding_input()
  local is_blowing = false
  if self._blow_detect_started then
    CsBirthdayModuleUtil.EvaluateBlow()
    is_blowing = CsBirthdayModuleUtil.IsBlowAvailable and CsBirthdayModuleUtil.IsBlowing
  end
  local has_active_input = is_holding or is_blowing
  if has_active_input and not self._was_active_input then
    self:_dispatch_candle_state(CANDLE_STATE.sway)
  elseif self._was_active_input and not has_active_input and not self._completed then
    self:_dispatch_candle_state(CANDLE_STATE.opening)
  end
  self._was_active_input = has_active_input
  if is_holding then
    gain = gain + deltaTime / self._hold_full_seconds
  end
  if is_blowing then
    local intensity = CsBirthdayModuleUtil.BlowIntensity
    gain = gain + deltaTime * self._blow_speed_per_sec * intensity
  end
  if has_active_input then
    self._inactive_seconds = 0
  elseif 0 < self._fill then
    self._inactive_seconds = self._inactive_seconds + deltaTime
    if self._inactive_seconds >= self._clear_delay_seconds then
      self:_reset_progress()
    end
  else
    self._inactive_seconds = 0
  end
  if 0 < gain then
    self._fill = math.min(1.0, self._fill + gain)
    if not_null(self._progress) then
      self._progress.fillAmount = self._fill
    end
    if self._fill >= 1.0 then
      self:_complete()
    end
  end
  self:_set_blow_visual_active(has_active_input)
end

function M:_bind_ui()
  if not_null(self._btn_blow) and self.binder then
    self._btn_blow_transition = UIUtil.find_cmpt(self._btn_blow, nil, typeof(UITransitionGroup))
    self.binder:BindViewCallback(self._btn_blow.transform, EventTriggerType.PointerDown, pack(self, M._on_blow_press_down))
    self.binder:BindViewCallback(self._btn_blow.transform, EventTriggerType.PointerUp, pack(self, M._on_blow_press_up))
    self.binder:BindViewCallback(self._btn_blow.transform, EventTriggerType.PointerExit, pack(self, M._on_blow_press_up))
  end
end

function M:_on_blow_press_down()
  self._is_holding = true
end

function M:_on_blow_press_up()
  self._is_holding = false
end

function M:_is_holding_input()
  return self._is_holding
end

function M:_set_blow_visual_active(is_active)
  local transition = self._btn_blow_transition
  if is_null(transition) then
    if not_null(self._btn_blow) then
      self._btn_blow:SetState(is_active and 2 or 0)
    end
    self._is_blow_visual_active = is_active
    return
  end
  if is_active then
    transition:DoStateTransition(2)
  elseif self._is_blow_visual_active then
    transition:ResetState()
  end
  self._is_blow_visual_active = is_active
end

function M:_reset_progress()
  self._fill = 0
  self._inactive_seconds = 0
  if not_null(self._progress) then
    self._progress.fillAmount = 0
  end
end

function M:_refresh_tips_text()
  if is_null(self._text_des) then
    return
  end
  local text
  if not_null(self._tip_text_map) and self._tip_text_map.ToStringExplicit then
    text = self._tip_text_map:ToStringExplicit()
  end
  if not string.is_valid(text) then
    local text_id = InputManagerIns:is_key_mouse() and "PlayerBirthday_ChuiLaZhu_NormalTips" or "PlayerBirthday_ChuiLaZhu_PhoneTips"
    text = UIUtil.get_text_by_id(text_id)
  end
  UIUtil.set_text_with_dynamic_sprite(self._text_des, text)
end

function M:_dispatch_candle_state(state_id)
  if self._candle_state == state_id then
    return
  end
  self._candle_state = state_id
  CsBirthdayModuleUtil.SwitchLocalCandleStateByGuids(self._candle_guids, state_id)
end

function M:_complete()
  if self._completed then
    return
  end
  self._completed = true
  if not_null(self._progress) then
    self._progress.fillAmount = 1.0
  end
  self:_dispatch_candle_state(CANDLE_STATE.close)
  self:close_self()
end

return M
