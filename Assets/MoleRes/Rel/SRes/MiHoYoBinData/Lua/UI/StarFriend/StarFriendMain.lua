star_friend_module = star_friend_module or {}

function star_friend_module:open_star_friend_page()
  InputManagerIns:lock_input(input_lock_from.Common)
  star_friend_module:init_galaxy_scene(function(success)
    if not success then
      EventCenter.Broadcast(EventID.Performance.OnStarFriendPageEnd, nil)
      return
    end
    self._all_friend_info = self:update_available_friend_info()
    success = self:create_galaxy_planets()
    InputManagerIns:unlock_input(input_lock_from.Common)
    if success then
      InputManagerIns:lock_input_while(1.1)
      star_friend_module:to_star_friend_galaxy_camera()
      local data = {
        info = self._all_friend_info,
        planet = self._star_entities
      }
      UIManagerInstance:open("UI/StarFriend/StarFriendPage", data)
    else
      EventCenter.Broadcast(EventID.Performance.OnStarFriendPageEnd, nil)
      self._galaxy_scene_obj:SetActive(false)
    end
  end)
end

function star_friend_module:create_galaxy_planets()
  if not self:is_galaxy_scene_init() then
    return false
  end
  if self._all_friend_info == nil then
    return true
  end
  self:_clear_galaxy_stars()
  local index = 1
  for friend_uid, info in pairs(self._all_friend_info) do
    if index <= #self._star_tfs then
      local planet_info = CsFriendPlanetManagerUtil.CreateStaticPlanetEntity(friend_uid, 2, false, self._star_tfs[index].position, nil, self._star_tfs[index].localScale)
      if not_null(planet_info) and planet_info:IsValid() then
        self._star_entities[friend_uid] = planet_info
        index = index + 1
      else
      end
    end
  end
  return true
end

function star_friend_module:open_star_friend_info_page(friend_uid, delay)
  InputManagerIns:lock_input(input_lock_from.Common)
  star_friend_module.is_far = true
  star_friend_module:init_info_scene(function(success)
    if not success then
      return
    end
    self._all_friend_info = self:update_available_friend_info(friend_uid)
    success = self:create_player_model_and_star(friend_uid)
    InputManagerIns:unlock_input(input_lock_from.Common)
    if success then
      InputManagerIns:lock_input_while(1.1)
      self:to_star_friend_info_camera()
      local data = {
        target_uid = friend_uid,
        info = self._all_friend_info
      }
      if delay ~= nil and 0 < delay then
        CsCoroutineManagerUtil.Invoke(delay, function()
          UIManagerInstance:open("UI/StarFriend/StarFriendInfoPage", data)
        end)
      else
        UIManagerInstance:open("UI/StarFriend/StarFriendInfoPage", data)
      end
    else
      self._info_scene_obj:SetActive(false)
    end
  end)
end

function star_friend_module:exit_star_friend_page()
  self:exit_star_friend_galaxy_camera()
  self:_clear_galaxy_stars()
  self._galaxy_scene_obj:SetActive(false)
end

function star_friend_module:exit_star_friend_info_page(do_clear)
  if not self.is_far then
    self:exit_star_friend_near_camera()
  else
    self:exit_star_friend_info_camera()
  end
  if do_clear then
    self:_clear_info_objs()
  end
  self._info_scene_obj:SetActive(false)
end

function star_friend_module:to_star_friend_galaxy_camera()
  GameplayUtility.Camera.SetFollowActive("CompanionStar", self._camera_target, self._camera_look)
end

function star_friend_module:to_star_friend_info_camera()
  GameplayUtility.Camera.SetFollowActive("FriendStar", self._info_camera_target, self._info_camera_look)
end

function star_friend_module:exit_star_friend_camera()
  GameplayUtility.Camera.PopState("FriendStar")
end

function star_friend_module:to_star_friend_near_camera()
  GameplayUtility.Camera.SetFollowActive("FriendStarNear", self._camera_temp_target, self._camera_temp_look)
end

function star_friend_module:exit_star_friend_near_camera()
  GameplayUtility.Camera.PopState("FriendStarNear")
end

function star_friend_module:exit_star_friend_galaxy_camera()
  GameplayUtility.Camera.PopState("CompanionStar")
end

function star_friend_module:exit_star_friend_info_camera()
  GameplayUtility.Camera.PopState("FriendStar")
end

function star_friend_module:disable_galaxy_sphere()
  CsUIUtil.DisableSphere(self._galaxy_scene_obj)
end

function star_friend_module:disable_info_star_sphere()
  CsUIUtil.DisableSphere(self._info_scene_obj)
end

function star_friend_module:set_all_sphere_active(active)
  CsUIUtil.SetLandSphereActive(active)
end

function star_friend_module:get_player_entity_guid()
  return self._player_entity_guid
end

function star_friend_module:update_available_friend_info(target_uid)
  local all_friend_info = self:_get_all_friend_info()
  local result = {}
  local index = 1
  if target_uid ~= nil and all_friend_info[target_uid] then
    result[target_uid] = all_friend_info[target_uid]
    index = 2
  end
  for uid, info in pairs(all_friend_info) do
    if index <= self._available_friend_count then
      result[uid] = info
      index = index + 1
    end
  end
  return result
