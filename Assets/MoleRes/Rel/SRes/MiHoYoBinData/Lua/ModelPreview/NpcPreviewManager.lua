local M = G.Class("ModelPreviewManager")
local LayerMask = CS.UnityEngine.LayerMask
local rota_speed = 0.06
local camera_z_offset = 3
local scale_ratio = 1.2
local local_angle_x = 0

function M:__ctor()
  self._npc_trans = nil
  self._npc = nil
  self._npc_id = nil
  self._is_show = false
  self._rotate_trans = nil
  self._rotate_obj = nil
  self._preview_root_trans = nil
  self._preview_root_obj = nil
  self.rect_utility = CS.UnityEngine.RectTransformUtility
end

function M:_init()
  self._preview_root_obj = GameObject("NpcPreviewRoot")
  self._preview_root_trans = self._preview_root_obj.transform
  self._main_camera.transform:SetLocalScale(1, 1, 1)
  self._preview_root_trans:SetParent(self._main_camera.transform)
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._preview_root_trans:SetLocalEulerAngles(local_angle_x, 0, 0)
  self._preview_root_trans:SetLocalScale(1, 1, 1)
  self._rotate_obj = GameObject("NpcRotateRoot")
  self._rotate_trans = self._rotate_obj.transform
  self._rotate_trans:SetParent(self._preview_root_trans)
  self._rotate_trans:SetLocalEulerAngles(0, 0, 0)
  self._rotate_trans:SetLocalPosition(0, 0, 0)
end

function M:load_npc(npc_id, rect_trans, load_callback)
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  self._main_camera = GameplayUtility.Camera.MainCamera
  self._ui_camera = UIManagerInstance.ui_camera
  if is_null(self._preview_root_trans) then
    self:_init()
  end
  self:_inter_load_npc(npc_id, function(need_resize)
    self._npc_showing = true
    if need_resize then
      self._rotate_trans:SetLocalEulerAngles(0, 180, 0)
      self:_resize_model(rect_trans)
    end
    if load_callback then
      load_callback(self._npc)
    end
  end)
end

function M:show_item_by_id(rect_trans, item_id, load_callback, layout, from_editor)
  if is_null(GameplayUtility.Camera.MainCamera) or is_null(UIManagerInstance.ui_camera) then
    return
  end
  if layout == nil then
    layout = ModelPreviewLayout.Bottom
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
  local model_path
  if item_id == 20003 then
    model_path = "Item/1_Tool/20003_Item_1tool_fishploeDrop"
  else
    model_path = CS.BEntityCfg.GetDisplayAssetPath(item_id)
  end
  if model_path == nil or model_path == "" then
    return
  end
  local item_bag_type = item_module:get_item_bag_type_by_id(item_id)
  self:_inter_load_npc(model_path, item_bag_type, item_id, function(need_resize)
    self._npc_showing = true
    if need_resize then
      self._rotate_trans:SetLocalEulerAngles(0, 180, 0)
      self:_resize_model(rect_trans, layout)
    end
    if load_callback then
      load_callback(self._npc_trans.gameObject)
    end
  end)
end

function M:_inter_load_npc(npc_id, load_action)
  if npc_id == self._npc_id then
    if load_action and not is_null(self._npc_trans) then
      UIUtil.set_active(self._npc_trans, true)
      load_action(false, self._npc_trans)
    end
    return
  end
  self:_destroy_model()
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._preview_root_trans:SetLocalEulerAngles(local_angle_x, 0, 0)
  self._rotate_trans:SetLocalEulerAngles(0, 0, 0)
  self._rotate_trans:SetLocalPosition(0, 0, 0)
  self._npc_id = npc_id
  local cache_npc_id = npc_id
  CsUIUtil.CreateVirtualNpc(npc_id, function(entity)
    self:_on_model_load(entity, cache_npc_id, load_action)
  end)
end

