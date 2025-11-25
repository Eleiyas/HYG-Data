local M = G.Class("BGSceneManager")

function M:_ctor()
  self._go = nil
  self._look_target = nil
  self._handle = nil
  self._cur_item_id = nil
  self._show_item_go = nil
  self._show_item_handle = nil
  self._ready = false
  self._is_create = false
  self._trans_3dbg_quad = nil
  self._mat_3dbg = nil
  self._trans_skybox = nil
  self._sphere_land_source = nil
end

function M:show_bg_img(img_path, proxy)
  local ui_sprite = proxy:LoadSprite(img_path)
  if ui_sprite == nil then
    Logger.LogWarning("Failed to load sprite from path: " .. img_path)
    return
  end
  self:show_bg_img_texture(ui_sprite.texture)
end

function M:show_bg_img_texture(texture)
  if is_null(texture) then
    return
  end
  if self._mat_3dbg ~= nil then
    self._mat_3dbg.mainTexture = texture
    if not is_null(self._trans_3dbg_quad) then
      UIUtil.set_active(self._trans_3dbg_quad, true)
    end
  else
    Logger.LogWarning("Failed to get material from _trans_3dbg_quad")
  end
end

function M:get_bg_img_texture()
  if self._mat_3dbg ~= nil then
    return self._mat_3dbg.mainTexture
  end
  return nil
end

function M:preload_scene()
  if self._is_create then
    return
  end
  self._main_cam = GameplayUtility.Camera.MainCamera
  self._is_create = true
  CsUIUtil.LoadPrefabAsync("UI/UIBackgroundScene", function(go, handle)
    if is_null(go) then
      return
    end
    self._handle = handle
    self._go = go
    local trans = go.transform
    UIUtil.set_active(trans, false)
    CsUIUtil.DisableSphere(trans)
    trans:SetLocalPosition(100, 1000, 0)
    trans:SetLocalScale(1, 1, 1)
    self._look_target = UIUtil.find_trans(trans, "look_target")
    self._trans_skybox = UIUtil.find_trans(trans, "UI_sky")
    self._trans_3dbg_quad = UIUtil.find_trans(trans, "3DBgQuad")
    local renderer = UIUtil.find_cmpt(self._trans_3dbg_quad, "", typeof(MeshRender))
    if renderer ~= nil then
      self._mat_3dbg = renderer.material
      if self._mat_3dbg == nil then
        Logger.LogError("Failed to get material from MeshRenderer")
      end
    else
      Logger.LogError("Failed to get MeshRenderer from _trans_3dbg_quad")
    end
    self._ready = true
    if self._call_back ~= nil then
      self._call_back()
      self._call_back = nil
    end
  end)
end

function M:load_enviro_profile(profile)
  if self._cache_profile == nil then
    self._cache_profile = EnvironmentSystemManager.GlobalEnviroSkyNew.SharedProfile
  end
  EnvironmentSystemManager.GlobalEnviroSkyNew.SharedProfile = profile
end

function M:open_directional_light()
  ModelPreviewManagerIns:open_directional_light()
end

function M:close_directional_light()
  ModelPreviewManagerIns:close_directional_light()
end

function M:unload_enviro_profile()
  if self._cache_profile ~= nil then
    EnvironmentSystemManager.GlobalEnviroSkyNew.SharedProfile = self._cache_profile
    self._cache_profile = nil
  end
end

function M:show(call_back, hide_sky_box)
  if self._ready and is_null(self._go) then
    self:destroy()
  end
  if not self._is_create then
    self:preload_scene()
  end
  
  function self._call_back()
    UIUtil.set_active(self._go, true)
    UIUtil.set_active(self._trans_3dbg_quad, false)
    UIUtil.set_active(self._trans_skybox, not hide_sky_box)
    local lockCameraData = GameplayUtility.Camera.CreateLockData()
    lockCameraData.lookatOffset = -self._look_target.forward
    lockCameraData.followOffset = self._look_target.forward * 2.5
    lockCameraData.fov = 20
    lockCameraData.lerp = false
    lockCameraData.lerpFov = false
    GameplayUtility.Camera.SetLockActive(lockCameraData, self._look_target, self._look_target)
    CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
      local canvas_z_pos = 100
      local cam_transform = self._main_cam.transform
      local cam_forward = cam_transform.forward
      local canvas_position = cam_transform.position + cam_forward * canvas_z_pos
      local cam_fov = self._main_cam.fieldOfView
      local cam_aspect = self._main_cam.aspect
      local canvas_width = 2 * canvas_z_pos * math.tan(cam_fov * 0.5 * math.pi / 180) * cam_aspect
      local canvas_height = 2 * canvas_z_pos * math.tan(cam_fov * 0.5 * math.pi / 180)
      self._trans_3dbg_quad.localEulerAngles = Vector3(0, 180, 0)
      self._trans_3dbg_quad.localScale = Vector3(canvas_width, canvas_height, 1)
      self._trans_3dbg_quad.position = canvas_position
      if self._cur_item_id ~= nil then
        local item_id = self._cur_item_id
        self._cur_item_id = nil
        self:show_item(item_id, self._rect_trans)
      end
      if self._sphere_land_source == nil then
        self._sphere_land_source = CS.miHoYo.HYG.SimpleSphereLandDataSource()
      end
      self._sphere_land_source:SetSphereOn(false)
      CsSphereLandManagerUtil.RegisterDataSource(self._sphere_land_source)
      if call_back ~= nil then
        call_back()
      end
    end)
  end
  
  if self._ready then
    self._call_back()
    self._call_back = nil
  end
