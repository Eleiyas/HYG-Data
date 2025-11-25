local M = G.Class("ModelPreviewManager")
local LayerMask = CS.UnityEngine.LayerMask
local rota_speed = 0.06
local camera_z_offset = 3
local scale_ratio = 1
local local_angle_x = -26
local rotator_origin_scale = 1
local avatar_scale_ratio = 2
ModelPreviewLayout = {
  Bottom = 0,
  Center = 1,
  Middle = 2
}

function M:__ctor()
  self._entity_guid = nil
  self._model = nil
  self._model_path = nil
  self._is_show = false
  self._show_item_handler = nil
  self._rotate_trans = nil
  self._rotate_obj = nil
  self._preview_root_trans = nil
  self._preview_root_obj = nil
  self.rect_utility = CS.UnityEngine.RectTransformUtility
  self._model_raw_data = {}
  self._model_rotate_speed = rota_speed
  self._gm_model_id = 0
  self._directional_light = nil
  self.mode_rotatable = true
  self.mode_additional_rotate = 0
end

function M:get_directional_light()
  return self._directional_light
end

function M:close_directional_light()
  if not is_null(self._directional_light) then
    self._directional_light.enabled = false
  end
end

function M:open_directional_light()
  if not is_null(self._directional_light) then
    self._directional_light.enabled = true
  end
end

function M:_destroy_directional_light()
  if self._directional_light then
    UIUtil.destroy_go(self._directional_light.gameObject)
    self._directional_light = nil
  end
end

function M:_init()
  self._preview_root_obj = GameObject("ModelPreviewRoot")
  self._preview_root_trans = self._preview_root_obj.transform
  self._main_camera.transform:SetLocalScale(1, 1, 1)
  self._preview_root_trans:SetParent(self._main_camera.transform)
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._preview_root_trans:SetLocalEulerAngles(local_angle_x, 0, 0)
  self._preview_root_trans:SetLocalScale(1, 1, 1)
  self._rotate_obj = GameObject("ModelRotateRoot")
  self._rotate_trans = self._rotate_obj.transform
  self._rotate_trans:SetParent(self._preview_root_trans)
  self._rotate_trans:SetLocalEulerAngles(0, 0, 0)
  self._rotate_trans:SetLocalPosition(0, 0, 0)
  local_angle_x = ModelPreviewConfig.GetDefaultAngle()
  rota_speed = ModelPreviewConfig.GetDefaultRSpeed()
  scale_ratio = ModelPreviewConfig.GetDefaultModelScale()
  self._model_rotate_speed = rota_speed
end

function M:show_item_by_id(rect_trans, item_id, load_callback, layout, from_editor)
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  if layout == nil then
    layout = ModelPreviewLayout.Middle
  end
  self._from_editor = from_editor
  if self._from_editor == nil then
    self._from_editor = false
  end
  if ApplicationUtil.IsEnableGM() and self._gm_model_id and self._gm_model_id ~= 0 then
    item_id = self._gm_model_id
    self._gm_model_id = 0
  end
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._preview_root_trans) then
    self:_init()
  end
  local model_path = self:get_model_asset(item_id)
  if model_path == nil or model_path == "" then
    return
  end
  local item_bag_type = item_module:get_item_bag_type_by_id(item_id)
  self.mode_rotatable = true
  self.mode_additional_rotate = 0
  self:_inter_load_model(model_path, item_bag_type, item_id, function(need_resize)
    self._model_showing = true
    if need_resize then
      self._rotate_trans:SetLocalEulerAngles(0, 180, 0)
      self:_resize_model(rect_trans, layout)
      self:_apply_cfg(item_id)
    end
    if load_callback then
      load_callback(self._model.gameObject)
    end
  end)
end

function M:show_react_item_by_id(rect_trans, should_refresh_avatar, item_id)
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._preview_root_trans) then
    self:_init()
  end
  self.mode_rotatable = false
  self.mode_additional_rotate = 0
  local react_card_cfg = LocalDataUtil.get_value(typeof(CS.BReactionCardCfg), item_id)
  local unlock_reaction_id = react_card_cfg.unlockreactionid
  local reaction_cfg = LocalDataUtil.get_value(typeof(CS.BReactionCfg), unlock_reaction_id)
  local reaction_atl_name = string.lower(reaction_cfg.hostatltagname)
  if reaction_atl_name == nil or reaction_atl_name == "" then
    reaction_atl_name = string.lower(reaction_cfg.hostinviteatltagname)
  end
  self._reaction_atl = ATLTagTags.Tags[reaction_atl_name]
  local is_double = reaction_cfg.participant == 2 and string.is_valid(reaction_cfg.guestatltagname)
  if is_double then
    local reaction_atl_name_double = string.lower(reaction_cfg.guestatltagname)
    self._reaction_atl_double = ATLTagTags.Tags[reaction_atl_name_double]
  else
    self._reaction_atl_double = nil
  end
  self:_inter_load_avatar(rect_trans, should_refresh_avatar, is_double)