function M:_on_model_load(entity, cache_npc_id, load_action)
  if self._npc_id ~= cache_npc_id then
    CsEntityManagerUtil.RemoveEntity(entity)
    return
  end
  if not is_null(self._npc_trans) then
    self:_destroy_model()
  end
  self._npc = entity
  local go = entity.root
  self._preview_root_trans:SetLocalPosition(0, 0, 0)
  self._npc_trans = go.transform
  self._npc_trans:SetParent(self._rotate_trans)
  if self._npc_trans then
    UIUtil.set_active(self._npc_trans, true)
    self._npc_trans:SetLocalPosition(0, 0, 0)
    self._npc_trans:SetLocalEulerAngles(0, 0, 0)
  end
  self._npc_trans.gameObject:SetLayer(LayerMask.NameToLayer("SceneProp"), true)
  CsUIUtil.DisableSphere(self._npc_trans)
  if load_action then
    load_action(true)
  end
end

function M:_resize_model(rect_trans)
  if is_null(self._main_camera) or is_null(self._ui_camera) or is_null(rect_trans) then
    return
  end
  local corners = CsUIUtil.GetWorldCorners(rect_trans)
  if corners.Count == 4 then
    local left_pos = self:_get_world_pos(corners[0])
    local left_up_pos = self:_get_world_pos(corners[1])
    local right_pos = self:_get_world_pos(corners[3])
    if right_pos and left_pos then
      local model_bottom_pos = (right_pos + left_pos) / 2
      local model_middle_pos = (left_up_pos + right_pos) / 2
      local side = (right_pos - left_pos).magnitude
      local combined_bounds
      if self._is_cloth then
        if is_null(self._cloth_preview) == false and is_null(self._cloth_preview.hangerModel) == false then
          combined_bounds = self:get_combined_bounds(self._cloth_preview.hangerModel.transform, false)
        end
      else
        combined_bounds = self:get_combined_bounds(self._npc_trans, false)
      end
      if combined_bounds == nil then
        Logger.LogWarning("no bounds found" .. self._npc_id)
        return
      end
      local model_pos = model_bottom_pos
      local ratio = side / combined_bounds.size.magnitude
      self:set_mode_scale(ratio * scale_ratio)
      local length = Vector2(combined_bounds.size.x, combined_bounds.size.z).magnitude
      self._inner_scale = ratio * scale_ratio
      local root_pos = model_pos
      self._preview_root_trans:SetLocalPosition(0, 0, 0)
      self._preview_root_trans:LookAt(root_pos)
      self._preview_root_trans:SetLocalEulerAnglesZ(0)
      self._preview_angle_offset = self._preview_root_trans.localEulerAngles
      self._preview_root_trans:AddLocalEulerAnglesX(local_angle_x)
      self._preview_root_trans.position = root_pos
      local offset_y = combined_bounds.size.y * self._inner_scale * 0.5
      self._rotate_trans:SetLocalPositionY(offset_y)
      self._npc_trans:SetLocalPositionY(-offset_y)
    end
  end
end

function CalculateAngle(vectorA, vectorB)
  local dotProduct = vector3.Dot(vectorA.normalized, vectorB.normalized)
  local angle = math.acos(dotProduct) * 180 / math.pi
  return angle
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
  return bounds
end

function M:set_mode_scale(scale)
  if self._npc_trans == nil then
    return
  end
  self._npc_trans:SetLocalScale(scale, scale, scale)
end

function M:_get_world_pos(pos)
  local vector = CsUIUtil.WorldToScreenPoint(self._ui_camera, pos)
  local world_pos = self:get_world_pos_by_ui(vector)
  return world_pos
end

function M:get_world_pos_by_ui(ui_pos)
  return self._main_camera:ViewportToWorldPoint(Vector3(ui_pos.x / Screen.width, ui_pos.y / Screen.height, camera_z_offset))
end

function M:get_cam_local_pos_by_ui(ui_pos)
  local world_pos = self:get_world_pos_by_ui(ui_pos)
  local local_pos = self._main_camera.transform:InverseTransformPoint(world_pos)
  return local_pos
end

function M:_destroy_model()
  if not is_null(self._npc_trans) then
    self._npc_showing = false
    CsEntityManagerUtil.RemoveEntity(self._npc)
    self._npc_trans = nil
    self._npc_id = nil
    self._npc = nil
  end
end

function M:hide()
  self._npc_showing = false
  if not is_null(self._npc_trans) then
    self:_destroy_model()
  end
end

function M:get_model()
  return self._npc_trans
end

return M
