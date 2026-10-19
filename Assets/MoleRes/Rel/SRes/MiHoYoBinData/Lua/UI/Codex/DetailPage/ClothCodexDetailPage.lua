local base_class = require("UI/Codex/DetailPage/ItemDetailPageV2")
local M = G.Class("ClothCodexDetailPage", base_class)
local base = base_class
local CAM_STATE = "CodexAppearance1"
local MAX_TEMP_PLAYER_RETRY = 180
local TARGET_SCREEN_RATIO = 0.3

function M:init()
  base.init(self)
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_CodexInfo"
  self._follow_target = nil
  self._look_target = nil
  self._player_root = nil
  self._temp_player_created = false
  self._temp_player_retry_coroutine = nil
  self._temp_player_retry_count = 0
  self._camera_retry_coroutine = nil
  self._screen_pos_coroutine = nil
  self._defer_first_temp_player_create = false
  self._follow_base_pos = nil
  self._look_base_pos = nil
  self._gm_mode = false
  self._gm_item_id = nil
end

function M:_init_data(extra_data)
  local ok = base._init_data(self, extra_data)
  if ok then
    self._gm_mode = false
    return true
  end
  if extra_data and extra_data.item_id then
    self._gm_mode = true
    self._gm_item_id = extra_data.item_id
    self._is_unlocked = true
    self.item_data = {
      IdCfg = {
        id = extra_data.item_id,
        name = "GM_" .. tostring(extra_data.item_id)
      },
      ItemCfg = {},
      SubType = 0,
      Type = 0,
      IsUnlocked = true
    }
    self.group_index = 1
    self.sequence = 1
    return true
  end
  return false
end

function M:on_enable()
  self._defer_first_temp_player_create = true
  self:_setup_scene_refs()
  base.on_enable(self)
  self:_setup_scene_refs()
end

function M:on_disable()
  self._defer_first_temp_player_create = false
  self:_clear_screen_pos_fix()
  self:_clear_camera_retry()
  self:_clear_temp_player_retry()
  self:_destroy_temp_player()
  self:_pop_camera()
  self:_restore_base_positions()
  self._follow_base_pos = nil
  self._look_base_pos = nil
  self._cached_dx = nil
  ModelPreviewManagerIns:hide()
  base.on_disable(self)
end

function M:on_destroy()
  self._defer_first_temp_player_create = false
  self:_clear_screen_pos_fix()
  self:_clear_camera_retry()
  self:_clear_temp_player_retry()
  self:_destroy_temp_player()
  self:_restore_base_positions()
  self._follow_base_pos = nil
  self._look_base_pos = nil
  self._cached_dx = nil
  ModelPreviewManagerIns:hide()
  base.on_destroy(self)
end

function M:_setup_scene_refs()
  if is_null(self.ui_scene_obj) then
    return
  end
  self._follow_target = UIUtil.find_trans(self.ui_scene_obj, "Art/FollowTarget")
  self._look_target = UIUtil.find_trans(self.ui_scene_obj, "Art/LookTarget")
  self._player_root = UIUtil.find_trans(self.ui_scene_obj, "Art/ModelPos/pos")
end

function M:_push_camera()
  if is_null(self._follow_target) or is_null(self._look_target) then
    self:_setup_scene_refs()
  end
  if not_null(self._follow_target) and not_null(self._look_target) then
    CsGameplayUtilitiesCameraUtil.PopTVShopping()
    CsGameplayUtilitiesCameraUtil.PopState(CAM_STATE)
    if not_null(self._player_root) then
      CsGameplayUtilitiesCameraUtil.SetViewportAnchorProjectionOffsetAnchor(CAM_STATE, self._player_root)
    end
    CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform(CAM_STATE, self._follow_target, self._look_target)
  end
end

function M:_save_base_positions()
  if not self._follow_base_pos then
    self._follow_base_pos = self._follow_target.localPosition
  end
  if not self._look_base_pos then
    self._look_base_pos = self._look_target.localPosition
  end
end

