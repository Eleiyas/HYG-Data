player_controller = player_controller or {}
CommandButton = {
  None = 0,
  Interact = 1,
  Tool = 2,
  Pick = 4,
  RunToggle = 8,
  ToolWheel = 16,
  MouseMiddle = 32,
  FarmingModeSwitch = 64,
  FishTap = 128,
  FishHold = 256,
  Slow = 512,
  SpecialTool = 1024
}
local pick_click_timeout = 0.2
local speed_up_timeout = 0.5

function player_controller:init()
  self.act_cfg = require("Input/PlayerCtrl/PlayerControllerCfg")
  self.values = {}
  self.values._move_horizontal = 0
  self.values._move_vertical = 0
  self.values._running = false
  self.values._run = false
  self.values._slow = false
  self.values._run_timer = 0
  self.values._camera_rotate_horizontal = 0
  self.values._camera_rotate_vertical = 0
  self.values._rotate_value_from = ActionType.CamValFrom.Default
  self.values._camera_mouse_rotate_allowed = false
  self.values._ban_camera_mouse_rotate_allowed = false
  self.values._show_mouse = false
  self.values._mouse_wheel = 0
  self.values._mouse_middle_pressing = false
  self.values._fixed_camera = Vector2()
  self.values._farming_mode_switch_pressed = false
  self._move_rotate_horizontal = 0
  self.values.has_send_pick_tip_event = false
  self.values._inter_action_down = false
  self.values._inter_action_pressing = false
  self.values._inter_action_up = false
  self.values._inter_action_down_and_up = 0
  self.values.interact_time = 0
  self.values.interact_up_time = 0
  self.values._use_prop = false
  self.values._use_prop_down = false
  self.values._use_prop_up = false
  self.values._use_prop_time = 0
  self.values.has_send_long_press_prop_tip_event = false
  self.values._tool_wheel = false
  self.values._tool_wheel_up = false
  self.values._tool_wheel_down = false
  self.values.fish_tap_ing = false
  self.values.fish_hold_ing = false
  self.values.fish_delta = Vector2()
  self.values.special_tool = false
  self._handled_events_this_frame = {}
  self._mouse_always_show = false
  self.is_moving = false
  self.values.move_vector = Vector2()
  self.values.camera_vector = Vector2()
  self.delay_move_horizontal = 0
  self.delay_move_vertical = 0
  self.delay_move_horizontal_frame = 0
  self.delay_move_vertical_frame = 0
  self._events = {}
end

function player_controller:apply_player_ctrl_cfg(page, player_ctrl_cfg)
  self.player_ctrl_cfg = player_ctrl_cfg
  local ui_cfg, ctrl_cfg
  if player_ctrl_cfg then
    ui_cfg = player_ctrl_cfg.ui_cfg
    ctrl_cfg = player_ctrl_cfg.ctrl_cfg
  end
  if ctrl_cfg then
    self.ctrl_cfg = ctrl_cfg
    EntityUtil.set_player_move(self.ctrl_cfg.move)
    EntityUtil.set_player_ability_input_active(self.ctrl_cfg.ability)
  else
    EntityUtil.set_player_move(false)
    EntityUtil.set_player_ability_input_active(false)
  end
  if ui_cfg then
    self.ui_config = ui_cfg
    self._current_owner_page = page
    if self.ctrl_ui == nil or UIManagerInstance:get_windows_by_guid(self.ctrl_ui.guid) == nil then
      local guid
      guid, self.ctrl_ui = UIManagerInstance:open("UI/PlayerCtrl/PlayerControllerScene", ui_cfg)
      self.is_active = true
    else
      self.ctrl_ui:set_extra_data(ui_cfg)
      self:_set_ui_active(true)
      self.ctrl_ui:refresh()
      if ui_cfg.tip then
        self:_reset_interaction()
        self:_reset_long_press_prop()
      end
    end
  else
    self:_reset_interaction()
    self:_reset_long_press_prop()
    self:_reset_delay_move()
    self.ui_config = ui_cfg
    self._current_owner_page = page
    self:_set_ui_active(false)
  end
