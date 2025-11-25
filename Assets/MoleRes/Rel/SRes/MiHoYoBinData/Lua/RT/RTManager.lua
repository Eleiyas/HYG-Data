local M = G.Class("RTManager")
local RenderTextureFormat = CS.UnityEngine.RenderTextureFormat
local RenderTexture = CS.UnityEngine.RenderTexture
local LayerMask = CS.UnityEngine.LayerMask
local def_cam_fov = 38
local def_init_angle = 180

function M:__ctor()
  self._trans = nil
  self._cam = nil
  self._trans_cam = nil
  self._rt = nil
  self._rt_w = 0
  self._rt_h = 0
  self._model = nil
  self._model_path = nil
  self._is_show = false
  self._rt_mgr_handler = nil
  self._show_item_handler = nil
  self._is_init = false
  self._load_call_back = nil
end

function M:init(load_action)
  if self._is_init then
    if not is_null(self._trans) and load_action then
      load_action()
    end
    return
  end
  self._load_call_back = load_action
  self._is_init = true
  if not is_null(self._trans) then
    if self._load_call_back then
      self._load_call_back()
      self._load_call_back = nil
    end
    return
  end
  CsUIUtil.LoadPrefabAsync("UI/RTMgr", function(go, handle)
    go.name = "RTMgr"
    self._trans = go.transform
    self._cam = UIUtil.find_cmpt(self._trans, "RT_cam", typeof(Camera))
    self._trans_cam = self._cam.transform
    self._rotate_root_trans = UIUtil.find_trans(self._trans, "RotateObj")
    GameObject.DontDestroyOnLoad(self._trans)
    self:hide()
    self._rt_mgr_handler = handle
    if self._load_call_back then
      self._load_call_back()
      self._load_call_back = nil
    end
    self:set_cam_fov(def_cam_fov)
  end)
end

function M:show_item_by_id(w, h, raw_img, item_id, load_action)
  local model_path = item_module:get_item_model_path(item_id)
  if model_path == nil or model_path == "" then
    return
  end
  local item_bag_type = item_module:get_item_bag_type_by_id(item_id)
  self:show(w, h, raw_img, model_path, item_bag_type, item_id, load_action)
end

function M:show(w, h, raw_img, model_path, item_bag_type, item_id, load_action)
  if is_null(self._trans) then
    self:init(function()
      self:_show(w, h, raw_img, model_path, item_bag_type, item_id, load_action)
    end)
    return
  end
  self:_show(w, h, raw_img, model_path, item_bag_type, item_id, load_action)
end

function M:_show(w, h, raw_img, model_path, item_bag_type, item_id, load_action)
  if is_null(raw_img) then
    Logger.LogError("raw_img 为空")
    return
  end
  if model_path == nil or model_path == "" then
    Logger.LogError("model_path 为空")
    return
  end
  self._is_show = true
  local cur_rt = self:_get_rt(w or 256, h or 256)
  if self._rt ~= cur_rt then
    self._rt = cur_rt
    self._cam.targetTexture = self._rt
  end
  raw_img.texture = self._rt
  self._show_pose_clip = nil
  self._model_animation = nil
  if model_path == self._model_path then
    if load_action and not is_null(self._model) then
      UIUtil.set_active(self._cam, true)
      UIUtil.set_active(self._model, true)
      load_action(self._model.gameObject)
    end
    return
  end
  self:_destroy_model()
  if self._model_path == nil or self._model_path == "" or is_null(self._model) then
    self._model_path = model_path
    local cache_path = model_path
    if item_bag_type == ItemBagType.BagTypeCloth.value__ then
      CsClothPreviewUtilUtil.CreateClothPreviewAuto(item_id, CS.ClothPreviewSubtype.Default, function(preview)
        local cloth_preview = preview
        cloth_preview:LoadAsync(function()
          if is_null(cloth_preview.root) == false then
            cloth_preview.root.transform:SetLocalPosition(0, 10000, 0)
          end
          CsCoroutineManagerUtil.InvokeAfterFrames(1, function()
            self:_on_prefab_load(cloth_preview.root, 0, cache_path, load_action, true, cloth_preview)
          end)
          cloth_preview:ReleaseAction()
        end)
      end)
    else
      CsUIUtil.LoadPrefabAsync(model_path, function(go, handle)
        self:_on_prefab_load(go, handle, cache_path, load_action, false, nil)
      end)
    end
  else
    UIUtil.set_active(self._cam, true)
    if not is_null(self._model) then
      UIUtil.set_active(self._model, true)
    end
    if load_action then
      load_action(self._model.gameObject)
    end
  end
end

function M:_destroy_model()
  if not is_null(self._model) then
    UIUtil.destroy_go(self._model.gameObject)
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

