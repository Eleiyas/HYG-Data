local M = G.Class("GalacticbazaarSupportPage", G.UIWindow)
local base = G.UIWindow
local BEAT_STATE_DEFAULT = 0
local BEAT_STATE_PRESSED = 2
local BEAT_STATE_MISS = 3
local BEAT_HINT_REVERT_SEC = 0.35
local CHEER_POSE_INDEX = 1
local CONTINUE_TIP_PATH = "UI/GalacticBazaar/GalacticbazaarContinueSupportTip"
local CHEER_SCREEN_VFX_01 = "Effects/Player/SocialInreract/Eff_SocialInteract_CheerScreen_01"
local CHEER_SCREEN_VFX_02 = "Effects/Player/SocialInreract/Eff_SocialInteract_CheerScreen_02"
local CHEER_SCREEN_VFX_SCALE = 1
local CHEER_SCREEN_VFX_OPTS = {
  scale = CHEER_SCREEN_VFX_SCALE,
  target_z = 2,
  auto_center_y = true
}
local CHEER_SCREEN_VFX_02_OPTS = {
  scale = CHEER_SCREEN_VFX_SCALE,
  target_z = 2,
  auto_center_y = true,
  auto_play = false
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticbazaarSupportPage"
  self.config.type = EUIType.Page
  self._cheer_context = nil
  self._cheer_score = 0
  self._beat_hint_timer = nil
  self._beat_window_timer = 0
  self._combo_count = 0
  self._go_cheer_screen_01 = nil
  self._go_cheer_screen_02 = nil
  self._cheer_gameplay_camera_pushed = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_init_cheering_ui()
end

function M:on_open()
  base.on_open(self)
  UIUtil.set_active(self._trans_switch_items, false)
  self:_apply_open_args(self:get_extra_data())
end

function M:on_enable()
  base.on_enable(self)
  self._combo_count = 0
  self:_apply_open_args(self:get_extra_data())
  self:_refresh_cheer_score_display()
  self._cur_color = 1
  CsGameplayUtilitiesSceneActivityUtil.TryChangeCheerStickColor(self._cur_color)
  if not self._cheer_gameplay_camera_pushed then
    CsGameplayUtilitiesCameraUtil.PushState("CheerGameplay")
    self._cheer_gameplay_camera_pushed = true
  end
  self:_show_cheer_screen_vfx_01()
  self:_prewarm_cheer_screen_vfx_02()
end

function M:on_before_close()
  base.on_before_close(self)
  self:_release_cheer_gameplay_resources()
end

function M:on_disable()
  base.on_disable(self)
  self:_clear_beat_hint_timer()
  self:_release_cheer_gameplay_resources()
end

function M:on_close()
  base.on_close(self)
  self:_clear_cheer_screen_vfx()
  self._cheer_context = nil
end

function M:on_destroy()
  base.on_destroy(self)
  self:_clear_beat_hint_timer()
  self:_clear_cheer_screen_vfx()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.SceneActivity.OnCheerScoreChanged, function(cheer_score)
    self:_on_cheer_score_changed(cheer_score)
  end)
  self:add_evt_listener(EventID.SceneActivity.OnCheerBeatHint, function(lead_time)
    self:_on_cheer_beat_hint(lead_time)
  end)
  self:add_evt_listener(EventID.SceneActivity.OnCheerStickColorChanged, function(color_id)
    self:_on_cheer_stick_color_changed(color_id)
  end)
  self:add_evt_listener(EventID.SceneActivity.CheerClickResultNtf, function(res)
    self:_on_cheer_click_result(res)
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_close then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
  self:bind_input_and_fun(ActionType.Act.MouseLeft, pack(self, M._on_mouse_left_click), ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.Tab, pack(self, M._on_tab_toggle), ActionType.EType.ButtonPressed)
end

function M:on_cheer_open_event(args)
  if not self:_is_valid_cheer_context(args) then
    self:close_self()
    return
  end
  self:_apply_open_args(args)
end

function M:_is_valid_cheer_context(args)
  return args ~= nil and not is_null(args) and args.reactionAction ~= nil
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_switch, pack(self, M._on_btn_switch_click))
  self:bind_callback(self._btn_close_switch, pack(self, M._on_btn_close_switch_click))
  self:bind_callback(self._btn_support, pack(self, M._on_btn_support_click))
  self:bind_callback(self._tog_color_1, function(is_on)
    if is_on then
      CsGameplayUtilitiesSceneActivityUtil.TryChangeCheerStickColor(1)
    end
  end)
  self:bind_callback(self._tog_color_2, function(is_on)
    if is_on then
      CsGameplayUtilitiesSceneActivityUtil.TryChangeCheerStickColor(2)
    end
  end)
  self:bind_callback(self._tog_color_3, function(is_on)
    if is_on then
      CsGameplayUtilitiesSceneActivityUtil.TryChangeCheerStickColor(3)
    end
  end)
