companion_star_module = companion_star_module or {}
companion_star_module.camera_state = NPCSphereLand.NPCSphereLandCameraState
local star_river_distance = 100
local friend_star_river_distance = 100
local friend_camera_height = 10
local friend_camera_zoom_in_distance = 30
local camera_fov = 22
local companion_star_camera_angle = -10
local friend_star_camera_angle = -10

function companion_star_module:_prepare_to_companion_star_camera(galaxy_type, callback)
  local neck_obj = player_module:get_obj_by_type(RefObjType.NeckRoot)
  local main_cam = GameplayUtility.Camera.MainCamera
  local player_guid = EntityUtil.get_player_entity_guid()
  if not (main_cam and player_guid) or player_guid == 0 then
    return
  end
  local camera_tran = main_cam.transform
  local euler_angle = camera_tran.localEulerAngles
  self:_init_obj(function(success)
    if success then
      UIUtil.set_active(self.companion_star_root, true)
      self.target_trans = self.companion_target_trans
      self.look_trans = self.companion_look_trans
      star_river_distance = self.companion_star_ctrl.starRiverDistance
      companion_star_camera_angle = self.companion_star_ctrl.companionStarCameraAngle
      friend_star_camera_angle = self.companion_star_ctrl.friendStarCameraAngle
      friend_star_river_distance = self.companion_star_ctrl.friendStarRiverDistance
      friend_camera_zoom_in_distance = self.companion_star_ctrl.friendCameraZoomInDistance
      friend_camera_height = self.companion_star_ctrl.starMapFriendCameraHeight
      self.companion_star_root.position = Vector3(0, 1000, 0)
      self.companion_star_root.localEulerAngles = Vector3(0, euler_angle.y, 0)
      self.look_trans.localPosition = Vector3(0, 0, 0)
      self.target_trans.localPosition = self.companion_star_ctrl._cameraStartPos
      self.look_pos = self.companion_star_root.position + self.companion_star_ctrl.lookEndPos
      self.target_pos = self.companion_star_root.position + self.companion_star_ctrl.cameraEndPos
      self.camera_vector = self.look_pos - self.target_pos
      self._main_camera_y_angle = 0
      local scale = 1
      local star_map_width, star_map_height, scale = self:calculate_frustum_size(main_cam, star_river_distance)
      self.companion_galaxy_scale = scale
      self.companion_galaxy_angle = math.atan(star_map_width / 2 / star_river_distance) * (180 / math.pi)
      self.galaxy_angle = self.companion_galaxy_angle
      self.galaxy_scale = self.companion_galaxy_scale
      star_map_width, star_map_height, scale = self:calculate_frustum_size(main_cam, friend_star_river_distance)
      self.friend_galaxy_scale = scale
      self.friend_galaxy_angle = math.atan(star_map_width / 2 / friend_star_river_distance) * (180 / math.pi)
      self.companion_star_cam_pos = self.target_pos
      self.friend_star_cam_pos = self.target_pos + Vector3(0, friend_camera_height, 0)
      self.target_trans.position = self.target_pos
      self.look_trans.position = self.look_pos
    end
    callback(success)
  end)
end

function companion_star_module:change_galaxy_camera(galaxy_type, progress)
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  self:_init_obj(function(success)
    if success then
      InputManagerIns:lock_input_while(1.1)
      if galaxy_type == companion_star_module.galaxy_type.friend_star then
        self:_change_to_friend_camera(progress)
      else
        self:_change_to_companion_star_camera(progress)
      end
    end
  end)
end

