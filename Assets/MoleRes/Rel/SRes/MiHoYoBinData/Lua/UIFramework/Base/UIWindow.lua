EUIType = {
  Scene = 2,
  BackgroundBoard = 3,
  Page = 4,
  Dialog = 5,
  Info = 6,
  Tip = 7,
  Top = 8
}
EUIState = {
  Prepare = 1,
  Ready = 2,
  Show = 3,
  Hide = 4,
  Destroy = 5
}
EUIMask = {
  None = 1,
  BlackScreen = 2,
  ScreenCapture = 3
}
EUIInputStackLevel = {
  high = 1,
  middle = 2,
  low = 3
}
local M = G.Class("UIWindow", G.UIPanel)
local base = G.UIPanel

function M:__ctor()
  self.config = {
    prefab_path = "",
    scene_prefab_path = "",
    env_profile_path = "",
    type = EUIType.Page,
    order_in_layer = 0,
    mask_type = EUIMask.None,
    is_singleton = true,
    input_penetrate = false,
    input_stack_level = EUIInputStackLevel.low,
    player_ctrl_cfg = nil,
    input_lock_type = input_lock_type.none,
    destroy_when_light_refresh = true,
    input_action_cfg = {use_penetrating_actions = false, penetrating_actions = nil},
    ability_name = "",
    auto_ability = true
  }
  self.full_class_name = nil
  self.full_class_name_hash = nil
  self.class_name = self.__cname
  self.guid = nil
  self.ui_scene_root = nil
  self.ui_scene_obj = nil
  self._input_actions_dirty = false
  self._open_sfx_list = nil
  self._close_sfx_list = nil
  self._audio_page_style = 0
  self._sfx_init = false
  self._page_audio = nil
  self._loading_count = 0
  self._state = nil
  self._next_state = nil
  self._bgm_handle = 0
end

function M:on_prepare()
  self:load_prefab_async(self.config.prefab_path, function(go)
    if self._state == EUIState.Destroy then
      UIUtil.destroy_go(go)
      return
    end
    local trans = go.transform
    trans:SetParent(self.parent_trans, false)
    trans:SetLocalPosition(0, 0, 0)
    trans:SetLocalScale(1, 1, 1)
    self:set_gameobject(go)
    self.is_active = false
  end, nil, false)
  if string.is_valid(self.config.scene_prefab_path) then
    self:load_prefab_async(self.config.scene_prefab_path, function(go)
      local trans = go.transform
      trans:SetLocalPosition(0, 0, 0)
      self.ui_scene_obj = go
    end, self.ui_scene_root, false)
  end
end

function M:loading_finish()
  if self._loading_count == 0 then
    return true
  end
  return false
end

function M:is_ready()
  return self._state >= EUIState.Ready
end

function M:is_destroy()
  return self._state >= EUIState.Destroy
end

function M:check_next_state()
  if self._next_state ~= nil and self._state ~= self._next_state then
    self:change_state(self._next_state)
  end
  if self._next_state == self._state then
    self._next_state = nil
  end
end

function M:change_state(state)
  if self._state == EUIState.Destroy then
    Logger.LogError(self.full_class_name .. "已经Destroy,不可改变状态!")
    return
  end
  if self._state == EUIState.Prepare and state ~= EUIState.Ready then
    self._next_state = state
    return
  end
  if self:is_play_anim() then
    self._next_state = state
    return
  end
  self._state = state
  if state == EUIState.Prepare then
    self:on_prepare()
  elseif state == EUIState.Ready then
    self:on_create()
  elseif state == EUIState.Show then
    self:set_active(true)
  elseif state == EUIState.Hide then
    self:on_before_close()
    self:set_active(false)
  elseif state == EUIState.Destroy then
    self:Delete()
  end
end

function M:load_prefab_async(path, callback, parent, active)
  local prefab_load_proxy = self:get_prefab_load_proxy()
  self._loading_count = self._loading_count + 1
  local load_cb = callback
  if load_cb == nil then
    Logger.LogError("callback can`t be nil," .. path)
    return
  end
  prefab_load_proxy:LoadPrefabAsync(path, function(go)
    self._loading_count = self._loading_count - 1
    if is_null(go) then
      Logger.LogError("load prefab is null," .. path)
      return
    end
    if self._loading_count < 0 then
      Logger.LogError("_loading_count < 0," .. path)
    end
    load_cb(go)
  end, parent, active)