end

function M:Flip3DBG()
  self._trans_3dbg_quad.localEulerAngles = Vector3(180, self._trans_3dbg_quad.localEulerAngles.y, self._trans_3dbg_quad.localEulerAngles.z)
end

function M:play_backGround_blurStart_anim(callable)
  if is_null(self._trans_3dbg_quad) then
    return
  end
  GameplayUtility.Animation.RequestPlay(self._trans_3dbg_quad, "BackGround_EnterBlur", callable, nil, true)
end

function M:play_backGround_blurEnd_anim(callable)
  if is_null(self._trans_3dbg_quad) then
    return
  end
  GameplayUtility.Animation.RequestPlay(self._trans_3dbg_quad, "BackGround_ExitBlur", callable, nil, true)
end

function M:show_item(item_id, rect_trans, call_back)
  if self._cur_item_id == item_id then
    self._rect_trans = rect_trans
    return
  end
  self._cur_item_id = item_id
  self._rect_trans = rect_trans
  self._show_item_call_back = call_back
  if not self._ready then
    return
  end
  ModelPreviewManagerIns:show_item_by_id(rect_trans, item_id, pack(self, self._on_model_load))
end

function M:show_react_item(item_id, should_refresh_avatar, rect_trans)
  if self._cur_item_id == item_id then
    self._rect_trans = rect_trans
    return
  end
  self._cur_item_id = item_id
  self._rect_trans = rect_trans
  if not self._ready then
    return
  end
  ModelPreviewManagerIns:show_react_item_by_id(rect_trans, should_refresh_avatar, item_id)
end

function M:clear_model()
  self._cur_item_id = nil
  self._rect_trans = nil
  self._show_item_go = nil
  ModelPreviewManagerIns:hide()
end

function M:destroy_react_avatar_model()
  ModelPreviewManagerIns:destroy_avatar_model()
end

function M:_on_model_load(go)
  if is_null(go) then
    return
  end
  self._show_item_go = go
  if self._show_item_call_back ~= nil then
    self._show_item_call_back(go)
    self._show_item_call_back = nil
  end
  if self._cur_item_id == nil then
    ModelPreviewManagerIns:hide()
  end
end

function M:_adapt_model_size(trans, is_cloth)
  local bounds = ModelPreviewManagerIns:get_combined_bounds(trans, is_cloth)
  local length = Vector2(bounds.size.x, bounds.size.z).magnitude
  local scale = 0.7 / length
  trans:SetLocalScale(scale, scale, scale)
end

function M:hide()
  self:unload_enviro_profile()
  GameplayUtility.Camera.ExitLockCamera()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if self._sphere_land_source ~= nil then
      CsSphereLandManagerUtil.UnregisterDataSource(self._sphere_land_source)
    end
    ModelPreviewManagerIns:hide()
    if not is_null(self._go) then
      UIUtil.set_active(self._go, false)
    end
    self:clear_model()
  end)
  if not GlobalVars.AlwaysCacheUI then
    self:destroy()
  end
end

function M:destroy()
  if not is_null(self._go) then
    UIUtil.destroy_go(self._go)
    self._go = nil
  end
  if self._handle ~= nil then
    CsUIUtil.DismissResource(self._handle)
    self._handle = nil
  end
  self._cache_profile = nil
  self._is_create = false
  self._ready = false
  self._look_target = nil
  self._trans_skybox = nil
  self._trans_3dbg_quad = nil
end

return M