function companion_star_module:_change_to_friend_camera(progress)
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  self:_init_obj(function(success)
    if success then
      self.target_trans = self.friend_target_trans
      self.look_trans = self.friend_look_trans
      self.galaxy_angle = self.friend_galaxy_angle
      self.galaxy_scale = self.friend_galaxy_scale
      local camera_tran = main_cam.transform
      local euler_angle = camera_tran.localEulerAngles
      self.companion_star_cam_pos = camera_tran.position
      self.temp_target_trans.position = self.target_pos + Vector3(0, friend_camera_height, 0)
      self.temp_target_trans.eulerAngles = Vector3(friend_star_camera_angle, euler_angle.y, euler_angle.z)
      self.target_pos = self.temp_target_trans.position + self.temp_target_trans.forward * friend_camera_zoom_in_distance
      self.look_pos = self.temp_target_trans.position + self.temp_target_trans.forward * (friend_star_river_distance + friend_camera_zoom_in_distance)
      self.temp_look_trans.position = self.look_pos
      self._main_camera_y_angle = -progress * self.galaxy_angle * 2
      self.camera_vector = self.look_pos - self.target_pos
      self.friend_star_cam_pos = self.target_pos
      self.target_trans.position = self.target_pos
      self.look_trans.position = self.look_pos
      GameplayUtility.Camera.PopState("CompanionStar")
      GameplayUtility.Camera.SetFollowActive("FriendStar", self.friend_target_trans, self.friend_look_trans)
    end
  end)
end

function companion_star_module:_change_to_companion_star_camera(progress)
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  self:_init_obj(function(success)
    if success then
      self.target_trans = self.companion_target_trans
      self.look_trans = self.companion_look_trans
      self.galaxy_angle = self.companion_galaxy_angle
      self.galaxy_scale = self.companion_galaxy_scale
      local camera_tran = main_cam.transform
      local euler_angle = camera_tran.localEulerAngles
      self.friend_star_cam_pos = self.target_pos
      self.temp_target_trans.position = camera_tran.position
      self.temp_target_trans.eulerAngles = Vector3(friend_star_camera_angle, euler_angle.y, euler_angle.z)
      self.target_pos = self.temp_target_trans.position - self.temp_target_trans.forward * friend_camera_zoom_in_distance - Vector3(0, friend_camera_height, 0)
      self.temp_target_trans.position = self.target_pos
      self.temp_target_trans.eulerAngles = Vector3(companion_star_camera_angle, euler_angle.y, euler_angle.z)
      self.look_pos = self.temp_target_trans.position + self.temp_target_trans.forward * star_river_distance
      self._main_camera_y_angle = -progress * self.galaxy_angle * 2
      self.camera_vector = self.look_pos - self.target_pos
      self.companion_star_cam_pos = self.target_pos
      self.target_trans.position = self.target_pos
      self.look_trans.position = self.look_pos
      GameplayUtility.Camera.PopState("FriendStar")
      GameplayUtility.Camera.SetFollowActive("CompanionStar", self.target_trans, self.look_trans)
    end
  end)
end

function companion_star_module:reset_target_pos(galaxy_type)
  self.target_pos = galaxy_type == self.galaxy_type.companion_star and self.companion_star_cam_pos or self.friend_star_cam_pos
  self.target_trans.position = self.target_pos
end

function companion_star_module:calculate_frustum_size(camera, star_distance)
  if not camera then
    return 1
  end
  local fov = camera_fov
  local aspect = camera.aspect
  local fovRad = math.rad(fov)
  local height = 2 * star_distance * math.tan(fovRad / 2)
  local width = height * aspect
  local targetAspect = 1.7777777777777777
  local rectWidth, rectHeight
  if targetAspect < width / height then
    rectHeight = height
    rectWidth = rectHeight * targetAspect
  else
    rectWidth = width
    rectHeight = rectWidth / targetAspect
  end
  return rectWidth, rectHeight, rectWidth / 16
end

function companion_star_module:calculate_loading_target_pos(look_pos, ratio)
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return nil
  end
  local camera_tran = main_cam.transform
  self.temp_target_trans.position = camera_tran.position
  self.temp_target_trans:LookAt(look_pos)
  return camera_tran.position + (look_pos - camera_tran.position) * ratio
end

