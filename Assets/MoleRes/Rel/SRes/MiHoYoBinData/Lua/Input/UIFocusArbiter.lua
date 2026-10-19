ui_focus_arbiter = ui_focus_arbiter or {}
local main_page_class_name = "UI/MainPage/MainPage"

function ui_focus_arbiter:begin_frame()
  self._frame_owner = self._owner
  self._frame_focus_bypassed_actions = self._focus_bypassed_actions
end

function ui_focus_arbiter:_get_main_page()
  local main_page = UIManagerInstance:get_window_by_class(main_page_class_name)
  if main_page == nil then
    return nil
  end
  if main_page.set_player_ctrl_cfg == nil then
    return nil
  end
  if main_page.config == nil or main_page.config.player_ctrl_cfg == nil or main_page.config.player_ctrl_cfg.ctrl_cfg == nil then
    return nil
  end
  return main_page
end

function ui_focus_arbiter:_disable_3c_ability()
  self._is_3c_saved = false
  self._saved_3c = nil
  local main_page = self:_get_main_page()
  if main_page == nil then
    return
  end
  local ctrl_cfg = main_page.config.player_ctrl_cfg.ctrl_cfg
  self._saved_3c = ctrl_cfg.ability
  self._is_3c_saved = true
  main_page:set_player_ctrl_cfg(ctrl_cfg.move, ctrl_cfg.camera, false)
end

function ui_focus_arbiter:_restore_3c_ability()
  if not self._is_3c_saved then
    return
  end
  local saved = self._saved_3c
  self._is_3c_saved = false
  self._saved_3c = nil
  local main_page = self:_get_main_page()
  if main_page == nil then
    return
  end
  local ctrl_cfg = main_page.config.player_ctrl_cfg.ctrl_cfg
  main_page:set_player_ctrl_cfg(ctrl_cfg.move, ctrl_cfg.camera, saved)
end

function ui_focus_arbiter:_grant(panel, set_focus_func, focus_bypassed_actions)
  self._owner = panel
  self._focus_bypassed_actions = focus_bypassed_actions
  self._is_penetrate_saved = false
  self._saved_penetrate = nil
  if panel.config ~= nil then
    self._saved_penetrate = panel.config.input_penetrate
    self._is_penetrate_saved = true
    panel.config.input_penetrate = false
  end
  self:_disable_3c_ability()
  if set_focus_func ~= nil then
    set_focus_func(true)
  end
end

function ui_focus_arbiter:_revoke()
  local panel = self._owner
  self._owner = nil
  self._focus_bypassed_actions = nil
  self:_restore_3c_ability()
  if self._is_penetrate_saved then
    self._is_penetrate_saved = false
    if panel ~= nil and panel.config ~= nil then
      panel.config.input_penetrate = self._saved_penetrate
    end
    self._saved_penetrate = nil
  end
  if panel ~= nil and panel._set_focused ~= nil then
    panel:_set_focused(false)
  end
end

function ui_focus_arbiter:request(panel, set_focus_func, focus_bypassed_actions)
  if panel == nil then
    return false
  end
  if self._owner == panel then
    return true
  end
  if self._owner ~= nil then
    return false
  end
  self:_grant(panel, set_focus_func, focus_bypassed_actions)
  return true
end

function ui_focus_arbiter:release(panel)
  if panel == nil or self._owner ~= panel then
    return
  end
  self:_revoke()
end

function ui_focus_arbiter:is_focused(panel)
  return panel ~= nil and self._owner == panel
end

function ui_focus_arbiter:is_focus_within(panel)
  if panel == nil or self._frame_owner == nil then
    return false
  end
  local node = self._frame_owner
  while node ~= nil do
    if node == panel then
      return true
    end
    node = node.holder
  end
  return false
end

function ui_focus_arbiter:get_owner()
  return self._owner
end

function ui_focus_arbiter:get_frame_owner()
  return self._frame_owner
end

function ui_focus_arbiter:update(deltaTime)
  local panel = self._owner
  if panel == nil then
    return
  end
  if panel.is_active ~= true then
    self:_revoke()
    return
  end
  if panel.holder == nil then
    self:_revoke()
    return
  end
  if not InputManagerIns:is_joystick() then
    self:_revoke()
    return
  end
end

function ui_focus_arbiter:get_focus_bypassed_action_ids()
  return self._frame_focus_bypassed_actions
end

function ui_focus_arbiter:_on_controller_ui_change()
  if self._owner == nil then
    return
  end
  if not InputManagerIns:is_joystick() then
    self:_revoke()
  end
end

function ui_focus_arbiter:_add_event()
  if self._events ~= nil then
    for event_id, fun in pairs(self._events) do
      EventCenter.LuaRemoveListener(event_id, fun)
    end
  end
  self._events = {}
  self._events[EventID.ControllerUIChange] = pack(self, self._on_controller_ui_change)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

ui_focus_arbiter:_add_event()
return ui_focus_arbiter
