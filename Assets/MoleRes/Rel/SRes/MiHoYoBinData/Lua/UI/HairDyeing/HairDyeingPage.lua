local M = G.Class("HairDyeingPage", G.UIWindow)
local base = G.UIWindow
local PANEL_CLASS = {
  mode_select = "UI/HairDyeing/HairDyeingModeSelectPanel",
  flower = "UI/HairDyeing/HairDyeingFlowerPanel",
  dye = "UI/HairDyeing/HairDyeingDyePanel",
  exchange = "UI/HairDyeing/HairDyeingExchangePanel"
}
local result_panel_cls = "UI/HairDyeing/HairDyeingResultPanel"
local placeholder_scene_path = "Scene/Map/4_UI/SceneMap_UI_HairDyeing"
local temp_player_owner = appearance_module.temp_player_owner and appearance_module.temp_player_owner.hair_dyeing or "hair_dyeing"
local appearance_return_sync_delay = 0.3
local panel_action_replay_delay = 0.15
local panel_action_retry_max = 40
local hidden_headwear_part_ids = {15}
local background_ramp_value = {default = 0, exchange = 0.5}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/HairDyeing/HairDyeingPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = placeholder_scene_path
  self._cur_cam_state = ""
  self._follow_target = nil
  self._look_target = nil
  self._player_root = nil
  self._cur_mode = nil
  self._cur_euler_y = 0
  self._panels = {}
  self._cur_panel_key = nil
  self._exchange_back_key = nil
  self._appearance_return_panel_key = nil
  self._mode_select_bound = false
  self._appearance_return_sync_co = nil
  self._panel_action_delay_co = nil
  self._page_close_broadcasted = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._page_close_broadcasted = false
  local appearance_return_panel_key = self._appearance_return_panel_key
  self._appearance_return_panel_key = nil
  self:_refresh_scene_root()
  local panel_key = self._cur_panel_key or "mode_select"
  self:_refresh_cam(panel_key, appearance_return_panel_key ~= nil)
  self:_refresh_background(panel_key)
  hair_dyeing_module:sync_cur_style_id_from_appearance()
  self:_refresh_temp_player()
  if appearance_return_panel_key ~= nil then
    self:_restore_panel_after_appearance(appearance_return_panel_key)
  else
    self:show_mode_select()
  end
  local need_refresh = hair_dyeing_module:consume_need_refresh_from_appearance()
  if need_refresh and appearance_return_panel_key ~= "exchange" then
    self:_schedule_appearance_return_sync()
  end
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:on_disable()
  local is_appearance_transition = self._appearance_return_panel_key ~= nil
  if not is_appearance_transition then
    self:_broadcast_page_close()
    CsDyeingModuleUtil.ClearHairDyeingEnvCache()
  end
  base.on_disable(self)
  self:_stop_panel_action_delay()
  self:_stop_appearance_return_sync()
  if not is_appearance_transition then
    for _, panel in pairs(self._panels or {}) do
      if panel ~= nil and panel.clear_dye_session_state then
        panel:clear_dye_session_state()
      end
    end
  end
  appearance_module:destroy_temp_player(temp_player_owner)
  if string.is_valid(self._cur_cam_state) then
    CsGameplayUtilitiesCameraUtil.PopState(self._cur_cam_state)
  end
  self._cur_cam_state = ""
  hair_dyeing_module:clear_dye_session()
end

function M:on_destroy()
  self:_broadcast_page_close()
  CsDyeingModuleUtil.ClearHairDyeingEnvCache()
  base.on_destroy(self)
end

function M:close_self()
  self:_broadcast_page_close()
  base.close_self(self)
end

function M:_broadcast_page_close()
  if self._page_close_broadcasted then
    return
  end
  self._page_close_broadcasted = true
  EventCenter.Broadcast(EventID.LuaHairDyeingPageClose)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._handle_back_input)
end