function companion_star_module:start_to_companion_star_camera()
  GameplayUtility.Camera.SetFollowActive("CompanionStar", self.target_trans, self.look_trans)
end

function companion_star_module:start_to_friend_star_camera()
  GameplayUtility.Camera.SetFollowActive("FriendStar", self.friend_target_trans, self.friend_look_trans)
end

function companion_star_module:exit_companion_star_camera(galaxy_type)
  if galaxy_type == companion_star_module.galaxy_type.friend_star then
    GameplayUtility.Camera.PopState("FriendStar")
  else
    GameplayUtility.Camera.PopState("CompanionStar")
  end
  self:hide_camera_obj()
  self:resume_camera_mask()
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, true)
end

function companion_star_module:set_star_map_camera_mask()
end

function companion_star_module:enter_companion_star_scene()
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  CsEnvironmentSystemManagerUtil.InterruptLerp()
end

function companion_star_module:exit_companion_star_scene()
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  self:resume_camera_mask()
end

function companion_star_module:hide_camera_obj()
  if self.target_dt then
    self.target_dt:Kill()
    self.target_dt = nil
  end
  if self.look_dt then
    self.look_dt:Kill()
    self.look_dt = nil
  end
  if is_null(self.star_river_root) == false then
    for _, galaxy in pairs(self.galaxy_models) do
      UIUtil.set_active(galaxy, false)
    end
  end
  if not_null(self.companion_star_root) then
    UIUtil.set_active(self.companion_star_root, false)
  end
  if not_null(self.enter_particle) then
    UIUtil.set_active(self.enter_particle, false)
  end
end

function companion_star_module:set_camera_mask(...)
  local mask_nums = {
    ...
  }
  local mask = 0
  for _, val in ipairs(mask_nums) do
    local layer = tonumber(val)
    if layer then
      mask = mask | 1 << layer
    end
  end
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  main_cam.cullingMask = mask
end

function companion_star_module:resume_camera_mask()
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  if self._cache_camera_mask then
    main_cam.cullingMask = self._cache_camera_mask
  end
end

function companion_star_module:cache_camera_mask()
  local main_cam = GameplayUtility.Camera.MainCamera
  if not main_cam then
    return
  end
  self._cache_camera_mask = main_cam.cullingMask
end

function companion_star_module:change_camera_state(camera_state)
  local npc_land = CsNPCSphereLandManagerUtil.curStar
  if npc_land and npc_land.Root and camera_state then
    self.cache_camera_state = nil
    npc_land:ChangeCameraState(camera_state)
  else
    self.cache_camera_state = camera_state
  end
end

function companion_star_module:resume_cached_camera_state()
  if self.cache_camera_state then
    local npc_land = CsNPCSphereLandManagerUtil.curStar
    if npc_land and not_null(npc_land.Root) then
      npc_land:ChangeCameraState(self.cache_camera_state)
      self.cache_camera_state = nil
    end
  end
end

function companion_star_module:init_star_river(galaxy_type, galaxy_id, callback)
  galaxy_id = galaxy_id or self:get_first_galaxy_cfg(galaxy_type).starpoolid
  local cfgs = self:get_initial_galaxy_cfgs(galaxy_type, galaxy_id, 1)
  local count = table.count(cfgs)
  if count == 0 then
    Logger.LogWarning("星系进入失败，无法读取到配置")
    callback(false)
    return
  end
  self:_prepare_to_companion_star_camera(galaxy_type, function(success)
    if success then
      local index = 0
      for i, cfg in pairs(cfgs) do
        self:load_galaxy(cfg.assetpath, function(galaxy_obj)
          companion_star_module:put_galaxy_in_the_sky(galaxy_obj, i)
          index = index + 1
          if index == count then
            callback(true)
          end
        end)
      end
    else
      callback(false)
    end
  end)
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, false)
end

