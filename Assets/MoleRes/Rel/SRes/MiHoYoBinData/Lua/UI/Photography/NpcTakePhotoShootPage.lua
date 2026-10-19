local M = G.Class("NpcTakePhotoShootPage", G.UIWindow)
local base = G.UIWindow
local expression_panel_cls = "UI/Photography/PhotographyExpressionPanel"
local expression_mode_third_person = 1
local ExpressionBtnState = {UnSelect = 0, Select = 1}
local CdState = {Hide = 0, Show = 1}
local HideUIState = {Hide = 0, Show = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Photography/CameraPage"
  self.config.type = EUIType.Page
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = true,
      camera = false,
      ability = false
    },
    ui_cfg = {
      player_ctrl = false,
      ability = false,
      tip = false
    }
  }
  self._photography_mode = expression_mode_third_person
  self._countdown_total = 0
  self._selected_expression_id = 0
end

function M:on_create()
  base.on_create(self)
  self._expression_panel = self:add_panel(expression_panel_cls, self._expression_panel_obj)
  self._expression_panel:set_active(false)
  self:bind_callback(self._expression_btn, pack(self, M._on_press_expression))
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LlmaiTakePhotoCountdownChanged, pack(self, M._refresh_countdown))
  self:add_evt_listener(EventID.LlmaiTakePhotoShootEnd, pack(self, M._on_shoot_end))
end

function M:on_open()
  base.on_open(self)
  self._selected_expression_id = 0
  self._expression_panel:clear_select()
  self._expression_panel:set_active(false)
end

function M:on_enable()
  base.on_enable(self)
  UniversalRenderPipeline.EnableExcludeInCameraCapture()
  local extra_data = self:get_extra_data() or {}
  self._countdown_total = extra_data.countdown_total or 0
  local countdown_remain = extra_data.countdown_remain or self._countdown_total
  self._ui_state_group_hide:SetState(HideUIState.Show)
  self:_hide_free_camera_controls()
  UIUtil.set_active(self._touch_input, InputManagerIns:get_control_mode() == ActionType.ControlModeType.TouchScreen)
  self:_apply_expression_btn()
  self:_refresh_countdown(countdown_remain)
  self._state_group_cd:SetState(CdState.Show)
  CsPhotographyManagerUtil.MouseForceShow = true
end

function M:on_disable()
  base.on_disable(self)
  UniversalRenderPipeline.DisableExcludeInCameraCapture()
  self._state_group_cd:SetState(CdState.Hide)
  self._bg_alpha.alpha = 0
  self._content_alpha.alpha = 0
  CsPhotographyManagerUtil.MouseForceShow = false
end

function M:_hide_free_camera_controls()
  UIUtil.set_active(self._btn_shutter, false)
  UIUtil.set_active(self._btn_close, false)
  UIUtil.set_active(self._lens_position_joy_stick, false)
  UIUtil.set_active(self._lens_toggle, false)
  UIUtil.set_active(self._camera_stand_switch, false)
  UIUtil.set_active(self._trans_btn_mode, false)
  UIUtil.set_active(self._btn_reset, false)
  UIUtil.set_active(self._trans_wheel_scale, false)
  UIUtil.set_active(self._wheel_obj, false)
  UIUtil.set_active(self._btn_album, false)
  UIUtil.set_active(self._btn_setting, false)
  UIUtil.set_active(self._btn_invite_npc, false)
  UIUtil.set_active(self._btn_npc_reaction, false)
  UIUtil.set_active(self._trans_grid_lines, false)
  UIUtil.set_active(self._toggle_hide_ui, false)
  UIUtil.set_active(self._obj_key_tips, false)
  UIUtil.set_active(self._obj_camera_npc_interact_panel, false)
  UIUtil.set_active(self._obj_photo_previrw_panel, false)
  UIUtil.set_active(self._obj_role_position, false)
  UIUtil.set_active(self._obj_btn_npc_come_light, false)
  UIUtil.set_active(self._shutter_eff, false)
end

function M:_refresh_countdown(remain_seconds)
  local remain = tonumber(remain_seconds) or 0
  UIUtil.set_text(self._txt_cd_dynamic, tostring(remain))
  if 0 < self._countdown_total then
    self._slider_cd.value = remain / self._countdown_total
  end
end

function M:_on_shoot_end()
  self:close_self()
end

function M:_on_press_expression()
  if GameplayUtilities_Avatar.UIValidateState(StateTags.Tags.state_system_reaction) == false then
    return
  end
  self._expression_panel:set_active(true)
end

function M:expression_selected(id)
  if not id then
    return
  end
  self._selected_expression_id = id
  self:_apply_expression_btn()
end

function M:_apply_expression_btn()
  if self._selected_expression_id == 0 then
    self._expression_btn_state:SetState(ExpressionBtnState.UnSelect)
    return
  end
  self._expression_btn_state:SetState(ExpressionBtnState.Select)
  local cfg = ExcelDataUtil.get_value(typeof(BReactionCfg), self._selected_expression_id)
  if cfg then
    UIUtil.set_image(self._expression_icon, cfg.iconpath, self:get_load_proxy())
  end
end

return M
