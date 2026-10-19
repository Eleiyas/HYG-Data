local M = G.Class("GachaPerformanceControllerPage", G.UIWindow)
local base = G.UIWindow
local CAMERA_BLEND_TIMEOUT = 3

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.page_path.performance_controller
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_Gacha"
  self._new_obtain_panel = nil
  self._result_panel = nil
  self._new_obtain_panel_loaded = false
  self._result_panel_loaded = false
  self._scene_camera_wrapper = nil
  self._camera_anim_completed = false
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnUISceneCameraBlendComplete, pack(self, M._on_camera_blend_complete))
end

function M:on_enable()
  base.on_enable(self)
  self:_init_camera()
  self:add_camera_blend_complete()
  self:_init_camera_state()
  self:_load_panels()
  gacha_module:hide_draw_transition_cover()
end

function M:on_disable()
  base.on_disable(self)
  self:remove_camera_blend_complete()
  self:_clear_camera_timeout()
  self:_close_new_obtain_panel()
  self:_close_result_panel()
  gacha_module:set_is_in_draw_show(false)
  gacha_module:hide_draw_transition_cover()
end

function M:on_close()
  base.on_close(self)
  gacha_module:set_last_draw_rsp_lua(nil)
end

function M:on_destroy()
  self._new_obtain_panel = nil
  self._result_panel = nil
  self._scene_camera_wrapper = nil
  base.on_destroy(self)
end

function M:_load_panels()
  local data = self._extra_data
  if data.performance_type == GachaConst.performance_type.new_obtain or data.performance_type == GachaConst.performance_type.both then
    self:_load_new_obtain_panel()
  end
  if data.performance_type == GachaConst.performance_type.draw_result or data.performance_type == GachaConst.performance_type.both then
    self:_load_result_panel()
  end
end

function M:_on_camera_blend_complete(state_name)
  if self._camera_anim_completed or is_null(self._scene_camera_wrapper) then
    return
  end
  if state_name == GachaConst.draw_performance_camera_mode_name.intro then
    self:_change_camera_state(GachaConst.draw_performance_camera_mode_name.normal)
  elseif state_name == GachaConst.draw_performance_camera_mode_name.normal then
    self._camera_anim_completed = true
    self:_load_panels()
  end
end

function M:_init_camera()
  self._camera_anim_completed = true
  if self._scene_camera_wrapper ~= nil then
    return
  end
  if not_null(self.ui_scene_obj) then
    self._scene_camera_wrapper = UIUtil.find_cmpt(self.ui_scene_obj, GachaConst.draw_scene_camera_path, typeof(CS.MonoHYGCameraWrapper))
  end
end

function M:_init_camera_state()
  if is_null(self._scene_camera_wrapper) then
    return
  end
  local data = self._extra_data
  if data.gacha_id == nil then
    return
  end
  local is_skip_anim = gacha_module:is_skip_anim(data.gacha_id)
  self._camera_anim_completed = is_skip_anim
  if not is_skip_anim then
    self:_change_camera_state(GachaConst.draw_performance_camera_mode_name.intro)
    self._camera_timeout_timer = CsCoroutineManagerUtil.Invoke(CAMERA_BLEND_TIMEOUT, function()
      if self._camera_anim_completed or is_null(self.game_obj) or not self.is_active then
        return
      end
      Logger.LogWarning("[GachaPerformanceControllerPage] camera blend timeout, fallback to no-anim")
      self._camera_anim_completed = true
      self:_load_panels()
    end)
  end
end

function M:_clear_camera_timeout()
  if self._camera_timeout_timer ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._camera_timeout_timer)
    self._camera_timeout_timer = nil
  end
end

function M:_change_camera_state(state)
  if is_null(self._scene_camera_wrapper) then
    return
  end
  self._scene_camera_wrapper:ChangeState(state)
end

function M:add_camera_blend_complete()
  if is_null(self._scene_camera_wrapper) then
    return
  end
  self._scene_camera_wrapper:AddListenerBlendComplete()
end

function M:remove_camera_blend_complete()
  if is_null(self._scene_camera_wrapper) then
    return
  end
  self._scene_camera_wrapper:RemoveListenerBlendComplete()
end

function M:_load_new_obtain_panel()
  if self._new_obtain_panel_loaded then
    self:_show_new_obtain_panel()
    return
  end
  if self._new_obtain_panel ~= nil then
    return
  end
  self._new_obtain_panel_loaded = false
  local lua_class = GachaConst.page_path.cloth_new_obtain
  self._new_obtain_panel = self:add_panel_async(lua_class, nil, self._panel_parent, pack(self, M._on_new_obtain_panel_loaded))
end

function M:_on_new_obtain_panel_loaded(loaded_panel)
  if is_null(loaded_panel) then
    Logger.LogError("[GachaPerformanceControllerPage] load_new_obtain_panel failed: ")
    return
  end
  self._new_obtain_panel_loaded = true
  self._new_obtain_panel = loaded_panel
  if not self.is_active then
    return
  end
  self:_show_new_obtain_panel()
end

function M:_show_new_obtain_panel()
  if not self._camera_anim_completed then
    self:_close_new_obtain_panel()
    return
  end
  if self._new_obtain_panel == nil then
    return
  end
  self._new_obtain_panel:set_extra_data(self._extra_data.new_obtain_data)
  self._new_obtain_panel:change_state(EUIState.Show)
  self._new_obtain_panel:refresh()
end

function M:_close_new_obtain_panel()
  if self._new_obtain_panel == nil then
    return
  end
  self._new_obtain_panel:change_state(EUIState.Hide)
end

function M:_load_result_panel()
  if self._result_panel_loaded then
    self:_set_result_panel_state()
    return
  end
  if self._result_panel ~= nil then
    return
  end
  self._result_panel_loaded = false
  local lua_class = GachaConst.page_path.draw_show_t0
  self._result_panel = self:add_panel_async(lua_class, nil, self._panel_parent, pack(self, M._on_result_panel_loaded))
end

function M:_on_result_panel_loaded(loaded_panel)
  if is_null(loaded_panel) then
    Logger.LogError("[GachaPerformanceControllerPage] load_result_panel failed: ")
    return
  end
  self._result_panel_loaded = true
  self._result_panel = loaded_panel
  if not self.is_active then
    return
  end
  self:_set_result_panel_state()
end

function M:_set_result_panel_state()
  if self._extra_data.performance_type == GachaConst.performance_type.both then
    self:_close_result_panel()
  else
    self:show_result_panel()
  end
end

function M:show_result_panel()
  if not self._camera_anim_completed then
    self:_close_result_panel()
    return
  end
  if self._result_panel == nil then
    return
  end
  self:_close_new_obtain_panel()
  self._result_panel:change_state(EUIState.Show)
  self._result_panel:refresh()
end

function M:_close_result_panel()
  if self._result_panel == nil then
    return
  end
  self._result_panel:change_state(EUIState.Hide)
end

return M