function companion_star_module:load_galaxy(path, callback)
  if not self.galaxy_models then
    self.galaxy_models = {}
  end
  if self.galaxy_models[path] then
    callback(self.galaxy_models[path])
    return
  end
  CsUIUtil.LoadPrefabAsync(path, function(go, handle)
    self.galaxy_models[path] = go
    go.transform:SetParent(self.star_river_root)
    table.insert(self._handles, handle)
    callback(go, true)
  end)
end

function companion_star_module:load_friend_galaxy(path, callback)
  if not self.friend_galaxy_model_cache then
    self.friend_galaxy_model_cache = {}
  end
  if #self.friend_galaxy_model_cache > 0 then
    callback(self.friend_galaxy_model_cache[#self.friend_galaxy_model_cache])
    table.remove(self.friend_galaxy_model_cache)
    return
  end
  CsUIUtil.LoadPrefabAsync(path, function(go, handle)
    self.friend_galaxy_model_cache[path] = go
    go.transform:SetParent(self.star_river_root)
    table.insert(self._handles, handle)
    callback(go)
  end)
end

function companion_star_module:recycle_friend_galaxy(obj)
  if not self.friend_galaxy_model_cache then
    self.friend_galaxy_model_cache = {}
  end
  table.insert(self.friend_galaxy_model_cache, obj)
end

function companion_star_module:put_galaxy_in_the_sky(galaxy_obj, index)
  local main_cam = GameplayUtility.Camera.MainCamera
  if is_null(galaxy_obj) or is_null(main_cam) then
    return
  end
  local pos = self:get_galaxy_pos(index)
  if galaxy_obj then
    galaxy_obj.transform.position = pos
    galaxy_obj.transform:LookAt(self.target_pos)
    galaxy_obj.transform:SetLocalScale(self.galaxy_scale, self.galaxy_scale, self.galaxy_scale)
  end
end

function companion_star_module:get_galaxy_pos(progress)
  local angle = -progress * self.galaxy_angle * 2 - self._main_camera_y_angle
  local angleRad = math.rad(angle)
  local cosTheta = math.cos(angleRad)
  local sinTheta = math.sin(angleRad)
  local x = self.camera_vector.x * cosTheta - self.camera_vector.z * sinTheta
  local z = self.camera_vector.x * sinTheta + self.camera_vector.z * cosTheta
  local cameraPosition = self.target_pos
  return cameraPosition + Vector3(x, self.camera_vector.y, z)
end

function companion_star_module:set_look_obj_pos(pos, ratio)
  self.look_trans.position = self:_lerp(self.look_trans.position, pos, ratio)
end

function companion_star_module:set_target_obj_pos(pos, ratio)
  self.target_trans.position = self:_lerp(self.target_trans.position, pos, ratio)
end

function companion_star_module:_lerp(pos1, pos2, t)
  return (1 - t) * pos1 + t * pos2
end

function companion_star_module:play_camera_enter(callback)
  if self.companion_star_ctrl and callback then
    self.companion_star_ctrl:PlayAnimation("CompanionStarCameraEnter", callback)
  end
end

function companion_star_module:play_enter_particle(callback)
  self:_init_obj(function(succeed)
    if succeed then
      UIUtil.set_active(self.enter_particle, false)
      UIUtil.set_active(self.enter_particle, true)
    end
    if callback then
      callback(succeed)
    end
  end)
end

function companion_star_module:exit_particle()
  if self.enter_particle_animation then
    if self.enter_particle_animation.isPlaying then
      self.enter_particle_animation:Stop()
    end
    self.enter_particle_animation:Play("Eff_Ani_StarRiver_NpcStarMapTransition_End")
  end
end

function companion_star_module:set_screen_light_enable()
  if not_null(self.screen_space_setting) then
    self.screen_space_setting:OnPageEnable()
  end
end

function companion_star_module:set_screen_light_disable()
  if not_null(self.screen_space_setting) then
    self.screen_space_setting:OnPageDisable()
  end
end

return companion_star_module