end

function M:set_ui_culling(ui_trans, fix_scale)
  self._trans_ui_culling = ui_trans
  self._fix_scale_ui_culling = fix_scale
end

function M:on_enable()
  base.on_enable(self)
  self:_enter_ui_scene()
  if self.config.player_ctrl_cfg then
    local camera_ctrl = self.config.player_ctrl_cfg.ctrl_cfg.camera
    InputManagerIns:set_mouse_active(not camera_ctrl)
  else
    InputManagerIns:set_mouse_active(true)
  end
  CsUIUtil.OnOpenLuaUI(self.class_name, true)
  self:play_open_sfx()
  if self.config.type == EUIType.Page or self.config.type == EUIType.Tip then
    self:_set_audio_page_style()
  end
  if self.config.auto_ability and self:can_start_ability() then
    self:start_ability()
  end
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
  if not_null(self._trans_ui_culling) then
    UIManagerInstance:set_ui_culling(self._trans_ui_culling, self._fix_scale_ui_culling)
  end
end

function M:set_active(active)
  if active then
    self.trans:SetAsLastSibling()
  end
  base.set_active(self, active)
  if not active then
    self:play_close_sfx()
    self:resume_page_bgm()
    if not_null(self._trans_ui_culling) then
      UIManagerInstance:set_ui_culling(nil)
    end
  else
    self:play_page_bgm()
  end
end

function M:_enter_ui_scene()
  if not is_null(self.ui_scene_obj) then
    UIUtil.set_active(self.ui_scene_obj, true)
    CsUISceneManagerUtil.EnterUIScene(self.ui_scene_root.gameObject, self.config.env_profile_path)
  end
end

function M:_exit_ui_scene()
  if not is_null(self.ui_scene_obj) then
    UIUtil.set_active(self.ui_scene_obj, false)
    CsUISceneManagerUtil.ExitUIScene()
  end
end

function M:bind_close_btn(btn_close, dont_bind_back_action)
  if is_null(btn_close) then
    return
  end
  self:bind_callback(btn_close, pack(self, self.close_self))
  if not dont_bind_back_action then
    self:bind_input_and_btn(ActionType.Act.Back, btn_close)
  end
end

function M:has_open_sfx()
  self:_init_page_audio()
  if is_null(self._page_audio) then
    return false
  end
  return self._open_sfx_list and self._open_sfx_list.Count and self._open_sfx_list.Count > 0
end

function M:has_page_bgm()
  self:_init_page_audio()
  if is_null(self._page_audio) then
    return false
  end
  return self._page_audio and self._page_audio:HasBGM()
end

function M:_init_page_audio()
  if is_null(self._page_audio) and not self._sfx_init then
    local page_audio_configs = CsAssetConfigManagerUtil.uiPageAudioConfig
    local prefab_name = self:_get_prefab_name()
    if page_audio_configs and string.is_valid(prefab_name) then
      self._page_audio = page_audio_configs:GetPageAudioConfig(prefab_name, false)
      if not is_null(self._page_audio) then
        self._open_sfx_list = self._page_audio.opens
        self._open_sfx_priority = self._page_audio.openPriority
        self._close_sfx_list = self._page_audio.closes
        self._close_sfx_priority = self._page_audio.closePriority
        self._audio_page_style = self._page_audio.pageStyle
      end
    end
  end
  self._sfx_init = true
end

