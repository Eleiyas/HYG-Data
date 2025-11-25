star_friend_social_module = star_friend_social_module or {}
local friend_detail_scene_path = "Scene/Map/4_UI/SceneMap_405_HaoYouZhanShi"

function star_friend_social_module:add_event()
  star_friend_social_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function star_friend_social_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function star_friend_social_module:init_friend_info_scene(callback)
  if is_null(self._info_scene_obj) then
    CsUIUtil.LoadPrefabAsync(friend_detail_scene_path, function(go, handle)
      if not is_null(go) then
        table.insert(self._handles, handle)
        self._info_scene_obj = go.transform
        local ctrl_comp = UIUtil.find_cmpt(self._info_scene_obj, nil, typeof(CS.GameModules.CompanionStar.CompanionStarCtrl))
        self:_init_friend_attributes(ctrl_comp)
        if callback then
          callback(true)
        else
          self:to_star_friend_info_camera()
          self:disable_info_star_sphere()
        end
      else
        if callback then
          callback(false)
        end
        return
      end
    end)
  else
    self._info_scene_obj:SetActive(true)
    if callback then
      callback(true)
    else
      self:disable_info_star_sphere()
    end
  end
end

function star_friend_social_module:_init_friend_attributes(ctrl_comp)
  self._info_scene_cls = ctrl_comp
  self._info_camera_target = ctrl_comp.cameraTarget
  self._info_camera_look = ctrl_comp.cameraLook
  self._info_star_tf = ctrl_comp.starRiverRoot
  self._player_entity_tf = ctrl_comp.friendCameraTarget
  self._camera_temp_target = ctrl_comp.cameraTempTarget
  self._camera_temp_look = ctrl_comp.cameraTempLook
  self._stand_player = ctrl_comp.friendCameraLook
end

function star_friend_social_module:load_friend_star_and_scene(friend_uid)
  star_friend_social_module:init_friend_info_scene(function(success)
    if not success then
      return
    end
    if not is_null(friend_uid) then
      self:update_available_friend_info(friend_uid)
      success = self:create_player_model_and_star(friend_uid)
    end
    if success then
      self:disable_info_star_sphere()
      CsCoroutineManagerUtil.InvokeNextFrame(function()
        self:set_all_sphere_active(false)
      end)
    end
  end)
end

function star_friend_social_module:update_available_friend_info(target_uid)
  local all_friend_info = self:_get_all_friend_info()
  local result = {}
  local index = 1
  if target_uid ~= nil then
    result[target_uid] = all_friend_info[target_uid]
    index = 2
  end
  for uid, info in pairs(all_friend_info) do
    if index <= self._available_friend_count then
      result[uid] = info
      index = index + 1
    end
  end
  self._all_friend_info = result
end

function star_friend_social_module:create_player_model_and_star(player_uid)
  if self._all_friend_info == nil or is_null(self._all_friend_info[player_uid]) then
    return false
  end
  self:_try_get_info_star_obj(player_uid)
  local success = self:_create_player_model_on_info_star(player_uid)
  self._info_friend_uid = player_uid
  if self._is_enter then
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      star_friend_social_module:play_planet_enter_atl()
    end)
    self._is_enter = false
  end
  if not success then
    return false
  end
  return true
end

function star_friend_social_module:reset_planet_transform(planet_guid)
  planet_guid = planet_guid or self._info_star_obj_tbl[self._info_friend_uid].PlanetEntity.Guid
  local position = self._info_star_tf.position
  local rotation = self._info_star_tf.localRotation
  local scale = self._info_star_tf.localScale
  EntityUtil.set_entity_position_by_guid(planet_guid, position.x, position.y, position.z)
end

function star_friend_social_module:_create_player_model_on_info_star(uid)
  if self._info_friend_uid == uid and not is_null(self._player_entity_guid) then
    return true
  end
  if not is_null(self._player_entity_guid) then
    EntityUtil.destroy_entity_by_guid(self._player_entity_guid)
    self._player_entity_guid = nil
  end
  local star_info = self._info_star_obj_tbl[uid]
  if star_info then
    CsFriendPlanetManagerUtil.GeneratePlayerEntityCallback(uid, star_info, self.is_far, function(entity)
      if not is_null(entity) then
        EventCenter.Broadcast(EventID.LuaRemoveBubblePage, nil)
        self._player_entity_guid = entity.Guid
        if star_friend_social_module.is_chat_panel_open then
          self:ste_info_star_distance(false, true, star_info)
        else
          self:ste_info_star_distance(self.is_far, true, star_info)
        end
      end
    end)
  end
  return self._player_entity_guid ~= nil and self._player_entity_guid ~= ""
end

function star_friend_social_module:_try_get_info_star_obj(uid)
  local curr_star_info
  if self._info_friend_uid ~= nil then
    curr_star_info = self._info_star_obj_tbl[self._info_friend_uid]
    if uid == self._info_friend_uid and not_null(curr_star_info) then
      curr_star_info:SetActive(true)
      return
    end
  end
  local position = self.is_far and Vector3(10000, 10000, 10000) or self._info_star_tf.position
  local target_star_info = self._info_star_obj_tbl[uid]
  if not_null(target_star_info) and target_star_info:IsValid() then
    if not_null(curr_star_info) and curr_star_info:IsValid() then
      curr_star_info:SetActive(false)
    end
    target_star_info:SetActive(true)
    local rotation = self._info_star_tf.localRotation
    EntityUtil.set_entity_rotation_by_guid(target_star_info.PlanetEntity.Guid, rotation.x, rotation.y, rotation.z, rotation.w)
    EntityUtil.set_entity_position_by_guid(target_star_info.PlanetEntity.Guid, position.x, position.y, position.z)
    return
  end
  local planet_info = CsFriendPlanetManagerUtil.CreateStaticPlanetEntity(uid, 1, true, position, self._info_star_tf.localRotation, self._info_star_tf.localScale)
  if planet_info:IsValid() then
    if not_null(curr_star_info) and curr_star_info:IsValid() then
      curr_star_info:SetActive(false)
    end
    self._info_star_obj_tbl[uid] = planet_info
  end