end

function player_controller:refresh_ui()
  if self.ctrl_ui then
    self.ctrl_ui:refresh()
  end
end

function player_controller:refresh_ui_ctrl_mode()
  if self.ctrl_ui then
    self.ctrl_ui:refresh_ui_ctrl_mode()
  end
end

function player_controller:_set_ui_active(active)
  self.is_active = active
  if is_null(self.ctrl_ui) == false and self.ctrl_ui.is_active ~= active and is_null(self.ctrl_ui.binder) == false and self.ctrl_ui:is_ready() then
    self.ctrl_ui:set_active(active)
  end
end

function player_controller:pre_dispatch_ctrl_event()
  table.clear(self._handled_events_this_frame)
  self.values._move_horizontal = 0
  self.values._move_vertical = 0
  self.values.move_vector:Set(0, 0)
  self.values._running = false
  if self.values._run and 0 < self.values._run_timer and Time.time - self.values._run_timer > speed_up_timeout then
    self.values._run_timer = -1
    self.values._run = false
  end
  self._move_rotate_horizontal = 0
  self.values._camera_rotate_horizontal = 0
  self.values._camera_rotate_vertical = 0
  self.values.camera_vector:Set(0, 0)
  self.values._rotate_value_from = ActionType.CamValFrom.Default
  self.values._camera_mouse_rotate_allowed = false
  self.values._show_mouse = false
  self.values._mouse_wheel = 0
  self.values._mouse_middle_pressing = false
  self.values._fixed_camera:Set(0, 0)
  self.values._farming_mode_switch_pressed = false
  self.values.fish_tap_ing = false
  self.values.fish_hold_ing = false
  self.values.fish_delta:Set(0, 0)
  self.values._inter_action_down = false
  self.values._inter_action_pressing = false
  self.values._inter_action_up = false
  self.values._inter_action_down_and_up = 0
  self.values._use_prop = false
  self.values._use_prop_down = false
  self.values._use_prop_up = false
  self.values.special_tool = false
  self._handled_this_frame = false
end

function player_controller:dispatch_ctrl_event(ctrl_cfg, extra_cfg)
  self.ctrl_cfg = ctrl_cfg
  self.extra_cfg = extra_cfg
  if self.ctrl_cfg.camera then
    self:_update_camera_val()
  end
  if self.ctrl_cfg.ability then
    self:_update_ability_val()
  end
  self:put_into_effect()
  self:player_input_mgr_sync()
end

function player_controller:player_input_mgr_sync()
  local command_btn = CommandButton.None
  if self.values._run then
    command_btn = command_btn | CommandButton.RunToggle
  end
  self.values.move_vector:Set(self.values._move_horizontal, self.values._move_vertical)
  if not is_null(self._camera_entity) then
    self.values.camera_vector:Set(self.values._camera_rotate_horizontal, self.values._camera_rotate_vertical)
  end
  if self.values.picking and OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStatePickUp) then
    command_btn = command_btn | CommandButton.Pick
  end
  if self.values._inter_action_pressing then
    command_btn = command_btn | CommandButton.Interact
  end
  if self.values._tool_wheel then
    command_btn = command_btn | CommandButton.ToolWheel
  end
  if self.values._mouse_middle_pressing then
    command_btn = command_btn | CommandButton.MouseMiddle
  end
  if self.values._farming_mode_switch_pressed then
    command_btn = command_btn | CommandButton.FarmingModeSwitch
  end
  if self.values.fish_hold_ing then
    command_btn = command_btn | CommandButton.FishHold
  end
  if self.values.fish_tap_ing then
    command_btn = command_btn | CommandButton.FishTap
  end
  if self.values._slow then
    command_btn = command_btn | CommandButton.Slow
  end
  if self.values.special_tool then
    command_btn = command_btn | CommandButton.SpecialTool
  end
  if self.values._use_prop and self:_check_ui_click() == false and player_controller_module:has_cook_accelerate_data() == false and OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateLeftClickInteraction) then
    command_btn = command_btn | CommandButton.Tool
  end
  if self.ctrl_ui then
    self.ctrl_ui:update_shortcut_pressed_state(command_btn)
  end