function M:_restore_base_positions()
  if self._follow_base_pos then
    self._follow_target.localPosition = self._follow_base_pos
  end
  if self._look_base_pos then
    self._look_target.localPosition = self._look_base_pos
  end
end

function M:_apply_cached_offset()
  local pos_f = self._follow_target.localPosition
  pos_f.x = pos_f.x + self._cached_dx
  self._follow_target.localPosition = pos_f
  local pos_l = self._look_target.localPosition
  pos_l.x = pos_l.x + self._cached_dx
  self._look_target.localPosition = pos_l
end

function M:_schedule_screen_pos_fix()
  self:_clear_screen_pos_fix()
  self._screen_pos_coroutine = CsCoroutineManagerUtil.InvokeAfterFrames(1, function()
    self._screen_pos_coroutine = nil
    if not self.is_active then
      return
    end
    self:_apply_fixed_screen_position()
  end)
end

function M:_clear_screen_pos_fix()
  if self._screen_pos_coroutine then
    CsCoroutineManagerUtil.StopCoroutine(self._screen_pos_coroutine)
    self._screen_pos_coroutine = nil
  end
end

function M:_apply_fixed_screen_position()
  local cam = CsGameplayUtilitiesCameraUtil.GetMainCamera()
  if is_null(cam) or is_null(self._player_root) or is_null(self._follow_target) or is_null(self._look_target) then
    return
  end
  local model_screen = cam:WorldToScreenPoint(self._player_root.position)
  local target_x = CS.UnityEngine.Screen.width * TARGET_SCREEN_RATIO
  local depth = model_screen.z
  local world_cur = cam:ScreenToWorldPoint(Vector3(model_screen.x, model_screen.y, depth))
  local world_dst = cam:ScreenToWorldPoint(Vector3(target_x, model_screen.y, depth))
  self._cached_dx = world_cur.x - world_dst.x
  self:_restore_base_positions()
  self:_apply_cached_offset()
  CsGameplayUtilitiesCameraUtil.PopState(CAM_STATE)
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform(CAM_STATE, self._follow_target, self._look_target)
end

function M:_pop_camera()
  CsGameplayUtilitiesCameraUtil.ClearViewportAnchorProjectionOffsetAnchor(CAM_STATE)
  CsGameplayUtilitiesCameraUtil.PopState(CAM_STATE)
end

function M:_schedule_camera_retry()
  self:_clear_camera_retry()
  self._camera_retry_coroutine = CsCoroutineManagerUtil.InvokeAfterFrames(1, function()
    self._camera_retry_coroutine = nil
    if not self.is_active then
      return
    end
    self:_push_camera()
  end)
end

function M:_clear_camera_retry()
  if self._camera_retry_coroutine ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._camera_retry_coroutine)
    self._camera_retry_coroutine = nil
  end
end

function M:_refresh_page()
  base._refresh_page(self)
end

function M:_refresh_left_display()
  if self._gm_mode then
    self:_refresh_left_gm_mode()
    return
  end
  local is_package = codex_module:is_package_sub_type(self.item_data.SubType)
  if is_package then
    local all = self.item_data.allCount or 0
    local unlocked = self.item_data.unlockCount or 0
    local is_complete = 0 < all and all <= unlocked
    self._ui_state_group:SetState(is_complete and 0 or 1)
    if not is_complete and not_null(self._txt_locked) then
      local text_key = self._is_unlocked and "Codex_Suite_NotComplete" or "Codex_Suite_NotUnlocked"
      UIUtil.set_text_by_id(self._txt_locked, text_key)
    end
  else
    self._ui_state_group:SetState(self._is_unlocked and 0 or 1)
    if not self._is_unlocked and not_null(self._txt_locked) then
      UIUtil.set_text_by_id(self._txt_locked, "Codex_Suite_NotUnlocked")
    end
  end
  UIUtil.set_text(self._txt_title, self:_get_page_title())
  UIUtil.set_active(self._obj_outline, is_package)
  ModelPreviewManagerIns:hide()
  UIUtil.set_active(self._trans_pic_group, false)
  UIUtil.set_active(self._img_item_icon, false)
  self:_refresh_cloth_model(is_package)
  self:_refresh_date()