end

function M:_init_cheering_ui()
  UIUtil.set_active(self._btn_close, true)
  UIUtil.set_active(self._btn_switch, true)
  UIUtil.set_active(self._trans_switch_items, false)
  if not is_null(self._support_state) then
    self._support_state:SetState(BEAT_STATE_DEFAULT)
    self._anim_helper:SetTriggerWithCallback("none")
  end
end

function M:_apply_open_args(args)
  if not self:_is_valid_cheer_context(args) then
    return
  end
  self._cheer_context = args
  self:_init_cheering_ui()
end

function M:_on_mouse_left_click(_, action)
  if not self:_is_switch_panel_active() and not self:_is_pointer_over_ui_btn() then
    self:_on_btn_support_click()
  end
  action.handled = false
end

function M:_on_tab_toggle()
  if self:_is_switch_panel_active() then
    UIUtil.set_active(self._trans_switch_items, false)
  else
    self:_on_btn_switch_click()
  end
end

function M:_on_btn_support_click()
  self:_on_cheer_button_click(CHEER_POSE_INDEX)
end

function M:_on_cheer_click_result(res)
  if res == EnumBeatGrade.Good then
    self._combo_count = self._combo_count + 1
    if not is_null(self._support_state) then
      self._support_state:SetState(BEAT_STATE_PRESSED)
      self:_schedule_beat_state_revert(BEAT_HINT_REVERT_SEC, BEAT_STATE_DEFAULT)
    end
    self:_show_combo_tip(self._combo_count)
    self:_show_cheer_screen_vfx_02()
  elseif res == EnumBeatGrade.Wrong then
    self._combo_count = 0
    if not is_null(self._support_state) then
      self._support_state:SetState(BEAT_STATE_MISS)
      self:_schedule_beat_state_revert(BEAT_HINT_REVERT_SEC, BEAT_STATE_DEFAULT)
    end
  end
end

function M:_show_combo_tip(count)
  local tip = UIManagerInstance:is_show(CONTINUE_TIP_PATH)
  if tip then
    tip:refresh_count(count)
  else
    UIManagerInstance:open(CONTINUE_TIP_PATH, count)
  end
end

function M:_on_btn_close_click()
  self:_try_exit_cheer()
end

function M:_on_btn_switch_click()
  UIUtil.set_active(self._trans_switch_items, true)
  if self._cur_color == 1 then
    self._tog_color_1.isOn = true
  elseif self._cur_color == 2 then
    self._tog_color_2.isOn = true
  elseif self._cur_color == 3 then
    self._tog_color_3.isOn = true
  end
end

function M:_on_btn_close_switch_click()
  if not self:_is_switch_panel_active() then
    return
  end
  UIUtil.set_active(self._trans_switch_items, false)
end

function M:_is_switch_panel_active()
  return not is_null(self._trans_switch_items) and self._trans_switch_items.gameObject.activeInHierarchy
end

function M:_is_pointer_over_ui_btn()
  local mp = CS.UnityEngine.Input.mousePosition
  local screen_pos = CS.UnityEngine.Vector2(mp.x, mp.y)
  if self:_rect_contains(self._btn_close, screen_pos) then
    return true
  end
  if self:_rect_contains(self._btn_switch, screen_pos) then
    return true
  end
  if self:_rect_contains(self._btn_support, screen_pos) then
    return true
  end
  return false
end