end

function star_friend_social_module:ste_info_star_distance(far, direct, star_info)
  local pos = self._info_star_tf.position
  local planet_info = star_info or self._info_star_obj_tbl[self._info_friend_uid]
  if far then
    self:exit_star_friend_near_camera()
    self:to_star_friend_info_camera()
    if not is_null(self._player_entity_guid) then
      CsSocialModuleUtil.SetPerformPlayerATL(self._player_entity_guid, true, direct, self._player_entity_tf.position, self._stand_player.position, planet_info.PlanetEntity.Guid)
    end
  else
    self:exit_star_friend_camera()
    self:to_star_friend_near_camera()
    if not is_null(self._player_entity_guid) then
      CsSocialModuleUtil.SetPerformPlayerATL(self._player_entity_guid, false, direct, self._player_entity_tf.position, self._stand_player.position, planet_info.PlanetEntity.Guid)
    end
    CsFriendPlanetManagerUtil.RotatePlanetTowards(planet_info, self._info_star_tf.localRotation, 1)
  end
end

function star_friend_social_module:exit_star_friend_info_page(do_clear)
  self:exit_star_friend_info_camera()
  if do_clear then
    self:clear_friend_info_scene()
    if self._info_star_obj_tbl ~= nil then
      for _, planet_info in pairs(self._info_star_obj_tbl) do
        planet_info:DestroyAll()
      end
    end
    self._info_star_obj_tbl = {}
    if not is_null(self._info_scene_obj) then
      GameObject.Destroy(self._info_scene_obj.gameObject)
    end
  end
  self._info_scene_obj:SetActive(false)
  self._is_enter = true
end

function star_friend_social_module:clear_friend_info_scene()
  if not is_null(self._player_entity_guid) then
    EntityUtil.destroy_entity_by_guid(self._player_entity_guid)
    star_friend_social_module._player_entity_guid = nil
  end
  if star_friend_social_module.cur_friend_uid > 0 then
    if self._info_star_obj_tbl[star_friend_social_module.cur_friend_uid] then
      self._info_star_obj_tbl[star_friend_social_module.cur_friend_uid]:DestroyAll()
    end
    self._info_star_obj_tbl[star_friend_social_module.cur_friend_uid] = nil
    self._info_friend_uid = nil
    star_friend_social_module:set_cur_friend_uid(-1)
  end
end

function star_friend_social_module:to_star_friend_galaxy_camera()
  GameplayUtility.Camera.SetFollowActive("CompanionStar", self._camera_target, self._camera_look)
end

function star_friend_social_module:to_star_friend_info_camera()
  GameplayUtility.Camera.SetFollowActive("FriendStar", self._info_camera_target, self._info_camera_look)
end

function star_friend_social_module:to_star_friend_near_camera()
  GameplayUtility.Camera.SetFollowActive("FriendStarNear", self._camera_temp_target, self._camera_temp_look)
end

function star_friend_social_module:exit_star_friend_near_camera()
  GameplayUtility.Camera.PopState("FriendStarNear")
end

function star_friend_social_module:exit_star_friend_camera()
  GameplayUtility.Camera.PopState("FriendStar")
end

function star_friend_social_module:exit_star_friend_info_camera()
  GameplayUtility.Camera.PopState("FriendStarNear")
  GameplayUtility.Camera.PopState("FriendStar")
end

function star_friend_social_module:disable_info_star_sphere()
  CsUIUtil.DisableSphere(self._info_scene_obj)
end

function star_friend_social_module:set_all_sphere_active(active)
  CsUIUtil.SetLandSphereActive(active)
end

function star_friend_social_module:rotate_planet(delta_y)
  if not self._info_friend_uid then
    return
  end
  local planet = self._info_star_obj_tbl[self._info_friend_uid]
  if is_null(planet) then
    return
  end
  local is_get, x, y, z, w = EntityUtil.try_get_entity_rotation_by_guid(planet.PlanetEntity.Guid)
  if not is_get then
    return
  end
  local deltaRotation = Quaternion.Euler(0, delta_y, 0)
  local currRotation = Quaternion(x, y, z, w)
  local newRotation = currRotation * deltaRotation
  EntityUtil.set_entity_rotation_by_guid(self._info_star_obj_tbl[self._info_friend_uid].PlanetEntity.Guid, newRotation.x, newRotation.y, newRotation.z, newRotation.w)
end

function star_friend_social_module:play_planet_enter_atl()
  local planetInfo = self._info_star_obj_tbl[self._info_friend_uid]
  if not planetInfo then
    return
  end
  EntityUtil.play_atl_with_tag(planetInfo.PlanetEntity.Guid, ATLTagTags.Tags.atlstate_gameplayentity_none_ui_friendstarenter)
  CsCoroutineManagerUtil.Invoke(0.1, function()
    self:reset_planet_transform(planetInfo.PlanetEntity.Guid)
  end)
end

function star_friend_social_module:play_planet_switch_atl()
  local planetInfo = self._info_star_obj_tbl[self._info_friend_uid]
  if not planetInfo then
    return
  end
  EntityUtil.play_atl_with_tag(planetInfo.PlanetEntity.Guid, ATLTagTags.Tags.atlstate_gameplayentity_none_ui_friendstarswitch)
  CsCoroutineManagerUtil.Invoke(0.15, function()
    self:reset_planet_transform(planetInfo.PlanetEntity.Guid)
  end)
end

return star_friend_social_module