end

function star_friend_module:create_player_model_and_star(player_uid)
  if self._all_friend_info == nil or is_null(self._all_friend_info[player_uid]) or not self:is_info_scene_init() then
    return false
  end
  local star_obj_guid = self:_try_get_info_star_obj(player_uid)
  if star_obj_guid == 0 then
    return false
  end
  local success = self:_create_player_model_on_info_star(player_uid)
  if not success then
    return false
  end
  self._info_friend_uid = player_uid
  return true
end

function star_friend_module:ste_info_star_distance(far, direct)
  local pos = self._info_star_tf.position
  local planet_info = self._info_star_obj_tbl[self._info_friend_uid]
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

function star_friend_module:play_planet_enter_atl()
  local planetInfo = self._info_star_obj_tbl[self._info_friend_uid]
  if not planetInfo then
    return
  end
  EntityUtil.play_atl_with_tag(planetInfo.PlanetEntity.Guid, ATLTagTags.Tags.atlstate_gameplayentity_none_ui_friendstarenter)
  CsCoroutineManagerUtil.Invoke(0.1, function()
    self:reset_planet_transform(planetInfo.PlanetEntity.Guid)
  end)
end

function star_friend_module:play_planet_switch_atl()
  local planetInfo = self._info_star_obj_tbl[self._info_friend_uid]
  if not planetInfo then
    return
  end
  EntityUtil.play_atl_with_tag(planetInfo.PlanetEntity.Guid, ATLTagTags.Tags.atlstate_gameplayentity_none_ui_friendstarswitch)
  self:reset_planet_transform(planetInfo.PlanetEntity.Guid)
end

function star_friend_module:rotate_planet(delta_y)
  local is_get, x, y, z, w = EntityUtil.try_get_entity_rotation_by_guid(self._info_star_obj_tbl[self._info_friend_uid].PlanetEntity.Guid)
  if not is_get then
    return
  end
  local deltaRotation = Quaternion.Euler(0, delta_y, 0)
  local currRotation = Quaternion(x, y, z, w)
  local newRotation = currRotation * deltaRotation
  EntityUtil.set_entity_rotation_by_guid(self._info_star_obj_tbl[self._info_friend_uid].PlanetEntity.Guid, newRotation.x, newRotation.y, newRotation.z, newRotation.w)
end

function star_friend_module:_try_get_info_star_obj(uid)
  local curr_star_info
  if self._info_friend_uid ~= nil then
    curr_star_info = self._info_star_obj_tbl[self._info_friend_uid]
    if uid == self._info_friend_uid and not_null(curr_star_info) then
      curr_star_info:SetActive(true)
      return curr_star_info
    end
  end
  local target_star_info = self._info_star_obj_tbl[uid]
  if not_null(target_star_info) and target_star_info:IsValid() then
    if not_null(curr_star_info) and curr_star_info:IsValid() then
      self:reset_planet_transform(curr_star_info.PlanetEntity.Guid)
      curr_star_info:SetActive(false)
    end
    target_star_info:SetActive(true)
    self:reset_planet_transform(target_star_info.PlanetEntity.Guid)
    return target_star_info
  end
  local position = self.is_far and Vector3(10000, 10000, 10000) or self._info_star_tf.position
  local planet_info = CsFriendPlanetManagerUtil.CreateStaticPlanetEntity(uid, 1, true, position, self._info_star_tf.localRotation, self._info_star_tf.localScale)
  if planet_info:IsValid() then
    if not_null(curr_star_info) and curr_star_info:IsValid() then
      self:reset_planet_transform(curr_star_info.PlanetEntity.Guid)
      curr_star_info:SetActive(false)
    end
    self._info_star_obj_tbl[uid] = planet_info
    return planet_info
  end
  return 0
end

function star_friend_module:reset_planet_transform(planet_guid)
  planet_guid = planet_guid or self._info_star_obj_tbl[self._info_friend_uid].PlanetEntity.Guid
  local position = self._info_star_tf.position
  local rotation = self._info_star_tf.localRotation
  local scale = self._info_star_tf.localScale
  EntityUtil.set_entity_position_by_guid(planet_guid, position.x, position.y, position.z)
end

function star_friend_module:_create_player_model_on_info_star(uid)
  if self._info_friend_uid == uid and not is_null(self._player_entity_guid) then
    return true
  end
  if not is_null(self._player_entity_guid) then
    EntityUtil.destroy_entity_by_guid(self._player_entity_guid)
  end
  local atl = self.is_far and ATLTagTags.Tags.atlstate_avatar_default_sit_sitonplanet or ATLTagTags.Tags.atlstate_avatar_basicperform_idle
  self._player_entity_guid = CsFriendPlanetManagerUtil.GeneratePlayerEntity(uid, self._info_star_obj_tbl[uid], self.is_far, atl)
  return self._player_entity_guid ~= 0
end

return star_friend_module
