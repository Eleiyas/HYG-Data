local M = G.Class("StarEtiquetteSignUpPage", G.UIWindow)
local base = G.UIWindow
local TIME_REFRESH_INTERVAL_SEC = 1
local PLANET_ROTATE_SPEED = 0.2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteSignUpPage"
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_405_HaoYouZhanShi"
  self.config.type = EUIType.Page
  self._is_close = false
  self._activity_id = 0
  self._time_acc = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_update_activity_id()
  self:_create_preview_planet()
  self._is_close = false
  self._time_acc = 0
  local secret_santa_id = tonumber(CsSecretSantaModuleUtil.GetSecretSantaId()) or 0
  if secret_santa_id ~= 0 then
    if not red_point_module:is_recorded_with_id(red_point_module.red_point_type.secret_santa_planet_interacted, secret_santa_id) then
      red_point_module:record_with_id(red_point_module.red_point_type.secret_santa_planet_interacted, secret_santa_id)
    end
    CsSecretSantaModuleUtil.RequestPlanetInteracted()
  end
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
  star_etiquette_module:exit_sign_up_camera()
  star_etiquette_module:destroy_sign_up_preview_planet()
end

function M:_create_preview_planet()
  local ctrl_comp = UIUtil.find_cmpt(self.ui_scene_obj, nil, typeof(CS.GameModules.CompanionStar.CompanionStarCtrl))
  if is_null(ctrl_comp) then
    return
  end
  star_etiquette_module:enter_sign_up_camera(ctrl_comp)
  star_etiquette_module:create_sign_up_preview_planet(ctrl_comp.starRiverRoot)
end

function M:update(delta_time)
  base.update(self, delta_time)
  self._time_acc = self._time_acc + delta_time
  if self._time_acc >= TIME_REFRESH_INTERVAL_SEC then
    self._time_acc = self._time_acc - TIME_REFRESH_INTERVAL_SEC
    self:_refresh_time_remain()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityDataChanged, pack(self, M._on_activity_data_changed))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
  self:add_evt_listener(EventID.OnSecretSantaUpdate, pack(self, M._on_secret_santa_update))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help_click))
  self:bind_callback(self._btn_sign_up, pack(self, M._on_btn_sign_up_click))
  self._scroll_drag:SetDragCallback(pack(self, M._on_drag), nil, nil)
end

function M:_on_drag(delta)
  star_etiquette_module:rotate_sign_up_preview_planet(-(delta * PLANET_ROTATE_SPEED))
end

function M:_update_activity_id()
  self._activity_id = tonumber(CsSecretSantaModuleUtil.GetActivityId()) or 0
end

function M:_refresh_ui()
  local phase = CsSecretSantaModuleUtil.GetPhase()
  self._claim_tracking_action = nil
  if phase == ESecretSantaPhase.SecretSantaPhaseSubmit then
    local can_submit_gift = CsSecretSantaModuleUtil.CanSubmitGift()
    self._state_group:SetState(can_submit_gift and 0 or 1)
    if can_submit_gift then
      UIUtil.set_text_by_id(self._txt_sign_up, "SantaStar_Page_06")
    else
      UIUtil.set_text_by_id(self._txt_over, "SantaStar_Page_07")
    end
  elseif phase == ESecretSantaPhase.SecretSantaPhaseClaim then
    local is_over = star_etiquette_module:is_stocking_task_complete() and not CsSecretSantaModuleUtil.HasAnyClaimableGift()
    self._state_group:SetState(is_over and 1 or 0)
    if is_over then
      UIUtil.set_text_by_id(self._txt_over, "SantaMainPage_08")
    else
      self._claim_tracking_action = star_etiquette_module:get_activity_center_tracking_action()
      local can_track_stocking = self._claim_tracking_action.target ~= nil and self._claim_tracking_action.target.kind == activity_center_module.tracking_kind.feature
      UIUtil.set_active(self._btn_sign_up, can_track_stocking)
      UIUtil.set_text_by_id(self._txt_sign_up, "SantaStar_Page_08")
    end
  end
  self:_refresh_time_remain()
end

function M:_refresh_time_remain()
  if is_null(self._trans_time_remain) or is_null(self._text_time_remain) then
    return
  end
  local remain_seconds = math.max(0, CsSecretSantaModuleUtil.GetPhaseEndTime() - TimeUtil.ServerUtcTimeSeconds)
  local time_text = UIUtil.format_left_time(remain_seconds)
  local phase = CsSecretSantaModuleUtil.GetPhase()
  if phase == ESecretSantaPhase.SecretSantaPhaseSubmit then
    UIUtil.set_text_by_id(self._text_time_remain, "SantaStar_Page_03", time_text)
  else
    UIUtil.set_text_by_id(self._text_time_remain, "SecretSanta_StarLeave", time_text)
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

function M:_on_btn_help_click()
  common_ui_module:show_introduction_dialog(45)
end

function M:_on_btn_sign_up_click()
  if self._activity_id <= 0 then
    return
  end
  local phase = CsSecretSantaModuleUtil.GetPhase()
  if phase == ESecretSantaPhase.SecretSantaPhaseSubmit and CsSecretSantaModuleUtil.CanSubmitGift() then
    UIManagerInstance:open("UI/MainActivity_y1/StarEtiquette/StarEtiquetteGiftDialog", {mode = "give"})
  elseif phase == ESecretSantaPhase.SecretSantaPhaseClaim then
    star_etiquette_module:execute_activity_center_tracking_action(self._claim_tracking_action)
  end
end

function M:_on_activity_data_changed(activity_id)
  if activity_id == self._activity_id then
    self:_refresh_ui()
  end
end

function M:_on_secret_santa_update()
  self:_refresh_ui()
end

function M:_on_activity_removed(activity_id)
  if activity_id == self._activity_id and self:is_in_show_state() then
    star_etiquette_module:show_activity_end_dialog(self._activity_id, pack(self, M._on_activity_end_confirmed))
  end
end

function M:_on_activity_end_confirmed()
  star_etiquette_module:finish_activity_end(self)
end

return M
