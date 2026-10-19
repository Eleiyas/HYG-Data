star_etiquette_module = star_etiquette_module or {}
local SIGN_UP_CAMERA_STATE = "FriendStarSanta"
local TRACKING_ID_INTRO = 22
local TRACKING_ID_EXCHANGE_GUIDE = 23
local TRACKING_ID_EXCHANGE_CLAIM = 24
local TRACKING_ID_GIFT_PLANET = 25
local TRACKING_ID_STOCKING = 26
local TRACKING_ID_NO_STOCKING = 27
local GIFT_PLANET_TASK_ID = 4001006
local STOCKING_TASK_ID = 4001008
local TRACKING_NAVIGATION_RESOLVER_KEY = "star_etiquette"
local CLICKABLE_TRACKING_IDS = {TRACKING_ID_GIFT_PLANET, TRACKING_ID_STOCKING}

function star_etiquette_module:register_tracking_navigation()
  activity_center_module:register_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY, function(source_activity_id)
    return self:resolve_tracking_navigation(source_activity_id)
  end)
end

function star_etiquette_module:unregister_tracking_navigation()
  activity_center_module:unregister_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY)
end

function star_etiquette_module:resolve_tracking_navigation(source_activity_id)
  local is_secret_santa_tracking = false
  for _, tracking_id in ipairs(CLICKABLE_TRACKING_IDS) do
    if activity_center_module:get_tracking_activity_id(tracking_id) == source_activity_id then
      is_secret_santa_tracking = true
      break
    end
  end
  if not is_secret_santa_tracking then
    return nil
  end
  local host_activity_id = tonumber(CsSecretSantaModuleUtil.GetActivityId()) or 0
  if host_activity_id <= 0 then
    return nil
  end
  return {host_activity_id = host_activity_id}
end

function star_etiquette_module:get_activity_end_gate_key(activity_id)
  return activity_center_module:make_activity_end_gate_key(activity_id)
end

function star_etiquette_module:show_activity_end_dialog(activity_id, on_confirm)
  activity_center_module:show_activity_end_dialog(on_confirm, {
    key = self:get_activity_end_gate_key(activity_id)
  })
end

function star_etiquette_module:finish_activity_end(fallback_window)
  local sign_up_page = UIManagerInstance:get_window_by_class("UI/MainActivity_y1/StarEtiquette/StarEtiquetteSignUpPage")
  if sign_up_page ~= nil then
    UIManagerInstance:close_page_with_dialogs_above(sign_up_page)
  elseif fallback_window ~= nil then
    fallback_window:close_self()
  end
end

star_etiquette_module.activity_center_action_state = {
  hidden = 0,
  submit = 1,
  submitted_waiting = 2,
  claim = 3,
  finished = 4
}
star_etiquette_module.tracking_text_id = {
  [activity_center_module.tracking_state.can_track] = "SpringFestival_TrackTask",
  [activity_center_module.tracking_state.tracking] = "SpringFestival_TrackTaskCancel"
}

function star_etiquette_module:is_tracking_task_group_complete(tracking_id)
  local task_ids = activity_center_module:get_tracking_memo_ids(tracking_id)
  if task_ids == nil or #task_ids == 0 then
    return false
  end
  for index = 1, #task_ids do
    if not task_module:task_is_finish(task_ids[index]) then
      return false
    end
  end
  return true
end

function star_etiquette_module:is_main_intro_task_complete()
  return self:is_tracking_task_group_complete(TRACKING_ID_INTRO)
end

function star_etiquette_module:is_planet_task_complete()
  return task_module:task_is_finish(GIFT_PLANET_TASK_ID)
end

function star_etiquette_module:is_stocking_task_complete()
  return task_module:task_is_finish(STOCKING_TASK_ID)
end

local function make_action(state, tracking_id)
  local target = activity_center_module:make_tracking_target_by_id(tracking_id)
  if target == nil then
    return {
      state = star_etiquette_module.activity_center_action_state.hidden,
      text = ""
    }
  end
  local text_id
  local text = activity_center_module:get_tracking_button_text(target)
  local tracking_state = activity_center_module.tracking_state.can_track
  if activity_center_module:is_tracking(target) then
    tracking_state = activity_center_module.tracking_state.tracking
    text = nil
    text_id = star_etiquette_module.tracking_text_id[tracking_state]
  elseif target.kind == activity_center_module.tracking_kind.task then
    text_id = star_etiquette_module.tracking_text_id[tracking_state]
  end
  return {
    state = state,
    text_id = text_id,
    text = text,
    target = target
  }
end

function star_etiquette_module:get_activity_center_tracking_action()
  local action_state = self.activity_center_action_state
  local phase = CsSecretSantaModuleUtil.GetPhase()
  if not self:is_main_intro_task_complete() then
    return make_action(action_state.submit, TRACKING_ID_INTRO)
  end
  if phase == ESecretSantaPhase.SecretSantaPhaseNone then
    return {
      state = action_state.hidden,
      text_id = "SantaMainPage_CantExchange_01"
    }
  elseif phase == ESecretSantaPhase.SecretSantaPhaseSubmit then
    if not self:is_tracking_task_group_complete(TRACKING_ID_EXCHANGE_GUIDE) then
      return make_action(action_state.submit, TRACKING_ID_EXCHANGE_GUIDE)
    end
    if CsSecretSantaModuleUtil.CanSubmitGift() then
      return make_action(action_state.submit, TRACKING_ID_GIFT_PLANET)
    else
      local remain_seconds = math.max(0, CsSecretSantaModuleUtil.GetPhaseEndTime() - TimeUtil.ServerUtcTimeSeconds)
      local time_text = UIUtil.format_left_time(remain_seconds)
      return {
        state = action_state.submitted_waiting,
        text = UIUtil.get_text_by_id("SantaMainPage_06", time_text)
      }
    end
  elseif phase == ESecretSantaPhase.SecretSantaPhaseClaim then
    if not self:is_stocking_task_complete() then
      if not self:is_tracking_task_group_complete(TRACKING_ID_NO_STOCKING) then
        return make_action(action_state.claim, TRACKING_ID_NO_STOCKING)
      end
      return {
        state = action_state.finished,
        text_id = "SpringFestival_CantExchange_03"
      }
    else
      if not self:is_tracking_task_group_complete(TRACKING_ID_EXCHANGE_CLAIM) then
        return make_action(action_state.claim, TRACKING_ID_EXCHANGE_CLAIM)
      end
      if CsSecretSantaModuleUtil.HasAnyClaimableGift() then
        return make_action(action_state.claim, TRACKING_ID_STOCKING)
      else
        return {
          state = action_state.finished,
          text_id = "SantaMainPage_08"
        }
      end
    end
  end
  return {
    state = action_state.hidden,
    text = ""
  }