end

function M:show_centered_model_by_id()
end

function M:_inter_load_model(model_path, item_bag_type, item_id, load_action)
  if model_path == self._model_path then
    if load_action and not is_null(self._model) then
      UIUtil.set_active(self._model, true)
      load_action(false, self._model)
    end
    return
  end
  self:_destroy_model()
  self:_hide_avatar_model()
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._preview_root_trans:SetLocalEulerAngles(local_angle_x, 0, 0)
  self._rotate_trans:SetLocalEulerAngles(0, 0, 0)
  self._rotate_trans:SetLocalPosition(0, 0, 0)
  self._rotate_trans:SetLocalScale(rotator_origin_scale, rotator_origin_scale, rotator_origin_scale)
  self._model_path = model_path
  local cache_path = model_path
  if item_bag_type == ItemBagType.BagTypeCloth.value__ and not item_module:is_clothing_handheld(item_id) then
    CsClothPreviewUtilUtil.CreateClothPreviewAuto(item_id, CS.ClothPreviewSubtype.Default, function(preview)
      local cloth_preview = preview
      cloth_preview:LoadAsync(function()
        CsCoroutineManagerUtil.InvokeAfterFrames(1, function()
          self:_on_model_load(cloth_preview.root, 0, cache_path, load_action, item_bag_type, item_id, cloth_preview)
        end)
        cloth_preview:ReleaseAction()
      end)
    end)
  elseif item_bag_type == ItemBagType.BagTypeBiota.value__ then
    self._entity_guid = EntityUtil.create_model_preview_entity(item_id, function(go)
      self:_on_model_load(go, nil, cache_path, load_action, item_bag_type, item_id, nil)
    end)
    CsCodexModuleUtil.PlayCreatureATLByEntityGuid(self._entity_guid, item_id)
  else
    CsUIUtil.LoadPrefabAsync(model_path, function(go, handle)
      self:_on_model_load(go, handle, cache_path, load_action, item_bag_type, item_id, nil)
    end)
  end
end

function M:_inter_load_avatar(rect_trans, should_refresh_avatar, is_double)
  self:_destroy_model()
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._preview_root_trans:SetLocalEulerAngles(local_angle_x, 0, 0)
  self._rotate_trans:SetLocalEulerAngles(0, 0, 0)
  self._rotate_trans:SetLocalPosition(0, 0, 0)
  self._rotate_trans:SetLocalScale(rotator_origin_scale, rotator_origin_scale, rotator_origin_scale)
  if self._perform_player_guid == nil then
    self._perform_player_guid = {}
    self._perform_player_creating = {}
    self._perform_player_hide = {}
    self._avatar_model = {}
  end
  self._perform_player_hide[1] = false
  if is_null(self._avatar_model[1]) and not self._perform_player_creating[1] then
    self._perform_player_creating[1] = true
    self._perform_player_guid[1] = EntityUtil.create_perform_player(true, function(avatar_go)
      self:_init_avatar(avatar_go, rect_trans, 1)
      self:_set_avatar_position(rect_trans, is_double)
      if not is_double or not is_null(self._avatar_model[2]) then
        self:_avatar_play_atl()
      end
      if self._perform_player_hide[1] then
        self._avatar_model[1]:SetActive(false)
        self._perform_player_hide[1] = false
      end
      self._perform_player_creating[1] = false
    end)
  elseif not is_null(self._avatar_model[1]) then
    if should_refresh_avatar then
      EntityUtil.put_on_avatar_by_real_player(self._perform_player_guid[1])
    end
    self._avatar_model[1]:SetActive(true)
    if not is_double or not is_null(self._avatar_model[2]) then
      self:_avatar_play_atl()
    end
  end
  if is_double then
    self._perform_player_hide[2] = false
    if is_null(self._avatar_model[2]) and not self._perform_player_creating[2] then
      self._perform_player_creating[2] = true
      self._perform_player_guid[2] = EntityUtil.create_perform_player(false, function(avatar_go)
        self:_init_avatar(avatar_go, rect_trans, 2)
        self:_set_avatar_position(rect_trans, is_double)
        if not is_null(self._avatar_model[1]) then
          self:_avatar_play_atl()
        end
        if self._perform_player_hide[2] then
          self._avatar_model[2]:SetActive(false)
          self._perform_player_hide[2] = false
        end
        self._perform_player_creating[2] = false
      end)
    elseif not is_null(self._avatar_model[2]) then
      self._avatar_model[2]:SetActive(true)
      if not is_null(self._avatar_model[1]) then
        self:_avatar_play_atl()
      end
    end
  elseif not is_null(self._avatar_model[2]) then
    self._avatar_model[2]:SetActive(false)
  end
  self:_set_avatar_position(rect_trans, is_double)