function M:_get_prefab_name()
  if string.is_valid(self.config.prefab_path) then
    local strs = lua_str_split(self.config.prefab_path, "/")
    if 0 < #strs then
      return strs[#strs]
    end
  end
  return nil
end

function M:_set_audio_page_style()
  if WType.state.stategroup_ui_screenDucking and self._audio_page_style ~= 0 and self._audio_page_style ~= WType.state.stategroup_ui_screenDucking.None then
    AudioManagerIns:set_state(WType.state.stategroup_ui_screenDucking.GroupID, self._audio_page_style)
  end
end

function M:play_open_sfx()
  if not is_null(self._page_audio) and self._open_sfx_list and self._open_sfx_list.Count and self._open_sfx_list.Count > 0 then
    local iter = self._open_sfx_list:GetEnumerator()
    while iter:MoveNext() do
      if iter.Current.value__ ~= WType.event.None then
        AudioManagerIns:play_sfx(iter.Current, self._open_sfx_priority)
      end
    end
  end
end

function M:play_close_sfx()
  if not is_null(self._page_audio) and self._close_sfx_list and self._close_sfx_list.Count and self._close_sfx_list.Count > 0 then
    local iter = self._close_sfx_list:GetEnumerator()
    while iter:MoveNext() do
      if iter.Current.value__ ~= WType.event.None then
        AudioManagerIns:play_sfx(iter.Current, self._close_sfx_priority)
      end
    end
  end
end

function M:play_page_bgm()
  if not is_null(self._page_audio) and self._page_audio and self._page_audio:HasBGM() then
    self._bgm_handle = CsBGMManagerUtil.SetUIBGM(BGMLayer.UI, self._page_audio)
  end
end

function M:resume_page_bgm()
  if self:has_page_bgm() then
    CsBGMManagerUtil.ResumeBGM(self._bgm_handle)
    self._bgm_handle = 0
  end
end

function M:on_before_close()
end

function M:on_disable()
  base.on_disable(self)
  self:_exit_ui_scene()
  CsUIUtil.OnOpenLuaUI(self.class_name, false)
  if self.config.input_lock_type ~= input_lock_type.none then
    InputManagerIns:unlock_3C(self)
  end
  if self.config.auto_ability then
    self:stop_ability()
  end
end

function M:on_level_prepare()
end

function M:on_level_destroy()
end

function M:close_self()
  UIManagerInstance:close(self.guid)
end

function M:add_panel(content, trans, extra_data, handle)
  local panel = base.add_panel(self, content, trans, extra_data, handle)
  self:set_dirty(panel)
  return panel
end

function M:remove_panel(instance)
  base.remove_panel(self, instance)
  self:set_dirty(instance)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:handle_input_action(action)
  if action then
    for _, panel in pairs(self.container) do
      if not action.handled and panel.handle_input_action and panel.is_active then
        panel:handle_input_action(action)
        if panel.config.input_penetrate == false then
          return
        end
      end
    end
    if not action.handled then
      base.handle_input_action(self, action)
    end
  end
end

function M:handle_back(action)
  self:close_self()
  action.handled = true
end

function M:get_all_input_actions()
  if self._input_actions_dirty then
    for _, panel in pairs(self.container) do
      local actions = panel.input_actions
      if actions then
        for _, val in pairs(actions) do
          self.input_actions[val.id] = val
        end
      end
    end
    self._input_actions_dirty = false
  end
  return self.input_actions
end

function M:set_penetrate_actions(actions)
  if not self.config.input_action_cfg.penetrating_actions then
    self.config.input_action_cfg.penetrating_actions = {}
  else
    table.clear(self.config.input_action_cfg.penetrating_actions)
  end
  self.config.input_action_cfg.use_penetrating_actions = true
  if actions then
    for _, action in ipairs(actions) do
      if action and action ~= 0 then
        self.config.input_action_cfg.penetrating_actions[action] = 1
      end
    end
  end
end

function M:clear_penetrate_actions()
  self.config.input_action_cfg.use_penetrating_actions = false
  self.config.input_action_cfg.penetrating_actions = nil
end

function M:set_dirty(panel)
  if panel.input_actions and #panel.input_actions ~= 0 then
    self._input_actions_dirty = true
  end
end

function M:check_3c_validate()
  return GameplayUtility.Player.UIDefaultValidatePlayerStates()
end

function M:reset_state()
end

function M:can_start_ability()
  if string.is_valid(self.config.ability_name) then
    return EntityUtil.can_activate_ui_ability(self.config.ability_name)
  else
    return false
  end
end

function M:start_ability()
  if string.is_valid(self.config.ability_name) then
    EntityUtil.start_ui_ability(self.config.ability_name)
  end
end

function M:stop_ability()
  if string.is_valid(self.config.ability_name) then
    EntityUtil.stop_ui_ability(self.config.ability_name)
  end
end

return M