function M:_switch_panel(key, on_ready)
  if is_null(self._trans_panel_parent) then
    Logger.LogError("[HairDyeingPage] _trans_panel_parent 未绑定，无法挂载子面板")
    return
  end
  local prev_key = self._cur_panel_key
  if prev_key ~= nil and prev_key ~= key then
    self:_clear_panel_color_preview(prev_key)
  end
  self._cur_panel_key = key
  
  local function reveal(panel)
    panel:change_state(EUIState.Show)
    self:_reset_player_rotation()
    self:_refresh_cam(key)
    self:_play_panel_action(key)
    self:_refresh_background(key)
    if prev_key ~= nil and prev_key ~= key then
      local prev_panel = self._panels[prev_key]
      if prev_panel ~= nil then
        prev_panel:change_state(EUIState.Hide)
      end
      CsDyeingModuleUtil.RefreshHairDyeTempPlayerColor()
    end
    if on_ready then
      on_ready(panel)
    end
  end
  
  local panel = self._panels[key]
  if panel ~= nil then
    reveal(panel)
    return
  end
  self._panels[key] = self:add_panel_async(PANEL_CLASS[key], nil, self._trans_panel_parent, reveal)
end

function M:_refresh_background(panel_key)
  local ramp_value = (panel_key == "exchange" or panel_key == "mode_select") and background_ramp_value.exchange or background_ramp_value.default
  CsDyeingModuleUtil.SetHairDyeingBackgroundRamp(ramp_value)
end

function M:_hide_result()
  if self._result_panel ~= nil then
    self._result_panel:change_state(EUIState.Hide)
  end
end

function M:show_mode_select()
  self._cur_mode = nil
  hair_dyeing_module:stop_region_brightness_pulse()
  self:_switch_panel("mode_select", function(panel)
    if not self._mode_select_bound then
      self._mode_select_bound = true
      panel:set_on_mode_selected(function(mode)
        self:enter_mode(mode)
      end)
      panel:set_on_close(function()
        self:close_self()
      end)
    end
  end)
  self:_hide_result()
end

function M:enter_mode(mode)
  if mode == hair_dyeing_module.dye_mode.dye and not hair_dyeing_module:has_gradient_region() then
    UIUtil.show_tips_by_text_id("HairDyeing_UI_Tips1")
    return
  end
  self._cur_mode = mode
  hair_dyeing_module._cur_dye_mode = mode
  local panel_key = mode == hair_dyeing_module.dye_mode.flower and "flower" or "dye"
  self:_switch_panel(panel_key, function(panel)
    panel:set_on_back(function()
      self:show_mode_select()
    end)
    if panel_key == "dye" and panel.set_on_exchange then
      panel:set_on_exchange(function(entry_data)
        self:show_exchange(entry_data)
      end)
    end
    if panel.set_on_haircut then
      panel:set_on_haircut(function()
        self:_open_appearance_from_panel(panel_key)
      end)
    end
    panel:refresh()
  end)
  self:_hide_result()
end

function M:show_exchange(entry_data)
  local from_key = self._cur_panel_key
  if from_key == "exchange" then
    from_key = self._exchange_back_key
  end
  self._exchange_back_key = from_key or "dye"
  entry_data = entry_data or {}
  if entry_data.style_id then
    hair_dyeing_module:set_cur_style_id(entry_data.style_id)
  end
  entry_data.from_key = self._exchange_back_key
  self:_switch_panel("exchange", function(panel)
    panel:set_on_back(function()
      self:_back_from_exchange()
    end)
    panel:set_on_haircut(function()
      self:_open_appearance_from_panel("exchange")
    end)
    panel:refresh(entry_data)
  end)
  self:_hide_result()
end

function M:_back_from_exchange()
  local back_key = self._exchange_back_key or "dye"
  self._exchange_back_key = nil
  self:_switch_panel(back_key)
  self:_apply_panel_region_pulse(back_key)
  self:_hide_result()
end

function M:_clear_panel_color_preview(panel_key)
  local panel = self._panels[panel_key]
  if panel ~= nil and panel.clear_color_preview then
    panel:clear_color_preview()
  end
end