end

function M:_avatar_play_atl()
  if self._avatar_model == nil then
    return
  end
  if self._reaction_atl ~= nil and not is_null(self._avatar_model[1]) then
    EntityUtil.play_atl_with_tag(self._perform_player_guid[1], self._reaction_atl, function(info)
      EntityUtil.play_atl_with_tag(self._perform_player_guid[1], ATLTagTags.Tags.atlstate_avatar_fullbody_move_idle_locomotion_idleing)
    end)
    self._reaction_atl = nil
  end
  if self._reaction_atl_double ~= nil and not is_null(self._avatar_model[2]) then
    EntityUtil.play_atl_with_tag(self._perform_player_guid[2], self._reaction_atl_double, function(info)
      EntityUtil.play_atl_with_tag(self._perform_player_guid[2], ATLTagTags.Tags.atlstate_avatar_fullbody_move_idle_locomotion_idleing)
    end)
    self._reaction_atl_double = nil
  end
end

function M:_init_avatar(avatar_go, rect_trans, index)
  if self._avatar_model == nil then
    self._avatar_model = {}
  end
  self._avatar_model[index] = avatar_go.transform
  self._avatar_model[index]:SetParent(self._rotate_trans)
  avatar_go:SetLayer(LayerMask.NameToLayer("SceneProp"), true)
  CsUIUtil.DisableSphere(self._avatar_model[index])
  self:_resize_avatar(self._avatar_model[index], rect_trans)
end

function M:_on_model_load(go, handle, cache_path, load_action, item_bag_type, config_id, cloth_preview, use_animator)
  local wait_fish_animation_back = false
  if use_animator == nil then
    use_animator = false
  end
  if self._model_path ~= cache_path then
    if item_bag_type ~= ItemBagType.BagTypeBiota.value__ then
      UIUtil.destroy_go(go)
    else
      EntityUtil.destroy_entity_by_guid(self._entity_guid)
      self._entity_guid = nil
    end
    if item_bag_type == ItemBagType.BagTypeCloth.value__ and not item_module:is_clothing_handheld(config_id) then
      if is_null(cloth_preview) == false then
        cloth_preview:Release()
      end
    elseif handle and handle ~= 0 then
      CsUIUtil.DismissResource(handle)
    end
    return
  end
  if not is_null(self._model) then
    self:_destroy_model()
  end
  self:_hide_avatar_model()
  self._cloth_preview = cloth_preview
  self._is_cloth = item_bag_type == ItemBagType.BagTypeCloth.value__ and not item_module:is_clothing_handheld(config_id)
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._model = go.transform
  self._model:SetParent(self._rotate_trans)
  if self._model then
    local cmpt = UIUtil.find_cmpt(self._model, nil, typeof(CS.UnityEngine.Rigidbody))
    if not is_null(cmpt) then
      UIUtil.destroy_go(cmpt)
    end
    UIUtil.set_active(self._model, true)
    self._model:SetLocalPosition(0, 0, 0)
    self._model:SetLocalEulerAngles(0, 0, 0)
    if self._is_cloth == false and not use_animator and not item_bag_type == ItemBagType.BagTypeBiota.value__ then
      local animator = UIUtil.find_cmpt(self._model, nil, typeof(CS.UnityEngine.Animator))
      if not is_null(animator) then
        UIUtil.destroy_go(animator)
      end
    end
    if config_id == 90021 then
      CsUIUtil.HideLineRender(self._model)
    end
  end
  self._model.gameObject:SetLayer(LayerMask.NameToLayer("SceneProp"), true)
  CsUIUtil.DisableSphere(self._model)
  self._show_item_handler = handle
  if load_action and wait_fish_animation_back == false then
    load_action(true)
  end
