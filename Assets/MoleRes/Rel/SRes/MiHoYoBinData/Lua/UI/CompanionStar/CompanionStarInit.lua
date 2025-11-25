companion_star_module = companion_star_module or {}
companion_star_module._cname = "companion_star_module"
lua_module_mgr:require("UI/CompanionStar/CompanionStarData")
lua_module_mgr:require("UI/CompanionStar/CompanionStarScene")
lua_module_mgr:require("UI/CompanionStar/CompanionStarMain")
lua_module_mgr:require("UI/CompanionStar/CompanionStarCommon")
local companion_root_path = "SceneObj/Galaxy/CompanionStarRoot"
local screen_space_setting_path = "SceneObj/Galaxy/ScreenSpaceLit"
local enter_particle_path = "Effects/Scene/ResourceStar/Eff_StarRiver_NpcStarMapTransition"
companion_star_module.panel_type = {
  info_panel = 1,
  log_panel = 2,
  star_map_panel = 3,
  growth_panel = 4,
  story_panel = 5,
  aqi_detail_panel = 401,
  growth_eff_panel = 402,
  log_detail_panel = 201
}
companion_star_module.panel_camera = {}
companion_star_module.panel_camera[companion_star_module.panel_type.info_panel] = companion_star_module.camera_state.Particulars
companion_star_module.panel_camera[companion_star_module.panel_type.growth_panel] = companion_star_module.camera_state.ActiveLevel
companion_star_module.panel_camera[companion_star_module.panel_type.log_panel] = companion_star_module.camera_state.NpcLog
companion_star_module.panel_camera[companion_star_module.panel_type.star_map_panel] = companion_star_module.camera_state.StarAtlas
companion_star_module.panel_camera[companion_star_module.panel_type.story_panel] = companion_star_module.camera_state.NpcLike
companion_star_module.galaxy_type = {companion_star = 1, friend_star = 2}
companion_star_module.loading_mode = {enter = 1, exit = 2}
companion_star_module.open_detail_from = {loading = 1, performance = 2}
companion_star_module.friend_count_per_page = 5

function companion_star_module:init()
  self._star_map_cfgs = nil
  self._star_map_names = nil
  self._star_pool_cfgs = nil
  self._npc_tag_pool_cfgs = nil
  self._npc_tag_label_cfgs = nil
  self._star_task_des_cfgs = nil
  self._npc_growth_level_type_cfgs = nil
  self._npc_growth_level_reward_cfgs = nil
  self._npc_story_cfgs = nil
  self._favour_level_cfgs = nil
  self._star_detail_data = nil
  self.galaxy_models = {}
  self.unlocked_npc = {}
  self.galaxy_unlocked_npc = {}
  self._handles = {}
  self.friend_galaxy_model_cache = {}
  companion_star_module:add_event()
end

function companion_star_module:close()
  companion_star_module:remove_event()
  self:hide_camera_obj()
  if is_null(self.companion_star_root) == false then
    GameObject.Destroy(self.companion_star_root)
  end
end

function companion_star_module:clear_on_disconnect()
end

function companion_star_module:on_level_destroy()
  self:reset_on_disconnect()
end

function companion_star_module:reset_on_disconnect()
  self:resume_camera_mask()
  if self._handles then
    for i, handle in ipairs(self._handles) do
      CsUIUtil.DismissResource(handle)
    end
  end
  if not_null(self.companion_star_root) then
    GameObject.Destroy(self.companion_star_root.gameObject)
  end
  if not_null(self.enter_particle) then
    GameObject.Destroy(self.enter_particle)
  end
  if not_null(self.screen_space_setting) then
    GameObject.Destroy(self.screen_space_setting.gameObject)
  end
  self._star_map_cfgs = nil
  self._star_map_names = nil
  self._star_pool_cfgs = nil
  self._npc_tag_pool_cfgs = nil
  self._npc_tag_label_cfgs = nil
  self._star_task_des_cfgs = nil
  self._npc_growth_level_type_cfgs = nil
  self._npc_growth_level_reward_cfgs = nil
  self._npc_story_cfgs = nil
  self._favour_level_cfgs = nil
  self._star_detail_data = nil
  self.galaxy_models = {}
  self._handles = {}
  self.friend_galaxy_model_cache = {}
end

function companion_star_module:_init_obj(callback)
  self.init_obj_callback = callback
  if is_null(self.companion_star_root) and not self.loading_companion_star_root then
    self.loading_companion_star_root = true
    CsUIUtil.LoadPrefabAsync(companion_root_path, function(go, handle)
      self.loading_companion_star_root = false
      if go then
        table.insert(self._handles, handle)
        self.companion_star_root = go.transform
        local ctrl_comp = UIUtil.find_cmpt(self.companion_star_root, nil, typeof(CS.GameModules.CompanionStar.CompanionStarCtrl))
        if not ctrl_comp and not self.camera_animation then
          self:_invoke_init_obj_callback(false)
          return
        end
        self.star_river_root = ctrl_comp.starRiverRoot
        self.companion_target_trans = ctrl_comp.cameraTarget
        self.companion_look_trans = ctrl_comp.cameraLook
        self.friend_target_trans = ctrl_comp.friendCameraTarget
        self.friend_look_trans = ctrl_comp.friendCameraLook
        self.temp_target_trans = ctrl_comp.cameraTempTarget
        self.temp_look_trans = ctrl_comp.cameraTempLook
        self.companion_star_ctrl = ctrl_comp
        self:_invoke_init_obj_callback(true)
      else
        self:_invoke_init_obj_callback(false)
      end
    end)
  elseif self:_invoke_init_obj_callback(true) then
    return
  end
  if self:_invoke_init_obj_callback(true) then
    return
  end
end

function companion_star_module:_invoke_init_obj_callback(result)
  if result then
    if self:_check_obj() and self.init_obj_callback then
      self.init_obj_callback(true)
      self.init_obj_callback = nil
      return true
    end
    return false
  else
    self.init_obj_callback(false)
    self.init_obj_callback = nil
  end
end

function companion_star_module:_check_obj()
  return is_null(self.companion_star_root) == false
end

function companion_star_module:_init_screen_setting_obj(callback)
  if is_null(self.screen_space_setting) and not self.loading_screen_space_setting then
    self.loading_screen_space_setting = true
    CsUIUtil.LoadPrefabAsync(screen_space_setting_path, function(go, handle)
      self.loading_screen_space_setting = false
      if go then
        table.insert(self._handles, handle)
        self.screen_space_setting = UIUtil.find_cmpt(go, nil, typeof(CS.GameModules.CompanionStar.ScreenSpaceLightSetting))
        if not self.screen_space_setting then
          if callback then
            callback(false)
          end
          return
        end
        if callback then
          callback(true)
        end
      elseif callback then
        callback(false)
      end
    end)
  elseif callback and not_null(self.screen_space_setting) then
    callback(true)
  end
end

return companion_star_module