end

function player_controller:_update_ability_val()
  local ability_actions = self:_get_multi_platform_cfg(self.act_cfg.e_ability)
  if ability_actions then
    self.values._inter_action_down = self:_check_event(ability_actions.inter_action)
    self.values._inter_action_pressing = self:_check_event(ability_actions.inter_action, ActionType.EType.ButtonPressing)
    self.values._inter_action_up = self:_check_event(ability_actions.inter_action, ActionType.EType.ButtonReleased)
    local up_and_down = self:_get_axis(ability_actions.inter_action_down_and_up, ActionType.EType.InProgress)
    if up_and_down then
      self.values._inter_action_down_and_up = up_and_down
    end
    if self.values._inter_action_pressing then
      self.values.interact_time = self.values.interact_time + Time.deltaTime
    end
    if self.values._inter_action_up then
      self.values.interact_up_time = self.values.interact_time
      self.values.interact_time = 0
    end
    if self.values._inter_action_down then
      self.values.interact_time = 0
      self.values.interact_up_time = 0
    end
    self.values._use_prop_down = self:_check_event(ability_actions.prop)
    self.values._use_prop_up = self:_check_event(ability_actions.prop, ActionType.EType.ButtonReleased)
    self.values._use_prop = self:_check_event(ability_actions.prop, ActionType.EType.ButtonPressing) and not self.values._show_mouse
    if self.values._use_prop then
      self.values._use_prop_time = self.values._use_prop_time + Time.deltaTime
    end
    if self.values._use_prop_down or self.values._use_prop_up then
      self.values._use_prop_time = 0
    end
    self.values.special_tool = self:_check_event(ability_actions.special_tool, ActionType.EType.ButtonPressing)
  end
end

function player_controller:_update_camera_val()
  local camera_actions = self:_get_multi_platform_cfg(self.act_cfg.e_camera)
  if camera_actions then
    self.values._rotate_value_from = camera_actions.value_from
    local camera_x, camera_y = self:_get_vector2(camera_actions.camera, ActionType.EType.InProgress)
    self.values._camera_rotate_horizontal = camera_x
    self.values._camera_rotate_vertical = camera_y
    local fixed_camera_vector_x, fixed_camera_vector_y = self:_get_vector2(camera_actions.fixed_camera, ActionType.EType.InProgress)
    self.values._fixed_camera:Set(fixed_camera_vector_x, fixed_camera_vector_y)
    if player_controller_module:is_key_mouse() then
      if self.extra_cfg and self.extra_cfg.replace_rotate_allow_action and self.extra_cfg.rotate_allow_action then
        self.values._camera_mouse_rotate_allowed = self:_check_event(self.extra_cfg.rotate_allow_action, ActionType.EType.ButtonPressing)
      else
        self.values._camera_mouse_rotate_allowed = self:_check_event(camera_actions.rotate_allowed, ActionType.EType.ButtonPressing)
      end
      if self.extra_cfg and self.extra_cfg.rotate_allow_check_click_ui and self.extra_cfg.rotate_allow_action then
        if self:_check_event(self.extra_cfg.rotate_allow_action) then
          if self:_check_ui_click() then
            self.values._ban_camera_mouse_rotate_allowed = true
          else
            self.values._ban_camera_mouse_rotate_allowed = false
          end
        end
        if self.values._ban_camera_mouse_rotate_allowed then
          self.values._camera_mouse_rotate_allowed = false
        end
      end
    end
    self.values._show_mouse = self:_check_event(ActionType.Act.ShowMouse, ActionType.EType.ButtonPressing) or self._mouse_always_show
    if player_controller_module:is_key_mouse() then
      self.values._mouse_middle_pressing = self:_check_event(camera_actions.rotate_allowed_new, ActionType.EType.ButtonPressing)
      local val = self:_get_axis(camera_actions.mouse_wheel, ActionType.EType.InProgress)
      if is_null(val) == false then
        self.values._mouse_wheel = val
      end
    end
  end