end

function M:_resize_model(rect_trans, layout, new_mode)
  if is_null(self._main_camera) or is_null(self._ui_camera) or is_null(rect_trans) then
    return
  end
  local corners = CsUIUtil.GetWorldCorners(rect_trans)
  if corners.Count == 4 then
    local left_pos = self:_get_world_pos(corners[0], new_mode)
    local left_up_pos = self:_get_world_pos(corners[1], new_mode)
    local right_pos = self:_get_world_pos(corners[3], new_mode)
    if right_pos and left_pos then
      local model_bottom_pos = (right_pos + left_pos) / 2
      local model_middle_pos = (left_up_pos + right_pos) / 2
      local side = (right_pos - left_pos).magnitude
      local height = (left_pos - left_up_pos).magnitude
      local combined_bounds
      if self._is_cloth then
        if is_null(self._cloth_preview) == false and is_null(self._cloth_preview.root) == false then
          combined_bounds = self:get_combined_bounds(self._cloth_preview.root.transform, false)
        end
      else
        combined_bounds = self:get_combined_bounds(self._model, false)
      end
      if combined_bounds == nil then
        Logger.LogWarning("no bounds found" .. self._model_path)
        return
      end
      if layout == ModelPreviewLayout.Middle then
        local model_pos = model_middle_pos
        local length = Vector2(combined_bounds.size.x, combined_bounds.size.z).magnitude
        local mode_height = combined_bounds.size.y + 0.5 * length * self:_calculate_offset()
        local vertical_ratio = height / mode_height
        local horizontal_ratio = side / length
        local ratio = math.min(vertical_ratio, horizontal_ratio)
        self:set_mode_scale(ratio * scale_ratio)
        self._inner_scale = ratio * scale_ratio
        local root_pos = model_pos
        self._preview_root_trans:SetLocalPosition(0, 0, 0)
        self._preview_root_trans:LookAt(root_pos)
        self._preview_root_trans:SetLocalEulerAnglesZ(0)
        self._preview_angle_offset = self._preview_root_trans.localEulerAngles
        self._preview_root_trans:AddLocalEulerAnglesX(local_angle_x)
        self._preview_root_trans.position = root_pos
        local offset_y = combined_bounds.size.y * self._inner_scale * 0.5
        self._rotate_trans:SetLocalPositionY(0)
        self._model:SetLocalPositionY(-offset_y)
      elseif layout == ModelPreviewLayout.Bottom then
        local model_pos = model_bottom_pos
        local ratio = side / combined_bounds.size.magnitude
        self:set_mode_scale(ratio * scale_ratio)
        local length = Vector2(combined_bounds.size.x, combined_bounds.size.z).magnitude
        self._inner_scale = ratio * scale_ratio
        local root_pos = model_pos + Vector3(0, 0.5 * length * self:_calculate_offset() * self._inner_scale, 0)
        self._preview_root_trans:SetLocalPosition(0, 0, 0)
        self._preview_root_trans:LookAt(root_pos)
        self._preview_root_trans:SetLocalEulerAnglesZ(0)
        self._preview_angle_offset = self._preview_root_trans.localEulerAngles
        self._preview_root_trans:AddLocalEulerAnglesX(local_angle_x)
        self._preview_root_trans.position = root_pos
        local offset_y = combined_bounds.size.y * self._inner_scale * 0.5
        self._rotate_trans:SetLocalPositionY(offset_y)
        self._model:SetLocalPositionY(-offset_y)
      elseif layout == ModelPreviewLayout.Center then
        local ratio = side / combined_bounds.size.magnitude
        self:set_mode_scale(ratio * scale_ratio)
        self._inner_scale = ratio * scale_ratio
        self._preview_root_trans:SetLocalEulerAngles(0, 0, 0)
        self._preview_angle_offset = self._preview_root_trans.localEulerAngles
        local offset_y = combined_bounds.size.y * self._inner_scale * 0.5
        self._preview_root_trans.position = model_middle_pos
        self._preview_root_trans:AddLocalPositionY(-offset_y)
        self._rotate_trans:SetLocalPositionY(offset_y)
        self._model:SetLocalPositionY(-offset_y)
      end
      self:_set_raw_data()
    end
  end
end