function M:_rect_contains(btn, screen_pos)
  if is_null(btn) or not btn.gameObject.activeInHierarchy then
    return false
  end
  local rt = btn.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
  if is_null(rt) then
    return false
  end
  return CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(rt, screen_pos, UIManagerInstance.ui_camera)
end

function M:_on_cheer_button_click(pose_index)
  local context = self._cheer_context
  if not context or not context.reactionAction then
    return
  end
  context.reactionAction(pose_index or CHEER_POSE_INDEX)
end

function M:_on_cheer_score_changed(cheer_score)
  self._cheer_score = tonumber(cheer_score) or 0
  self:_refresh_cheer_score_display()
end

function M:_on_cheer_beat_hint(lead_time)
  local duration = lead_time or BEAT_HINT_REVERT_SEC
  self._beat_window_timer = duration
  if not is_null(self._anim_helper) then
    self._anim_helper:SetAnimatorSpeed(1 / duration)
    self._anim_helper:SetTriggerWithCallback("shrink")
  end
end

function M:_on_cheer_stick_color_changed(color_id)
end

function M:_refresh_cheer_score_display()
end

function M:_schedule_beat_state_revert(delay_sec, target_state)
  self:_clear_beat_hint_timer()
  self._beat_hint_timer = delay_sec
  self._beat_hint_revert_state = target_state or BEAT_STATE_DEFAULT
end

function M:_clear_beat_hint_timer()
  self._beat_hint_timer = nil
  self._beat_hint_revert_state = nil
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._beat_window_timer > 0 then
    self._beat_window_timer = self._beat_window_timer - deltaTime
    if self._beat_window_timer < 0 then
      self._beat_window_timer = 0
    end
  end
  if not self._beat_hint_timer then
    return
  end
  self._beat_hint_timer = self._beat_hint_timer - deltaTime
  if 0 >= self._beat_hint_timer then
    local revert_state = self._beat_hint_revert_state or BEAT_STATE_DEFAULT
    self:_clear_beat_hint_timer()
    if not is_null(self._support_state) then
      self._support_state:SetState(revert_state)
      self._anim_helper:SetTriggerWithCallback("none")
    end
  end
end

function M:_try_exit_cheer()
  self:close_self()
  CsGameplayUtilitiesSceneActivityUtil.TryInitiativeCheerExit()
end

function M:_show_cheer_screen_vfx_01()
  if not is_null(self._go_cheer_screen_01) then
    return
  end
  UIUtil.recycle_main_camera_vfx(self._go_cheer_screen_01)
  self._go_cheer_screen_01 = UIUtil.spawn_main_camera_vfx(CHEER_SCREEN_VFX_01, CHEER_SCREEN_VFX_OPTS)
end

function M:_prewarm_cheer_screen_vfx_02()
  if not is_null(self._go_cheer_screen_02) then
    return
  end
  UIUtil.recycle_main_camera_vfx(self._go_cheer_screen_02)
  self._go_cheer_screen_02 = UIUtil.spawn_main_camera_vfx(CHEER_SCREEN_VFX_02, CHEER_SCREEN_VFX_02_OPTS)
end

function M:_show_cheer_screen_vfx_02()
  if UIUtil.replay_main_camera_vfx(self._go_cheer_screen_02) then
    return
  end
  UIUtil.recycle_main_camera_vfx(self._go_cheer_screen_02)
  self._go_cheer_screen_02 = UIUtil.spawn_main_camera_vfx(CHEER_SCREEN_VFX_02, CHEER_SCREEN_VFX_OPTS)
end

function M:_clear_cheer_screen_vfx()
  UIUtil.recycle_main_camera_vfx(self._go_cheer_screen_01)
  self._go_cheer_screen_01 = nil
  UIUtil.recycle_main_camera_vfx(self._go_cheer_screen_02)
  self._go_cheer_screen_02 = nil
end

function M:_release_cheer_gameplay_resources()
  self:_clear_cheer_screen_vfx()
  if self._cheer_gameplay_camera_pushed then
    CsGameplayUtilitiesCameraUtil.PopState("CheerGameplay")
    self._cheer_gameplay_camera_pushed = false
  end
end

return M