function M:_open_appearance_from_panel(panel_key)
  self._appearance_return_panel_key = panel_key
  self:_clear_panel_color_preview(panel_key)
  self:_reset_player_rotation()
  appearance_module:open_appearance_page_with_preset({
    type = appearance_module.tab_type.dress,
    preset_attrib_type = appearance_module.appearance_attrib_type.hair_style,
    from_hair_dyeing = true
  })
end

function M:_restore_panel_after_appearance(panel_key)
  if panel_key == "exchange" then
    local panel = self._panels[panel_key]
    if panel ~= nil then
      panel:change_state(EUIState.Hide)
    end
    self:_schedule_appearance_return_sync(panel_key)
    return
  end
  local mode = panel_key == "flower" and hair_dyeing_module.dye_mode.flower or panel_key == "dye" and hair_dyeing_module.dye_mode.dye or nil
  if mode == nil then
    self:show_mode_select()
    return
  end
  self._cur_mode = mode
  hair_dyeing_module._cur_dye_mode = mode
  if self._panels[panel_key] ~= nil then
    self:_switch_panel(panel_key)
    self:_apply_panel_region_pulse(panel_key)
  else
    self:enter_mode(mode)
  end
  self:_hide_result()
end

function M:_apply_panel_region_pulse(panel_key)
  local panel = self._panels[panel_key]
  if panel ~= nil and panel.apply_region_brightness_pulse then
    panel:apply_region_brightness_pulse()
  end
end

function M:show_result()
  local source_panel_key = self._cur_panel_key
  local source_panel = self._panels[source_panel_key]
  
  local function reveal(panel)
    if not (not is_null(self.game_obj) and self.is_active) or self._cur_panel_key ~= source_panel_key then
      panel:change_state(EUIState.Hide)
      return
    end
    panel:set_on_close(function()
      if self.is_active and self._cur_panel_key == source_panel_key and source_panel ~= nil then
        source_panel:change_state(EUIState.Show)
        self:_apply_panel_region_pulse(source_panel_key)
      end
      self:_hide_result()
    end)
    panel:change_state(EUIState.Show)
    if source_panel ~= nil then
      source_panel:change_state(EUIState.Hide)
    end
  end
  
  if self._result_panel ~= nil then
    reveal(self._result_panel)
    return
  end
  self._result_panel = self:add_panel_async(result_panel_cls, nil, self._trans_panel_parent, reveal)
end

function M:_refresh_scene_root()
  CsDyeingModuleUtil.InitHairDyeingEnv(self.ui_scene_obj.transform)
  self._follow_target = UIUtil.find_trans(self.ui_scene_obj, "Art/FollowTarget")
  self._look_target = UIUtil.find_trans(self.ui_scene_obj, "Art/LookTarget")
  self._player_root = UIUtil.find_trans(self.ui_scene_obj, "Art/PlayerRoot")
end

function M:_refresh_cam(panel_key, force)
  local new_state = hair_dyeing_module.cam_state[panel_key] or hair_dyeing_module.cam_state.mode_select
  if not force and self._cur_cam_state == new_state then
    return
  end
  if string.is_valid(self._cur_cam_state) then
    CsGameplayUtilitiesCameraUtil.PopState(self._cur_cam_state)
  end
  self._cur_cam_state = new_state
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform(self._cur_cam_state, self._follow_target, self._look_target)
end

function M:_play_panel_action(panel_key)
  if not CsAppearanceManagerUtil.IsTempPlayerDressUpReady() then
    self:_schedule_panel_action(panel_key)
    return
  end
  local cfg = hair_dyeing_module:get_tab_cfg(panel_key)
  local display_tag = cfg and cfg.atl or ""
  if not string.is_valid(display_tag) or display_tag == "null" then
    display_tag = ""
  end
  appearance_module:play_dress_up_pose(display_tag, "ATLState_Avatar_BasicPerform_IdleAction")
end

function M:_stop_panel_action_delay()
  if self._panel_action_delay_co ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._panel_action_delay_co)
    self._panel_action_delay_co = nil
  end