function M:_resize_avatar(avatar_trans, rect_trans)
  if is_null(avatar_trans) then
    return
  end
  local corners = CsUIUtil.GetWorldCorners(rect_trans)
  if corners.Count == 4 then
    local left_pos = self:_get_world_pos(corners[0], true)
    local left_up_pos = self:_get_world_pos(corners[1], true)
    local right_pos = self:_get_world_pos(corners[3], true)
    if right_pos and left_pos then
      local combined_bounds
      combined_bounds = self:get_combined_bounds(avatar_trans, false)
      if self._avatar_inner_scale == nil then
        local side = (right_pos - left_pos).magnitude
        local height = (left_pos - left_up_pos).magnitude
        local length = Vector2(combined_bounds.size.x, combined_bounds.size.z).magnitude
        local mode_height = combined_bounds.size.y + 0.5 * length * self:_calculate_offset()
        local vertical_ratio = height / mode_height
        local horizontal_ratio = side / length
        local ratio = math.min(vertical_ratio, horizontal_ratio)
        self._avatar_inner_scale = ratio * avatar_scale_ratio
      end
      avatar_trans:SetLocalScale(self._avatar_inner_scale, self._avatar_inner_scale, self._avatar_inner_scale)
      local offset_y = combined_bounds.size.y * self._avatar_inner_scale * 0.5
      avatar_trans:SetLocalPositionY(-offset_y)
      avatar_trans:SetLocalPositionZ(0)
    end
  end
end

function M:_set_avatar_position(rect_trans, is_double)
  if self._avatar_model == nil or is_null(self._avatar_model[1]) then
    return
  end
  local corners = CsUIUtil.GetWorldCorners(rect_trans)
  if corners.Count == 4 then
    local left_pos = self:_get_world_pos(corners[0], true)
    local left_up_pos = self:_get_world_pos(corners[1], true)
    local right_pos = self:_get_world_pos(corners[3], true)
    if right_pos and left_pos then
      local model_middle_pos = (left_up_pos + right_pos) / 2
      local model_pos = model_middle_pos
      local root_pos = model_pos
      self._rotate_trans:SetLocalPositionY(0)
      self._preview_root_trans:SetLocalPosition(0, 0, 0)
      self._preview_root_trans:LookAt(root_pos)
      self._preview_root_trans:SetLocalEulerAnglesZ(0)
      self._preview_angle_offset = self._preview_root_trans.localEulerAngles
      self._preview_root_trans:AddLocalEulerAnglesX(local_angle_x)
      self._preview_root_trans.position = root_pos
    end
  end
  if not is_double or is_null(self._avatar_model[2]) then
    self._avatar_model[1]:SetLocalPositionX(0)
  else
    self._avatar_model[1]:SetLocalPositionX(-0.4)
    if not is_null(self._avatar_model[2]) then
      self._avatar_model[2]:SetLocalPositionX(0.1)
    end
  end
end

function M:_hide_avatar_model()
  if self._avatar_model ~= nil and not is_null(self._avatar_model[1]) then
    self._avatar_model[1]:SetActive(false)
    if not is_null(self._avatar_model[2]) then
      self._avatar_model[2]:SetActive(false)
    end
  end
  if self._perform_player_creating ~= nil then
    if self._perform_player_creating[1] then
      self._perform_player_hide[1] = true
    end
    if self._perform_player_creating[2] then
      self._perform_player_hide[2] = true
    end
  end
end

function M:destroy_avatar_model()
  if self._avatar_model ~= nil and not is_null(self._avatar_model[1]) then
    if self._perform_player_guid ~= nil and self._perform_player_guid[1] ~= nil then
      EntityUtil.destroy_entity_by_guid(self._perform_player_guid[1])
      self._perform_player_guid[1] = nil
    else
      UIUtil.destroy_go(self._avatar_model[1].gameObject)
    end
    if not is_null(self._avatar_model[2]) then
      if self._perform_player_guid ~= nil and self._perform_player_guid[2] ~= nil then
        EntityUtil.destroy_entity_by_guid(self._perform_player_guid[2])
        self._perform_player_guid[2] = nil
      else
        UIUtil.destroy_go(self._avatar_model[2].gameObject)
      end
    end
    self._avatar_model = nil
    self._perform_player_guid = nil
    self._perform_player_creating = nil
    self._perform_player_hide = nil
  end
end