end

function player_controller:is_vector_null(vector)
  if is_null(vector) or vector.x == 0 and vector.y == 0 then
    return true
  end
  return false
end

function player_controller:_get_axis(action_type, event_type)
  if self:_check_event(action_type, event_type) then
    return InputManagerIns:get_axis(action_type)
  end
  return 0
end

function player_controller:_get_vector2(action_type, event_type)
  if self:_check_event(action_type, event_type) then
    return InputManagerIns:get_vector2(action_type)
  end
  return 0, 0
end

function player_controller:_check_event(action_type, event_type)
  if event_type == nil then
    event_type = ActionType.EType.ButtonPressed
  end
  if action_type == nil then
    return false
  end
  local event = self:_get_event(action_type, event_type)
  event.handled = true
  table.insert(self._handled_events_this_frame, event)
  return InputManagerIns:check_input_event(event)
end

function player_controller:_get_event(action_type, event_type)
  local id = action_type * 100 + event_type
  if self._events[id] == nil then
    local input_action = G.New(InputAction)
    input_action:init(action_type, event_type)
    self._events[id] = input_action
  end
  return self._events[id]
end

function player_controller:put_into_effect()
  local set_move_value = false
  if self.ctrl_cfg.move and player_controller_module.player and (self.values._move_horizontal ~= 0 or self.values._move_vertical ~= 0) then
    set_move_value = true
    if math.abs(self.values._move_horizontal) >= 0.1 or math.abs(self.values._move_vertical) >= 0.1 then
      level_musicalchairs:_losegame()
    end
  end
  self.is_moving = set_move_value
  if self.ctrl_cfg.camera then
    self:_rotate_value_filter()
    GameplayUtility.Camera.TryRotateCamera(self.values._camera_rotate_horizontal, self.values._camera_rotate_vertical, self.values._rotate_value_from)
    if self.ctrl_cfg.right_ctrl or CsCameraManagerUtil.AllowRotateMode or CsPhotographyManagerUtil.MouseForceShow then
      InputManagerIns:set_mouse_active(self.values._camera_mouse_rotate_allowed == false, true)
    else
      InputManagerIns:set_mouse_active(self.values._show_mouse, false)
    end
  end
  if self.ctrl_cfg.ability then
    self:handle_interaction()
    if player_controller_module:need_exit_holding_hand() then
      if self.values._use_prop_up then
        player_controller_module:exit_holding_hand()
      end
    else
      self:handle_use_prop()
    end
    if self.values._inter_action_down_and_up and self.values._inter_action_down_and_up ~= 0 then
      lua_event_module:send_event(lua_event_module.event_type.interaction_list_up_down, self.values._inter_action_down_and_up)
    end
  end
  CsStarSeaManagerUtil.SetInputData(self.values._move_horizontal, self.values._move_vertical)
end

function player_controller:handle_use_prop()
  if self.values._use_prop_down then
    local long_press_prop_data = player_controller_module:get_long_press_prop_data()
    if long_press_prop_data and long_press_prop_data.press_time > 0 then
      local data = {
        time = long_press_prop_data.press_time
      }
      self.values.has_send_long_press_prop_tip_event = true
      lua_event_module:send_event(lua_event_module.event_type.long_press_prop_show_or_hide_tip, data)
    end
    local cur_mode = player_controller_module:get_cur_ui_ctrl_mode()
    local mode_val = type(cur_mode) == "number" and cur_mode or cur_mode.value__
    if mode_val == PlayerCtrlUIMode.KiteCtrl.value__ then
      lua_event_module:send_event(lua_event_module.event_type.kite_ctrl_hit)
    end
  end
  if self.values.has_send_long_press_prop_tip_event and 0 < self.values._use_prop_time then
    local long_press_prop_data = player_controller_module:get_long_press_prop_data()
    if long_press_prop_data and long_press_prop_data.press_time > 0 then
      if self.values._use_prop_time > long_press_prop_data.press_time then
        player_controller_module:press_long_press_prop_data()
        lua_event_module:send_event(lua_event_module.event_type.long_press_prop_show_or_hide_tip)
        self.values.has_send_long_press_prop_tip_event = false
        self.values._use_prop_time = 0
      end
    else
      self:_reset_long_press_prop()
    end
  end
  if self.values._use_prop_up and self.values.has_send_long_press_prop_tip_event then
    self:_reset_long_press_prop()
  end