end

function M:_refresh_left_gm_mode()
  self._ui_state_group:SetState(0)
  UIUtil.set_text(self._txt_title, "GM_" .. tostring(self._gm_item_id))
  UIUtil.set_active(self._obj_outline, false)
  ModelPreviewManagerIns:hide()
  UIUtil.set_active(self._trans_pic_group, false)
  UIUtil.set_active(self._img_item_icon, false)
  UIUtil.set_active(self._txt_date, false)
  self:_refresh_cloth_model(false)
end

function M:_refresh_cloth_model(is_package)
  if not is_package then
    self:_clear_temp_player_retry()
    self:_destroy_temp_player()
    self:_pop_camera()
    self:_clear_camera_retry()
    local item_id = self._gm_mode and self._gm_item_id or self.item_data.IdCfg.id
    ModelPreviewManagerIns:set_use_separate_scale(false)
    ModelPreviewManagerIns:show_item_by_id(self._trans_model, item_id)
    return
  end
  if is_null(self._player_root) then
    self:_setup_scene_refs()
    if is_null(self._player_root) then
      self:_schedule_temp_player_retry(is_package)
      return
    end
  end
  if self._temp_player_created and not CsAppearanceManagerUtil.HasTempPlayer() then
    self._temp_player_created = false
  end
  if self._defer_first_temp_player_create and not self._temp_player_created then
    self:_schedule_temp_player_retry(is_package)
    return
  end
  if not self._temp_player_created then
    CsAppearanceManagerUtil.CreateTempPlayerForCodex(self._player_root)
    self._temp_player_created = CsAppearanceManagerUtil.HasTempPlayer()
    if not self._temp_player_created then
      self:_schedule_temp_player_retry(is_package)
      return
    end
  end
  if not CsAppearanceManagerUtil.IsTempPlayerDressUpReady() then
    self:_schedule_temp_player_retry(is_package)
    return
  end
  self:_clear_temp_player_retry()
  self._player_rotation_y = 0
  local ids = self.item_data.PackageItemIds
  if ids and 0 < ids.Count then
    local arr = {}
    for i = 0, ids.Count - 1 do
      arr[#arr + 1] = ids[i]
    end
    CsAppearanceManagerUtil.TempPlayerPutOnCodexSuite(arr)
  end
  self:_push_camera()
end

function M:_destroy_temp_player()
  if self._temp_player_created then
    CsAppearanceManagerUtil.DestroyTempPlayer()
    self._temp_player_created = false
  end
end

function M:_schedule_temp_player_retry(is_package)
  if self._temp_player_retry_coroutine ~= nil then
    return
  end
  if self._temp_player_retry_count >= MAX_TEMP_PLAYER_RETRY then
    return
  end
  self._temp_player_retry_count = self._temp_player_retry_count + 1
  self._temp_player_retry_coroutine = CsCoroutineManagerUtil.InvokeAfterFrames(1, function()
    self._temp_player_retry_coroutine = nil
    self._defer_first_temp_player_create = false
    if not self.is_active then
      return
    end
    self:_refresh_cloth_model(is_package)
  end)
end

function M:_clear_temp_player_retry()
  if self._temp_player_retry_coroutine ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._temp_player_retry_coroutine)
    self._temp_player_retry_coroutine = nil
  end
  self._temp_player_retry_count = 0
end

function M:close_self()
  if self._gm_mode then
    UIManagerInstance:close(self.guid)
    return
  end
  base.close_self(self)
end

function M:_on_mouse_scroll(action)
  local var = InputManagerIns:get_axis(ActionType.Act.MouseScroll)
  if is_null(var) or var == 0 then
    return
  end
end

function M:_on_drag(evt)
  if self._temp_player_created then
    local delta = evt.delta
    if is_null(delta) then
      return
    end
    self._player_rotation_y = (self._player_rotation_y or 0) - delta.x * 0.5
    CsAppearanceManagerUtil.TempPlayerUpdateRotationY(self._player_rotation_y)
  else
    ModelPreviewManagerIns:on_drag_model(evt)
  end
end

return M