function M:record_model_data(position_rect_trans, size_rect_trans, new_mode, size_ratio)
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._main_camera) or is_null(self._ui_camera) or is_null(position_rect_trans) or is_null(size_rect_trans) then
    return
  end
  local position_corners = CsUIUtil.GetWorldCorners(position_rect_trans)
  local size_corners = CsUIUtil.GetWorldCorners(size_rect_trans)
  self._inner_scale = size_ratio * scale_ratio
  if position_corners.Count == 4 and size_corners.Count == 4 then
    self._left_pos = self:_get_world_pos(position_corners[0], new_mode)
    self._left_up_pos = self:_get_world_pos(position_corners[1], new_mode)
    self._right_pos = self:_get_world_pos(position_corners[3], new_mode)
    self._size_left_pos = self:_get_world_pos(size_corners[0], new_mode)
    self._size_up_pos = self:_get_world_pos(size_corners[1], new_mode)
    self._size_right_pos = self:_get_world_pos(size_corners[3], new_mode)
    if self._right_pos and self._left_pos and self._size_left_pos and self._size_right_pos then
      self._model_bottom_pos = (self._right_pos + self._left_pos) / 2
      self._model_middle_pos = (self._left_up_pos + self._right_pos) / 2
      self._size_rect_width = (self._size_right_pos - self._size_left_pos).magnitude
    end
  end
end

function M:_resize_model_for_position_scale(position_rect_trans, size_rect_trans, layout, new_mode, size_ratio)
  if is_null(self._main_camera) or is_null(self._ui_camera) then
    return
  end
  local combined_bounds = self:get_combined_bounds(self._model, false)
  if combined_bounds == nil then
    Logger.LogWarning("no bounds found" .. self._model_path)
    return
  end
  local model_width = combined_bounds.size.x
  if self._size_rect_width == nil then
    self:record_model_data(position_rect_trans, size_rect_trans, new_mode, size_ratio)
  end
  local model_scale_ratio = self._size_rect_width * size_ratio / model_width
  if layout == ModelPreviewLayout.Bottom then
    local model_pos = model_bottom_pos
    self:set_mode_scale(model_scale_ratio)
    self._preview_root_trans:SetLocalPosition(0, 0, 0)
    self._preview_root_trans:LookAt(model_pos)
    self._preview_root_trans:SetLocalEulerAnglesZ(0)
    self._preview_angle_offset = self._preview_root_trans.localEulerAngles
    self._preview_root_trans:AddLocalEulerAnglesX(local_angle_x)
    self._preview_root_trans.position = model_pos
  elseif layout == ModelPreviewLayout.Center then
    self:set_mode_scale(model_scale_ratio)
    self._preview_root_trans:SetLocalEulerAngles(0, 0, 0)
    self._preview_angle_offset = self._preview_root_trans.localEulerAngles
    self._rotate_trans:SetLocalPositionY(0)
    self._preview_root_trans.position = self._model_middle_pos
  end
  self:_set_raw_data()
end

function M:move_model_to_rect(duration, mode)
  if is_null(self._main_camera) or is_null(self._ui_camera) then
    return
  end
  if self._right_pos and self._left_pos then
    local target_pos
    if mode == "screen_middle" then
      target_pos = (self._size_up_pos + self._size_right_pos) / 2
    else
      target_pos = self._model_middle_pos
    end
    CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
      self:_smooth_move_model(target_pos, duration)
    end)
  end
end

function M:_smooth_move_model(target_pos, duration)
  local start_pos = self._preview_root_trans.position
  local elapsed_time = 0
  
  local function move_step()
    if self._model == nil then
      return
    end
    elapsed_time = elapsed_time + Time.deltaTime
    local t = math.min(elapsed_time / duration, 1)
    self._preview_root_trans.position = Vector3.Lerp(start_pos, target_pos, t)
    self:_set_raw_data()
    if t < 1 then
      CsCoroutineManagerUtil.InvokeAfterFrames(1, move_step)
    end
  end
  
  move_step()
end

function M:_apply_cfg(item_id)
  if item_id == nil then
    return
  end
  self.model_preview_data = self:get_cfg_data(item_id, false)
  if self.model_preview_data ~= nil then
    self:set_cfg_data(self.model_preview_data)
  else
    self._model_rotate_speed = rota_speed
  end
end

function CalculateAngle(vectorA, vectorB)
  local dotProduct = vector3.Dot(vectorA.normalized, vectorB.normalized)
  local angle = math.acos(dotProduct) * 180 / math.pi
  return angle