function M:_on_prefab_load(go, handle, cache_path, load_action, from_cloth, cloth_preview)
  if self._model_path ~= cache_path then
    UIUtil.destroy_go(go)
    if from_cloth then
      if is_null(cloth_preview) == false then
        cloth_preview:Release()
      end
    elseif handle and handle ~= 0 then
      CsUIUtil.DismissResource(handle)
    end
  end
  if not is_null(self._model) then
    self:_destroy_model()
    return
  end
  self._cloth_preview = cloth_preview
  self._is_cloth = from_cloth
  self._rotate_root_trans:SetLocalPosition(0, 0, 0)
  self._model = go.transform
  self._model:SetParent(self._rotate_root_trans)
  if self._model then
    local cmpt = UIUtil.find_cmpt(self._model, nil, typeof(CS.UnityEngine.Rigidbody))
    if not is_null(cmpt) then
      UIUtil.destroy_go(cmpt)
    end
    UIUtil.set_active(self._model, true)
    self._model:SetLocalPosition(0, 0, 0)
    self._model:SetLocalEulerAngles(0, 0, 0)
    if from_cloth == false then
      local animator = UIUtil.find_cmpt(self._model, nil, typeof(CS.UnityEngine.Animator))
      if not is_null(animator) then
        UIUtil.destroy_go(animator)
      end
    end
  end
  if self._trans_cam then
    self._trans_cam:SetLocalPosition(0, 0, 0)
    self._trans_cam:SetLocalEulerAngles(0, 0, 0)
  end
  self._model.gameObject:SetLayer(LayerMask.NameToLayer("UI"), true)
  CsUIUtil.DisableSphere(self._model)
  UIUtil.set_active(self._cam, true)
  self._show_item_handler = handle
  if load_action then
    load_action(go)
  end
end

function M:_get_rt(w, h)
  if not is_null(self._rt) and w == self._rt_w and h == self._rt_h then
    return self._rt
  end
  self._rt_w = w
  self._rt_h = h
  if not is_null(self._rt) then
    self._cam.targetTexture = nil
    RenderTexture.ReleaseTemporary(self._rt)
  end
  return RenderTexture.GetTemporary(w, h, 24, RenderTextureFormat.ARGB32)
end

function M:set_cam_pos_data(pos_data, rot_data)
  scale = scale or 1
  if self._trans_cam then
    self._trans_cam:SetLocalPosition(pos_data[0] or 0, pos_data[1] or 0, pos_data[2] or 0)
    self._trans_cam:SetLocalEulerAngles(rot_data[0] or 0, rot_data[1] or 0, rot_data[2] or 0)
  end
end

function M:set_cam_pos_x(x)
  if self._trans_cam then
    self._trans_cam:SetLocalPositionX(x or 0)
  end
end

function M:set_cam_pos_y(y)
  if self._trans_cam then
    self._trans_cam:SetLocalPositionY(y or 0)
  end
end

function M:set_cam_pos_z(z)
  if self._trans_cam then
    self._trans_cam:SetLocalPositionZ(z or 0)
  end
end

function M:set_mode_pos_x(x)
  if self._model then
    self._model:SetLocalPositionX(x or 0)
  end
end

function M:set_mode_pos_y(y)
  if self._model then
    self._model:SetLocalPositionY(y or 0)
  end
end

function M:set_mode_pos_z(z)
  if self._model then
    self._model:SetLocalPositionZ(z or 0)
  end
end

function M:set_cam_rota_x(x)
  if self._trans_cam then
    self._trans_cam:SetLocalEulerAnglesX(x or 0)
  end
end

function M:set_cam_rota_y(y)
  if self._trans_cam then
    self._trans_cam:SetLocalEulerAnglesY(y or 0)
  end
end

function M:set_cam_rota_z(z)
  if self._trans_cam then
    self._trans_cam:SetLocalEulerAnglesZ(z or 0)
  end
end

function M:set_cam(dis, pos_offset, angle, obj_rotate, use_obj_center, combined_bounds)
  if self._trans_cam and self._model then
    self._dis = dis
    self._pos_offset = pos_offset
    self._angle = angle
    self._obj_rotate = obj_rotate
    self._use_obj_center = use_obj_center
    local origin = pos_offset
    if combined_bounds == nil then
      combined_bounds = self:_get_combined_bounds(self._model, use_obj_center)
    end
    if combined_bounds == nil then
      return
    end
    self:_set_rotate_center(combined_bounds.center + pos_offset, obj_rotate)
    origin = combined_bounds.center + pos_offset
    local rad = math.rad(angle)
    local vec = Vector3(0, math.sin(rad), math.cos(rad))
    vec = -vec.normalized * dis
    self._trans_cam.position = origin + vec
    self._trans_cam:LookAt(origin)
  end
