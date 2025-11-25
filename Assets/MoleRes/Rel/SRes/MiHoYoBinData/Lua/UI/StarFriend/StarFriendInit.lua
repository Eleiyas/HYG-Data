star_friend_module = star_friend_module or {}
star_friend_module._cname = "star_friend_module"
lua_module_mgr:require("UI/StarFriend/StarFriendMain")
local galaxy_scene_path = "Scene/Map/4_UI/SceneMap_404_XingXiYouLin"
local friend_detail_scene_path = "Scene/Map/4_UI/SceneMap_405_HaoYouZhanShi"

function star_friend_module:init()
  self._all_friend_info = nil
  self._handles = {}
  self._available_friend_count = 6
  self._star_friend_galaxy_root = nil
  self._galaxy_scene_obj = nil
  self._star_entities = {}
  self._star_friend_galaxy_cls = nil
  self._camera_target = nil
  self._camera_look = nil
  self._galaxy_tf = nil
  self._star_tfs = {}
  self._info_scene_obj = nil
  self._info_friend_uid = nil
  self._player_entity_guid = nil
  self._info_star_obj = nil
  self._info_star_obj_tbl = {}
  self._player_entity_guid_tbl = {}
  self._info_scene_cls = nil
  self._player_entity_tf = nil
  self._info_camera_target = nil
  self._info_camera_look = nil
  self._info_star_tf = nil
  self._camera_temp_target = nil
  self._camera_temp_look = nil
  self._stand_player = nil
  self.is_far = true
end

function star_friend_module:close()
  self:_clear_galaxy_scene()
  self:_clear_info_scene()
end

function star_friend_module:get_all_friend_info()
  return self._all_friend_info
end

function star_friend_module:init_galaxy_scene(callback)
  if is_null(self._galaxy_scene_obj) then
    Logger.Log("星系友邻 出行页面 加载场景")
    CsUIUtil.LoadPrefabAsync(galaxy_scene_path, function(go, handle)
      if not is_null(go) then
        Logger.Log("星系友邻 出行页面 加载场景成功")
        table.insert(self._handles, handle)
        self._galaxy_scene_obj = go.transform
        local ctrl_comp = UIUtil.find_cmpt(self._galaxy_scene_obj, nil, typeof(CS.miHoYo.HYG.BindingPointTool))
        self:_init_galaxy_attributes(ctrl_comp)
        callback(true)
      else
        Logger.Log("星系友邻 出行页面 加载场景失败")
        callback(false)
        return
      end
    end)
  else
    self._galaxy_scene_obj:SetActive(true)
    callback(true)
  end
end

function star_friend_module:init_info_scene(callback)
  if is_null(self._info_scene_obj) then
    CsUIUtil.LoadPrefabAsync(friend_detail_scene_path, function(go, handle)
      if not is_null(go) then
        table.insert(self._handles, handle)
        self._info_scene_obj = go.transform
        local ctrl_comp = UIUtil.find_cmpt(self._info_scene_obj, nil, typeof(CS.GameModules.CompanionStar.CompanionStarCtrl))
        self:_init_info_attributes(ctrl_comp)
        callback(true)
      else
        callback(false)
        return
      end
    end)
  else
    self._info_scene_obj:SetActive(true)
    callback(true)
  end
end

function star_friend_module:_init_galaxy_attributes(ctrl_comp)
  self._star_friend_galaxy_cls = ctrl_comp
  _, self._star_friend_galaxy_root = ctrl_comp:LuaTryGetBindingPoint("StarRoot")
  self._star_friend_galaxy_root = self._star_friend_galaxy_root.transform
  _, self._camera_target = ctrl_comp:LuaTryGetBindingPoint("CameraPosition")
  self._camera_target = self._camera_target.transform
  _, self._camera_look = ctrl_comp:LuaTryGetBindingPoint("MainStarPosition")
  self._camera_look = self._camera_look.transform
  self._star_tfs = {}
  for i = 1, 6 do
    local is_get, obj = ctrl_comp:LuaTryGetBindingPoint("StarPosition" .. i)
    if is_get then
      table.insert(self._star_tfs, obj.transform)
    end
  end
end

function star_friend_module:_init_info_attributes(ctrl_comp)
  self._info_scene_cls = ctrl_comp
  self._info_camera_target = ctrl_comp.cameraTarget
  self._info_camera_look = ctrl_comp.cameraLook
  self._info_star_tf = ctrl_comp.starRiverRoot
  self._player_entity_tf = ctrl_comp.friendCameraTarget
  self._camera_temp_target = ctrl_comp.cameraTempTarget
  self._camera_temp_look = ctrl_comp.cameraTempLook
  self._stand_player = ctrl_comp.friendCameraLook
end

function star_friend_module:is_galaxy_scene_init()
  return not is_null(self._galaxy_scene_obj) and not is_null(self._star_friend_galaxy_cls) and #self._star_tfs ~= 0
end

function star_friend_module:is_info_scene_init()
  return not is_null(self._info_scene_obj) and not is_null(self._info_scene_cls) and not is_null(self._player_entity_tf) and not is_null(self._info_star_tf)
end

function star_friend_module:_get_all_friend_info()
  if CsFriendPlanetManagerUtil.IsNull() then
    return {}
  end
  local cs_all_friend_info = CsFriendPlanetManagerUtil.GetAllFriendInfo()
  return dic_to_table(cs_all_friend_info)
end

function star_friend_module:_get_all_friend_planet()
  if CsFriendPlanetManagerUtil.IsNull() then
    return
  end
  local cs_all_friend_planet = CsFriendPlanetManagerUtil.GetAllFriendPlanet()
  return dic_to_table(cs_all_friend_planet)
end

function star_friend_module:_clear_galaxy_scene()
  if not is_null(self._galaxy_scene_obj) then
    GameObject.Destroy(self._galaxy_scene_obj.gameObject)
  end
  self._galaxy_scene_obj = nil
end

function star_friend_module:_clear_galaxy_stars()
  if self._star_entities == nil then
    return
  end
  for i, planet_info in pairs(self._star_entities) do
    planet_info:DestroyAll()
  end
  self._star_entities = {}
end

function star_friend_module:_clear_info_scene()
  self:_clear_info_objs()
  if not is_null(self._info_scene_obj) then
    GameObject.Destroy(self._info_scene_obj.gameObject)
  end
end

function star_friend_module:_clear_info_objs()
  self._info_friend_uid = nil
  if self._info_star_obj_tbl ~= nil then
    for _, planet_info in pairs(self._info_star_obj_tbl) do
      planet_info:DestroyAll()
    end
  end
  self._info_star_obj_tbl = {}
  if not is_null(self._player_entity_guid) then
    EntityUtil.destroy_entity_by_guid(self._player_entity_guid)
  end
  self._player_entity_guid = nil
end

return star_friend_module