end

function player_controller:handle_interaction()
  if self.values._inter_action_down then
    local long_pick_data = player_controller_module:get_long_pick_data()
    if long_pick_data and long_pick_data.press_time > 0 then
      local data = {
        time = long_pick_data.press_time,
        delay_time = pick_click_timeout
      }
      self.values.has_send_pick_tip_event = true
      lua_event_module:send_event(lua_event_module.event_type.pick_show_or_hide_tip, data)
    end
  end
  if self.values.has_send_pick_tip_event and 0 < self.values.interact_time then
    local long_pick_data = player_controller_module:get_long_pick_data()
    if long_pick_data and long_pick_data.press_time > 0 then
      if self.values.interact_time > long_pick_data.press_time + pick_click_timeout then
        player_controller_module:press_long_pick()
        lua_event_module:send_event(lua_event_module.event_type.pick_show_or_hide_tip)
        self.values.has_send_pick_tip_event = false
        self.values.interact_time = 0
      end
    else
      self:_reset_interaction()
    end
  end
  if self.values._inter_action_up and self.values.interact_up_time < pick_click_timeout then
    lua_event_module:send_event(lua_event_module.event_type.press_interaction)
  end
  if self.values._inter_action_up and self.values.has_send_pick_tip_event then
    self:_reset_interaction()
  end
end

function player_controller:_get_multi_platform_cfg(cfg)
  if cfg and cfg.multi_platform then
    return cfg[player_controller_module:get_cur_ctrl_mode()]
  end
  return cfg
end

function player_controller:_handle_move_rotate()
  local move_horizontal = InputManagerIns:get_axis(ActionType.Act.Horizontal)
  local move_vertical = InputManagerIns:get_axis(ActionType.Act.Vertical)
  if move_horizontal ~= 0 or move_vertical ~= 0 then
    if self._move_time == nil then
      self._move_time = 0
    end
    self._move_time = self._move_time + Time.deltaTime
    if self._move_time >= CsCameraManagerUtil.autoRotatePrepare then
      self._long_move = true
    end
  else
    self._long_move = false
    self._move_time = 0
  end
  if move_horizontal == 0 then
    self._rotate_time = 0
  end
  if self._last_vertical_axis == nil then
    self._last_vertical_axis = move_vertical
  end
  if 0 > move_vertical * self._last_vertical_axis then
    self._long_move = false
    self._move_time = 0
  end
  self._last_vertical_axis = move_vertical
  if self._long_move and self:_check_event(ActionType.Act.CameraRAllowed, ActionType.EType.ButtonPressing) == false then
    if 0 >= move_horizontal * self._last_horizontal_axis then
      self._rotate_time = 0
    end
    self._rotate_time = self._rotate_time + Time.deltaTime
    local a = math.min(1, self._rotate_time / CsCameraManagerUtil.autoRotateSlow)
    self._move_rotate_horizontal = a * CsCameraManagerUtil.autoRotateRatio * (0 <= move_vertical and 1 or -1) * move_horizontal
    self.values._rotate_value_from = ActionType.CamValFrom.Mouse
    self._last_horizontal_axis = move_horizontal
  else
    self._last_horizontal_axis = 0
  end
end