end

function star_etiquette_module:get_activity_center_reward_red_point_type()
  local activity_id = CsSecretSantaModuleUtil.GetActivityId()
  local activity_data = CsActivityCenterModuleUtil.GetActivityById(activity_id)
  if is_null(activity_data) then
    return RedPointType.None
  end
  return activity_data:GetRewardRedDotType()
end

function star_etiquette_module:execute_activity_center_tracking_action(action)
  if action == nil or action.target == nil then
    return
  end
  activity_center_module:toggle_tracking(action.target)
end

function star_etiquette_module:enter_sign_up_camera(ctrl_comp)
  self:exit_sign_up_camera()
  if is_null(ctrl_comp) or is_null(ctrl_comp.cameraTarget) or is_null(ctrl_comp.cameraLook) then
    return false
  end
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform(SIGN_UP_CAMERA_STATE, ctrl_comp.cameraTarget, ctrl_comp.cameraLook)
  self._is_sign_up_camera_active = true
  return true
end

function star_etiquette_module:exit_sign_up_camera()
  if not self._is_sign_up_camera_active then
    return
  end
  self._is_sign_up_camera_active = false
  CsGameplayUtilitiesCameraUtil.PopState(SIGN_UP_CAMERA_STATE)
end

function star_etiquette_module:create_sign_up_preview_planet(anchor)
  self:destroy_sign_up_preview_planet()
  if is_null(anchor) then
    return false
  end
  local secret_santa_id = CsSecretSantaModuleUtil.GetSecretSantaId()
  local cfg = ExcelDataUtil.get_value(typeof(BSecretSantaActivityCfg), secret_santa_id)
  local star_count = cfg ~= nil and tonumber(cfg.santastaridLength) or 0
  local state = tonumber(CsSecretSantaModuleUtil.GetSantaStarState()) or 0
  local config_index = star_count - 3 + state
  if config_index < 0 or star_count <= config_index then
    return false
  end
  local planet_config_id = tonumber(cfg:santastarid(config_index)) or 0
  if planet_config_id <= 0 then
    return false
  end
  local entity = CsGameplayUtilitiesGameplayObjectUtil.CreatePreviewSimplePlanet(planet_config_id, anchor.position, anchor.rotation, anchor.lossyScale)
  if is_null(entity) or not entity.IsValid then
    return false
  end
  self._sign_up_preview_planet = entity
  return true
end

function star_etiquette_module:destroy_sign_up_preview_planet()
  local entity = self._sign_up_preview_planet
  self._sign_up_preview_planet = nil
  if is_null(entity) or not entity.IsValid then
    return
  end
  CsGameplayUtilitiesGameplayObjectUtil.DestroyPreviewSimplePlanet(entity)
end

function star_etiquette_module:rotate_sign_up_preview_planet(delta_y)
  local entity = self._sign_up_preview_planet
  if is_null(entity) or not entity.IsValid then
    return
  end
  local is_get, x, y, z, w = EntityUtil.try_get_entity_rotation_by_guid(entity.Guid)
  if not is_get then
    return
  end
  local current_rotation = Quaternion(x, y, z, w)
  local delta_rotation = Quaternion.Euler(0, delta_y, 0)
  local new_rotation = current_rotation * delta_rotation
  EntityUtil.set_entity_rotation_by_guid(entity.Guid, new_rotation.x, new_rotation.y, new_rotation.z, new_rotation.w)
end

function star_etiquette_module:open_sign_up_page()
  if self._is_opening_sign_up_page or UIManagerInstance:is_show("UI/MainActivity_y1/StarEtiquette/StarEtiquetteSignUpPage") then
    return
  end
  self._is_opening_sign_up_page = true
  UIManagerInstance:open("UI/MainActivity_y1/StarEtiquette/StarEtiquetteSignUpPage")
  self._is_opening_sign_up_page = false
end

function star_etiquette_module:open_gift_card_dialog(slot)
  if slot == nil or slot == ESecretSantaGiftSlot.SecretSantaGiftSlotNone then
    return
  end
  local dialog_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteGiftDialog"
  if slot == ESecretSantaGiftSlot.SecretSantaGiftSlotNpc then
    dialog_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteNpcGiftDialog"
  end
  if UIManagerInstance:is_show(dialog_path) then
    return
  end
  local activity_id = tonumber(CsSecretSantaModuleUtil.GetActivityId()) or 0
  if activity_id <= 0 or not activity_center_module:has_activity(activity_id) then
    self:show_activity_end_dialog(activity_id, function()
      self:finish_activity_end()
    end)
    return
  end
  UIManagerInstance:open(dialog_path, {mode = "receive", slot = slot})
end

return star_etiquette_module