end

function M:_set_raw_data()
  self._model_raw_data = {}
  self._model_raw_data.preview_pos = self._preview_root_trans.localPosition
  self._model_raw_data.preview_angle = self._preview_root_trans.localEulerAngles.x
  self._model_raw_data.model_euler_angle = self._model.localEulerAngles
  self._model_raw_data.model_center_pos = self._model.localPosition
  self._model_raw_data.inner_scale = self._inner_scale
  self._model_raw_data._preview_angle_offset = self._preview_angle_offset
end

function M:_calculate_offset()
  local angle_a = math.rad(math.abs(local_angle_x))
  return math.abs(math.sin(angle_a))
end

function M:_get_y_ratio(size)
  local longer = size.x > size.z and size.x or size.z
  return math.min(size.y / longer, 1)
end

function M:get_combined_bounds(model, use_obj_center)
  self:set_mode_scale(1)
  self:reset_mode_rotate()
  local all_mesh_renders = CsUIUtil.GetAllMeshRender(model, use_obj_center)
  local bounds
  if all_mesh_renders and all_mesh_renders.Count ~= 0 then
    for i, val in pairs(all_mesh_renders) do
      if bounds then
        bounds:Encapsulate(val.bounds)
      else
        bounds = val.bounds
      end
    end
  end
  self:reset_mode_local_rotate()
  return bounds
end

function M:set_mode_scale(scale)
  if self._model == nil then
    return
  end
  self._model:SetLocalScale(scale, scale, scale)
end

function M:reset_mode_rotate()
  if self._model == nil then
    return
  end
  self._model.rotation = Quaternion.identity
end

function M:reset_mode_local_rotate()
  if self._model == nil then
    return
  end
  self._model.localRotation = Quaternion.identity
end

function M:_get_world_pos(pos, new_mode)
  local vector = CsUIUtil.WorldToScreenPoint(self._ui_camera, pos)
  local world_pos = self:get_world_pos_by_ui(vector, new_mode)
  return world_pos
end

function M:get_world_pos_by_ui(ui_pos, new_mode)
  if new_mode then
    return self._main_camera:ViewportToWorldPoint(Vector3(ui_pos.x / Screen.width, ui_pos.y / Screen.height, camera_z_offset))
  else
    return self._main_camera:ScreenToWorldPoint(Vector3(ui_pos.x, ui_pos.y, camera_z_offset))
  end
end

function M:get_cam_local_pos_by_ui(ui_pos)
  local world_pos = self:get_world_pos_by_ui(ui_pos)
  local local_pos = self._main_camera.transform:InverseTransformPoint(world_pos)
  return local_pos
end

function M:_destroy_model()
  if not is_null(self._model) then
    self._model_showing = false
    if self._entity_guid then
      EntityUtil.destroy_entity_by_guid(self._entity_guid)
      self._entity_guid = nil
    else
      UIUtil.destroy_go(self._model.gameObject)
    end
    self._model = nil
    self._model_path = nil
    if self._is_cloth then
      if is_null(self._cloth_preview) == false then
        self._cloth_preview:Release()
      end
      self._cloth_preview = nil
    elseif self._show_item_handler and self._show_item_handler ~= 0 then
      CsUIUtil.DismissResource(self._show_item_handler)
    end
  end
end

function M:hide()
  self._model_showing = false
  self.mode_rotatable = true
  self.mode_additional_rotate = 0
  if not is_null(self._model) then
    self:_destroy_model()
  end
  self:_hide_avatar_model()
  self:close_directional_light()
end

function M:update(deltaTime)
  if not self._model_showing or is_null(self._model) then
    return
  end
  if self.mode_rotatable then
    self._rotate_trans:AddLocalEulerAnglesY(360 * deltaTime * self._model_rotate_speed)
  end
end

function M:scale_model_parent(delta_scale, min_ratio, max_ratio)
  if not self._model_showing or is_null(self._model) then
    return
  end
  local local_scale = self._rotate_trans.localScale.x
  local target_scale = local_scale + delta_scale
  local min_scale = rotator_origin_scale * min_ratio
  local max_scale = rotator_origin_scale * max_ratio
  local final_scale = math.min(math.max(min_scale, target_scale), max_scale)
  self._rotate_trans:SetLocalScale(final_scale, final_scale, final_scale)
end

function M:reset_model_rotation()
  if self._rotate_trans then
    self._rotate_trans:SetLocalEulerAnglesY(0)
  end