function player_controller:_rotate_value_filter()
  if self.values._rotate_value_from == ActionType.CamValFrom.Joypad then
    if math.abs(self.values._camera_rotate_vertical) < 0.15 and math.abs(self.values._camera_rotate_horizontal) > 0.6 then
      self.values._camera_rotate_vertical = 0
    end
    if math.abs(self.values._camera_rotate_horizontal) < 0.4 and math.abs(self.values._camera_rotate_vertical) > 0.6 then
      self.values._camera_rotate_horizontal = 0
    end
  end
  if InputManagerIns:is_joystick() or InputManagerIns:is_touch() then
    if math.abs(self.values._fixed_camera.y) < 0.3 and 0.6 < math.abs(self.values._fixed_camera.x) then
      self.values._fixed_camera.y = 0
    end
    if 0.4 > math.abs(self.values._fixed_camera.x) and 0.6 < math.abs(self.values._fixed_camera.y) then
      self.values._fixed_camera.x = 0
    end
  end
  if player_controller_module:has_any_interaction_data() and (InputManagerIns:is_joystick() or InputManagerIns:is_key_mouse()) then
    self.values._fixed_camera.x = 0
    self.values._fixed_camera.y = 0
    if InputManagerIns:is_joystick() then
      self.values._camera_rotate_vertical = 0
    end
  end
  if self.ctrl_cfg.right_ctrl or CsCameraManagerUtil.AllowRotateMode or CsPhotographyManagerUtil.MouseForceShow then
    if self.values._rotate_value_from == ActionType.CamValFrom.Mouse and not self.values._camera_mouse_rotate_allowed then
      self.values._camera_rotate_vertical = 0
      self.values._camera_rotate_horizontal = 0
    end
  elseif self.values._rotate_value_from == ActionType.CamValFrom.Mouse and self.values._show_mouse then
    self.values._camera_rotate_vertical = 0
    self.values._camera_rotate_horizontal = 0
  end
  if self._move_rotate_horizontal ~= 0 then
    self.values._camera_rotate_horizontal = self._move_rotate_horizontal
  end
end

function player_controller:set_touch_parent_by_mask_active(parent, active)
  if self.ctrl_ui then
    self.ctrl_ui:set_touch_parent_by_mask_active(parent, active)
  end
end

function player_controller:destroy()
  if self.ctrl_ui then
    self.ctrl_ui = nil
  end
end

function player_controller:reload_ui()
  if self.ctrl_ui then
    UIManagerInstance:destroy_window(self.ctrl_ui.guid)
    self.ctrl_ui = nil
    self:apply_player_ctrl_cfg(self._current_owner_page, self.player_ctrl_cfg)
  end
end

function player_controller:get_cur_ctrl_mode()
  return player_controller_module:get_cur_ctrl_mode()
end

function player_controller:is_player_moving()
  return self.is_moving
end

function player_controller:set_mouse_always_show(status)
  self._mouse_always_show = status
end

function player_controller:is_ability_active()
  if self.ctrl_cfg and self.ctrl_cfg.ability then
    return true
  end
  return false
end

function player_controller:get_ability_cfg()
  if self.ctrl_cfg and self.ctrl_cfg.ability then
    return self.ctrl_cfg.ability
  end
  return nil
end

function player_controller:update(deltaTime)
  local ability = self:get_ability_cfg()
  if ability ~= self._old_ability then
    self._old_ability = ability
    lua_event_module:send_event(lua_event_module.event_type.on_player_ability_change)
  end
end

function player_controller:_check_ui_click()
  return player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.KeyboardWithMouse and CsUIUtil.IsPointerOverGameObject()
end

function player_controller:_reset_interaction()
  if self.values.has_send_pick_tip_event then
    lua_event_module:send_event(lua_event_module.event_type.pick_show_or_hide_tip)
    self.values.has_send_pick_tip_event = false
    self.values.interact_time = 0
    self.values.interact_up_time = 0
  end
end

function player_controller:_reset_long_press_prop()
  if self.values.has_send_long_press_prop_tip_event then
    lua_event_module:send_event(lua_event_module.event_type.long_press_prop_show_or_hide_tip)
    self.values.has_send_long_press_prop_tip_event = false
    self.values._use_prop_time = 0
  end
end

function player_controller:_reset_delay_move()
  self.delay_move_horizontal_frame = 0
  self.delay_move_vertical_frame = 0
end

function player_controller:close_run_toggle()
  if not self.values._running then
    self.values._run = false
  end
end

return player_controller