end

function M:_schedule_panel_action(panel_key, retry_left)
  self:_stop_panel_action_delay()
  retry_left = retry_left or panel_action_retry_max
  if retry_left <= 0 then
    return
  end
  self._panel_action_delay_co = CsCoroutineManagerUtil.Invoke(panel_action_replay_delay, function()
    self._panel_action_delay_co = nil
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    local key = panel_key or self._cur_panel_key
    if key == nil or key ~= self._cur_panel_key then
      return
    end
    if not CsAppearanceManagerUtil.IsTempPlayerDressUpReady() then
      self:_schedule_panel_action(key, retry_left - 1)
      return
    end
    self:_play_panel_action(key)
  end)
end

function M:_refresh_temp_player()
  self:_stop_panel_action_delay()
  self:_reset_player_rotation()
  appearance_module:create_temp_player(self._player_root, temp_player_owner)
  CsAppearanceManagerUtil.SetOnTempPlayerReadyCallback(function()
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    appearance_module:set_cloth_show_state_by_part_ids(hidden_headwear_part_ids, false)
    self:_schedule_panel_action()
  end)
end

function M:_refresh_cur_workspace_panel(is_appearance_return)
  local panel_key = self._cur_panel_key
  if panel_key ~= "flower" and panel_key ~= "dye" and panel_key ~= "exchange" then
    return
  end
  local panel = self._panels[panel_key]
  if panel_key == "exchange" and is_appearance_return and panel ~= nil and panel.refresh_after_appearance then
    panel:refresh_after_appearance()
  elseif panel ~= nil and panel.refresh then
    panel:refresh()
  end
end

function M:_refresh_dyeable_state()
  local panel = self._panels[self._cur_panel_key]
  if panel ~= nil and panel.refresh_dyeable_state then
    panel:refresh_dyeable_state()
  end
end

function M:_stop_appearance_return_sync()
  if self._appearance_return_sync_co ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._appearance_return_sync_co)
    self._appearance_return_sync_co = nil
  end
end

function M:_schedule_appearance_return_sync(panel_key_to_restore)
  self:_stop_appearance_return_sync()
  self._appearance_return_sync_co = CsCoroutineManagerUtil.Invoke(appearance_return_sync_delay, function()
    self._appearance_return_sync_co = nil
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    local style_id = hair_dyeing_module:sync_cur_style_id_from_appearance()
    if style_id ~= nil and 0 < style_id then
      appearance_module:active_attrib_by_id(style_id)
      CsDyeingModuleUtil.RefreshHairDyeTempPlayerColor()
    end
    appearance_module:set_cloth_show_state_by_part_ids(hidden_headwear_part_ids, false)
    self:_refresh_cur_workspace_panel(true)
    if panel_key_to_restore ~= nil then
      if self._cur_panel_key ~= panel_key_to_restore then
        return
      end
      self:_switch_panel(panel_key_to_restore)
      self:_apply_panel_region_pulse(panel_key_to_restore)
      self:_hide_result()
    elseif self._cur_panel_key ~= nil then
      self:_refresh_background(self._cur_panel_key)
      self:_play_panel_action(self._cur_panel_key)
    end
  end)
end

function M:_add_ui_listener()
  self.binder:BindViewCallback(self._trans_model_area, EventTriggerType.Drag, pack(self, M._on_drag))
end

function M:_handle_back_input(action)
  if self._cur_panel_key == "exchange" then
    self:_back_from_exchange()
    return
  end
  if self._cur_mode ~= nil then
    self:show_mode_select()
    return
  end
  self:close_self()
end

function M:_on_drag(evt)
  local delta_x = evt.delta.x
  self._cur_euler_y = self._cur_euler_y - delta_x * hair_dyeing_module.rotate_speed
  appearance_module:update_player_euler_angles_y(self._cur_euler_y)
end

function M:_reset_player_rotation()
  self._cur_euler_y = 0
  appearance_module:update_player_euler_angles_y(0)
end

return M