end

function M:set_model_additional_rotation(y)
  if self._rotate_trans and self.cfg_data then
    self.mode_additional_rotate = y
    self._rotate_trans.localEulerAngles = self.cfg_data.objRotate
    if self.mode_rotatable == false then
      self._rotate_trans:AddLocalEulerAnglesY(self.mode_additional_rotate)
    end
  end
end

function M:set_cfg_data(cfg_data)
  if cfg_data == nil then
    return
  end
  self.cfg_data = cfg_data
  if self._inner_scale == nil then
    self._inner_scale = 1
  end
  local ratio = self._inner_scale / cfg_data.innerScale
  local a_offset = self._model_raw_data._preview_angle_offset
  self._preview_root_trans:SetLocalEulerAngles(a_offset.x, a_offset.y, a_offset.z)
  self._preview_root_trans:AddLocalEulerAnglesX(cfg_data.angle)
  local model_scale = self._inner_scale * cfg_data.scale * ratio
  self:set_mode_scale(self._inner_scale * cfg_data.scale)
  local preview_pos = cfg_data.posOffset * ratio + self._model_raw_data.preview_pos
  self._preview_root_trans.localPosition = preview_pos
  local model_offset = cfg_data.objRotatePosOffset * ratio + self._model_raw_data.model_center_pos
  self._model.localPosition = model_offset
  self._rotate_trans.localEulerAngles = cfg_data.objRotate
  if self.mode_rotatable == false then
    self._rotate_trans:AddLocalEulerAnglesY(self.mode_additional_rotate)
  end
  self._model_rotate_speed = cfg_data.rSpeed
end

function M:set_model_rotate(speed)
  self._model_rotate_speed = speed
end

function M:get_cfg_data(item_id, get_default_data)
  if item_id == nil then
    return
  end
  local data
  if data == nil then
    data = ModelPreviewConfig.GetConfig(item_id, self._from_editor, get_default_data)
  else
    data.initialized = true
  end
  return data
end

function M:get_model_asset(item_id)
  local model_path
  if item_id == 20003 then
    model_path = "Item/1_Tool/20003_Item_1tool_fishploeDrop"
  elseif item_id == 20007 then
    model_path = "Entity/Item/1_Tool/107_ExtensionBoard/20007_Item_3SpecialTool_slope_preview"
  else
    model_path = CS.BEntityCfg.GetDisplayAssetPath(item_id)
    if string.is_valid(model_path) == false and item_module:is_furniture(item_id) then
      local cfg = CS.BEntityCfg.GetConfig(item_id, SceneItemType.Furniture.value__)
      model_path = cfg and cfg.assetpath or nil
    end
  end
  return model_path
end

function M:set_gm_model_id(id)
  self._gm_model_id = id
end

function M:get_model()
  return self._model
end

function M:get_entity_guid()
  return self._entity_guid
end

function M:show_model_by_path(path, rect_trans, load_callback, use_animator)
  self:_destroy_model()
  self:_hide_avatar_model()
  if string.is_valid(path) == false then
    return
  end
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._preview_root_trans) then
    self:_init()
  end
  self._model_path = path
  local cache_path = path
  CsUIUtil.LoadPrefabAsync(path, function(go, handle)
    self:_on_model_load(go, handle, cache_path, function()
      self._model_showing = true
      self._rotate_trans:SetLocalEulerAngles(0, 180, 0)
      self:_resize_model(rect_trans, ModelPreviewLayout.Center, true)
      self:_apply_cfg(-1)
      if load_callback then
        load_callback(self._model.gameObject)
      end
    end, 0, 0, nil, use_animator)
  end)
end

function M:load_gallery_book_model(path, position_rect_trans, size_rect_trans, ratio, load_callback, use_animator)
  if string.is_valid(path) == false then
    return
  end
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._preview_root_trans) then
    self:_init()
  end
  self._model_path = path
  local cache_path = path
  CsUIUtil.LoadPrefabAsync(path, function(go, handle)
    self:_on_model_load(go, handle, cache_path, function()
      self._model_showing = true
      self._rotate_trans:SetLocalEulerAngles(0, 180, 0)
      self:_resize_model_for_position_scale(position_rect_trans, size_rect_trans, ModelPreviewLayout.Center, true, ratio)
      if load_callback then
        load_callback(self._model.gameObject)
      end
    end, 0, 0, nil, use_animator)
  end)
end

return M