end

function M:get_params()
  local data
  if self._trans_cam and self._model then
    data = {}
    data.pos_offset = self._pos_offset
    data.dis = self._dis
    data.angle = self._angle
    data.obj_rotate = self._obj_rotate
    data.use_obj_center = self._use_obj_center
  end
  return data
end

function M:auto_set_value(use_obj_center)
  if self._model and not is_null(self._cam) and self._trans_cam then
    local combined_bounds
    if self._is_cloth then
      if is_null(self._cloth_preview) == false and is_null(self._cloth_preview.hangerModel) == false then
        combined_bounds = self:_get_combined_bounds(self._cloth_preview.hangerModel.transform, use_obj_center)
      end
    else
      combined_bounds = self:_get_combined_bounds(self._model, use_obj_center)
    end
    if is_null(combined_bounds) == false then
      local size = combined_bounds.size
      local x = size.x
      local y = size.y
      local z = size.z
      local width = math.sqrt(x * x + z * z + y * y)
      local dis = width / 2 / math.tan(math.rad(self._cam.fieldOfView / 2))
      local height = 0
      self:set_cam(dis, Vector3.zero, SceneItemShowConfig.DEFAULT_ANGLE, Vector3.zero, use_obj_center, combined_bounds)
      Logger.Log("center: " .. tostring(combined_bounds.center) .. " dis: " .. tostring(dis) .. " height: " .. tostring(height))
      return true
    else
      Logger.LogWarning("没有找到包围盒" .. tostring(self._model.gameObject.name))
      return false
    end
  end
  return false
end

function M:_get_combined_bounds(model, use_obj_center)
  self:reset_model()
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

function M:set_mode_rota(x, y, z)
  if self._model then
    self._model:SetLocalEulerAngles(x, y, z)
  end
end

function M:set_mode_rota_x(x)
  if self._model then
    self._model:SetLocalEulerAnglesX(x or 0)
  end
end

function M:set_mode_rota_y(y)
  if self._model then
    self._model:SetLocalEulerAnglesY(y or 0)
  end
end

function M:set_mode_rota_z(z)
  if self._model then
    self._model:SetLocalEulerAnglesZ(z or 0)
  end
end

function M:add_model_rota_x(x)
  if self._rotate_root_trans then
    self._rotate_root_trans:AddLocalEulerAnglesX(x or 0)
  end
end

function M:add_model_rota_y(y)
  if self._rotate_root_trans then
    self._rotate_root_trans:AddLocalEulerAnglesY(y or 0)
  end
end

function M:add_model_rota_z(z)
  if self._rotate_root_trans then
    self._rotate_root_trans:AddLocalEulerAnglesZ(z or 0)
  end
end

function M:reset_model_rota()
  if self._rotate_root_trans then
    self._rotate_root_trans:SetLocalEulerAngles(0, 0, 0)
  end
end

function M:set_mode_scale(scale)
  self._model:SetLocalScale(scale, scale, scale)
end

function M:reset_model()
  if self._rotate_root_trans then
    self._rotate_root_trans:SetLocalEulerAngles(0, 180, 0)
    self._rotate_root_trans:SetLocalPosition(0, 0, 0)
  end
  if self._model then
    self._model:SetLocalEulerAngles(0, 0, 0)
    self._model:SetLocalPosition(0, 0, 0)
    self:set_mode_scale(1)
  end
end

function M:_set_rotate_center(center, obj_rotate)
  if self._rotate_root_trans and self._model then
    local root_pos = self._trans.position
    local x = center.x - root_pos.x
    local y = center.y - root_pos.y
    local z = center.z - root_pos.z
    self._rotate_root_trans:SetLocalPosition(x, y, z)
    self._model:SetLocalPosition(-x, -y, -z)
    self._model:SetLocalEulerAngles(obj_rotate.x, obj_rotate.y, obj_rotate.z)
  end
end

function M:hide()
  if is_null(self._trans) then
    return
  end
  self._is_show = false
  UIUtil.set_active(self._cam, false)
  if not is_null(self._model) then
    UIUtil.set_active(self._model, false)
  end
end

function M:set_cam_fov(fov)
  if self._cam then
    self._cam.fieldOfView = fov or 60
  end
end

function M:get_show_state()
  return self._is_show or false
end

function M:get_trams()
  return self._trans
end

function M:destroy()
  self._load_call_back = nil
  if not is_null(self._rt) then
    self._cam.targetTexture = nil
    RenderTexture.ReleaseTemporary(self._rt)
    self._rt = nil
    CsUIUtil.DismissResource(self._rt_mgr_handler)
  end
end

return M
