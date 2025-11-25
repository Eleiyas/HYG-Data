local M = G.Class("InputManager")
local util_class_name = "Input/InputActionUtil"
local player_controller_class_name = "Input/PlayerCtrl/PlayerController"
local player_controller_data_module_class_name = "Input/PlayerCtrl/PlayerControllerModule"
local wait_time = 0.3
input_lock_type = {
  none = 0,
  lock_buttons = 1,
  lock_left_axis = 2,
  lock_right_axis = 4,
  lock_all = 65535
}
input_lock_from = {
  Common = 1,
  UIOpenAndClose = 2,
  DelayLock = 4
}

function M:__ctor()
  self._mouse_manager = MouseManager
  self._input_util = require(util_class_name)
  self._lock_input = false
  self._lock_bit = 0
  self._wait_clock = 0
  self._is_touch_mask_init = false
  self.ctrl_data_module = require(player_controller_data_module_class_name)
  self.ctrl_data_module:init()
  self.player_controller = require(player_controller_class_name)
  self.player_controller:init()
  self.threeC_locks = {}
  self:_add_event()
  self.penetrating_actions = nil
end

function M:destroy()
  self:_remove_event()
  self.ctrl_data_module:remove_event()
  self.player_controller:destroy()
end

function M:dispatch_input_event()
  if is_null(CsInputManagerUtil) then
    return false
  end
  self.penetrating_actions = nil
  self.use_penetrating_actions = false
  player_controller:pre_dispatch_ctrl_event()
  self:_handle_global_event()
  if not self:_check_input_availability() then
    player_controller:player_input_mgr_sync()
    return true
  end
  local need_stop = false
  local stack_level = UIManagerInstance:get_input_action_windows_stack()
  for i = EUIInputStackLevel.high, EUIInputStackLevel.low do
    local stack = stack_level[i]
    if stack then
      for i = #stack, 1, -1 do
        local window = stack[i]
        if window.is_active then
          local window_actions = window:get_all_input_actions()
          local event_handled = false
          if window.config.player_ctrl_cfg then
            self:_dispatch_player_ctrl(window.config.player_ctrl_cfg.ctrl_cfg, window.config.player_ctrl_cfg.extra_cfg)
            if self.use_penetrating_actions then
              CsInputManagerUtil.SetPenetratingActions(self.penetrating_actions)
            end
            CsInputManagerUtil.Dispatch3CInputAction()
          elseif not window.config.input_penetrate and window.config.input_action_cfg.use_penetrating_actions == false then
            self:set_mouse_active(true, false)
          end
          for _, val in pairs(window_actions) do
            if not self:_has_solved(val.id) then
              local event_appeared = self:check_input_event(val)
              if event_appeared and self:is_input_locked() == false then
                val.handled = false
                window:handle_input_action(val)
                if val.handled then
                  self:_add_solved_list(val.id)
                end
                event_handled = event_handled or val.handled
              end
            end
          end
          if not window.config.input_penetrate then
            if window.config.input_action_cfg.use_penetrating_actions == false then
              if not window.config.player_ctrl_cfg then
                CsInputManagerUtil.SetPenetratingActions(nil)
              end
              need_stop = true
              break
            end
            self.use_penetrating_actions = true
            self:_bind_penetrate_action(window.config.input_action_cfg.penetrating_actions)
            break
          end
        end
      end
    end
    if need_stop then
      break
    end
  end
  player_controller:player_input_mgr_sync()
  return false
end

function M:_bind_penetrate_action(actions)
  if table.count(self.penetrating_actions) > 0 and actions then
    local new_penetrate_actions = {}
    for key, val in pairs(actions) do
      if self.penetrating_actions[key] == 1 then
        new_penetrate_actions[key] = 1
      end
    end
    self.penetrating_actions = new_penetrate_actions
  else
    self.penetrating_actions = actions
  end
end

function M:_filter_action(actions)
  if self.penetrating_actions then
    for _, val in pairs(actions) do
      if self.penetrating_actions[val.type] == 1 then
        local event_appeared = self:check_input_event(val)
        if event_appeared then
          val.handled = false
          window:handle_input_action(val)
          if val.handled then
            self:_add_solved_list(val.id)
          end
          event_handled = event_handled or val.handled
        end
      end
    end
  end
end

function M:_dispatch_player_ctrl(ctrl_cfg, extra_cfg)
  local player_events = player_controller:dispatch_ctrl_event(ctrl_cfg, extra_cfg)
end

function M:_check_input_availability()
  if self._lock_input then
    return false
  end
  return true
end

function M:_add_event()
  self:_remove_event()
  self._tbl_event = {}
  self._tbl_event[EventID.LuaSetMaskInfoShowState] = pack(self, M._show_touch_mask)
  self._tbl_event[EventID.LuaSetLoadingState] = function(is_loading)
    if is_loading == false then
      self:_clear_3c_lock()
    end
  end
  for k, v in pairs(self._tbl_event) do
    EventCenter.LuaAddListener(k, v)
  end
end

function M:_remove_event()
  if self._tbl_event then
    for k, v in pairs(self._tbl_event) do
      EventCenter.LuaRemoveListener(k, v)
    end
    self._tbl_event = nil
  end
end

function M:update(deltaTime)
  if self._wait_clock and self._wait_clock > 0 then
    self._wait_clock = self._wait_clock - deltaTime
    if self._wait_clock <= 0 then
      self:unlock_input(input_lock_from.DelayLock)
    end
  end
  if self.player_controller and self.player_controller.update then
    self.player_controller:update(deltaTime)
  end
end

function M:add_global_action(action_type, func, event_type)
  if action_type then
    local input_action = G.New(InputAction)
    input_action:init(action_type, event_type)
    if not self._gl_input_acts then
      self._gl_input_acts = {}
      self._gl_input_act_funcs = {}
    end
    self._gl_input_acts[input_action.id] = input_action
    self._gl_input_act_funcs[input_action.id] = func
  end
end

function M:_handle_global_event()
  if self._gl_input_acts then
    for _, val in pairs(self._gl_input_acts) do
      if not self:_has_solved(val.id) and self._gl_input_act_funcs[val.id] and self:check_input_event(val) then
        self._gl_input_act_funcs[val.id](val)
        if val.handled then
          self:_add_solved_list(val.id)
        end
      end
    end
  end
end

function M:check_input_event(action)
  if not is_null(CsInputManagerUtil) and (self.penetrating_actions == nil or self.penetrating_actions[action.type] == 1) then
    return CsInputManagerUtil.QueryInputEvent(action.type, action.event_type) == 1
  end
  return false
end

function M:check_input_event_by_type(type, event_type)
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.QueryInputEvent(type, event_type) == 1
  end
  return false
end

function M:get_player_input_component()
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetPlayerInput()
  end
end

function M:_has_solved(id)
  return CsInputManagerUtil.IsActionHandled(id)
end

function M:_add_solved_list(id)
  CsInputManagerUtil.MarkActionHandled(id)
end

function M:get_axis(action_type)
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetInputActionAxisValue(action_type)
  end
  return 0
end

function M:get_vector2(action_type)
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetInputActionVector2Value(action_type)
  end
  return 0, 0
end

function M:get_vector3(action_type)
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetInputActionVector3Value(action_type)
  end
  return 0, 0, 0
end

function M:get_val(action_type)
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetInputActionValueObj(action_type)
  end
  return nil
end

function M:get_control_mode()
  if not is_null(CsInputManagerUtil) then
    return CsInputManagerUtil.GetControlModeType()
  end
end

function M:set_mouse_active(active, restorePos)
  if self._mouse_active == active then
    return
  end
  if not is_null(self._mouse_manager) and self._mouse_manager.lockSetup then
    return
  end
  if self:get_control_mode() ~= ActionType.ControlModeType.KeyboardWithMouse then
    return
  end
  if restorePos == nil then
    restorePos = false
  end
  self._mouse_active = active
  if not is_null(self._mouse_manager) then
    if active then
      self._mouse_manager.UnlockMouse(restorePos)
    else
      self._mouse_manager.LockMouse()
    end
  end
end

function M:get_mouse_active()
  return self._mouse_active
end

function M:mouse_tool_wheel_mode(viewportPos)
  if not is_null(self._mouse_manager) then
    self._mouse_manager.ToolWheelMode(viewportPos)
  end
end

function M:is_joystick()
  return not is_null(player_controller_module) and player_controller_module:is_joystick()
end

function M:is_key_mouse()
  return not is_null(player_controller_module) and player_controller_module:is_key_mouse()
end

function M:is_touch()
  return not is_null(player_controller_module) and player_controller_module:is_touch()
end

function M:change_mode_type_with_out_ui(mode_type)
  if not is_null(CsInputManagerUtil) then
    CsInputManagerUtil.ChangeControlModeWithoutUI(mode_type)
  end
end

function M:change_mode_type(mode_type)
  if not is_null(CsInputManagerUtil) then
    CsInputManagerUtil.ChangeControlModeWithoutUI(mode_type)
  end
  if mode_type == ActionType.ControlModeType.TouchScreen then
    UIManagerInstance:change_layout_version(LayoutVersion.Mobile, true)
  elseif mode_type == ActionType.ControlModeType.KeyboardWithMouse then
    UIManagerInstance:change_layout_version(LayoutVersion.PC, true)
  elseif mode_type == ActionType.ControlModeType.Joypad then
    UIManagerInstance:change_layout_version(LayoutVersion.PS, true)
  end
end

function M:bind_d_pad(panel, func, with_repeat)
  self:bind_d_pad_horizontal(panel, func, with_repeat)
  self:bind_d_pad_vertical(panel, func, with_repeat)
end

function M:bind_d_pad_vertical(panel, func, with_repeat)
  self._input_util.bind_d_pad_vertical(panel, func, with_repeat)
end

function M:bind_d_pad_horizontal(panel, func, with_repeat)
  self._input_util.bind_d_pad_horizontal(panel, func, with_repeat)
end

function M:bind_stick(panel, func, with_repeat)
  self:bind_stick_horizontal(panel, func, with_repeat)
  self:bind_stick_vertical(panel, func, with_repeat)
end

function M:bind_stick_vertical(panel, func, with_repeat)
  self._input_util.bind_stick_vertical(panel, func, with_repeat)
end

function M:bind_stick_horizontal(panel, func, with_repeat)
  self._input_util.bind_stick_horizontal(panel, func, with_repeat)
end

function M:bind_right_stick(panel, func, with_repeat)
  self:bind_right_stick_vertical(panel, func, with_repeat)
  self:bind_right_stick_horizontal(panel, func, with_repeat)
end

function M:bind_right_stick_vertical(panel, func, with_repeat)
  self._input_util.bind_right_stick_vertical(panel, func, with_repeat)
end

function M:bind_right_stick_horizontal(panel, func, with_repeat)
  self._input_util.bind_right_stick_horizontal(panel, func, with_repeat)
end

function M:is_up(action)
  return self._input_util.is_up(action)
end

function M:is_down(action)
  return self._input_util.is_down(action)
end

function M:is_left(action)
  return self._input_util.is_left(action)
end

function M:is_right(action)
  return self._input_util.is_right(action)
end

function M:clear()
  self._lock_input = false
  self._lock_bit = 0
  self._wait_clock = 0
  self._is_touch_mask_init = false
  self.player_controller:destroy()
  self.threeC_locks = {}
  self:_clear_3c_lock()
end

function M:is_input_locked()
  return self._lock_input
end

function M:lock_input(from, mask_type)
  if not from or 52 < from then
    Logger.LogWarning("锁定输入时，传入的参数不合法 " .. tostring(from))
    return
  end
  self._lock_bit = self._lock_bit | from
  Logger.Log("锁定输入 " .. tostring(self._lock_bit))
  if not self._lock_input and self._lock_bit ~= 0 then
    self:_lock_touch(mask_type)
  end
  self._lock_input = self._lock_bit ~= 0
  CsInputManagerUtil.disableInput = self._lock_input
end

function M:unlock_input(from)
  if not from or 52 < from then
    Logger.LogWarning("解锁输入时，传入的参数不合法 " .. tostring(from))
    return
  end
  self._lock_bit = self._lock_bit & ~from
  Logger.Log("解锁输入 " .. tostring(self._lock_bit))
  self._lock_input = self._lock_bit ~= 0
  if not self._lock_input then
    self:_unlock_touch()
  end
  CsInputManagerUtil.disableInput = self._lock_input
end

function M:lock_input_while(time)
  self._wait_clock = time
  self:lock_input(input_lock_from.DelayLock)
end

function M:_lock_touch(mask_type)
  UIManagerInstance:set_touch_lock(true, mask_type)
end

function M:set_touch_mask_init()
  self._is_touch_mask_init = true
end

function M:_unlock_touch()
  UIManagerInstance:set_touch_lock(false)
end

function M:lock_3C(window, lock_type)
  if window == nil or window.__cname == nil then
    return
  end
  if self.threeC_locks[window.__cname] then
    Logger.LogWarning("尝试去设置3C锁时，检测到已经存在记录，请检查这个界面的解锁逻辑是否存在问题")
  end
  self.threeC_locks[window.__cname] = lock_type
  lock_type = input_lock_type.none
  local debugStr = ""
  local num = 1
  for key, val in pairs(self.threeC_locks) do
    if val then
      debugStr = debugStr .. tostring(num) .. ":" .. key
      num = num + 1
      lock_type = lock_type | val
    end
  end
  CsPlayerInputManagerUtil.SetUILock(lock_type, debugStr)
end

function M:unlock_3C(window)
  if window == nil or window.__cname == nil then
    return
  end
  local lock_type = input_lock_type.none
  if self.threeC_locks[window.__cname] ~= nil then
    self.threeC_locks[window.__cname] = nil
  else
    return
  end
  local debugStr = ""
  for key, val in pairs(self.threeC_locks) do
    if val then
      debugStr = debugStr .. "|" .. key
      lock_type = lock_type | val
    end
  end
  CsPlayerInputManagerUtil.SetUILock(lock_type, debugStr)
end

function M:_clear_3c_lock()
  self.threeC_locks = {}
  CsPlayerInputManagerUtil.SetUILock(input_lock_type.none, "")
end

function M:_show_touch_mask(is_show)
  if is_show then
    self:lock_input(input_lock_from.Common)
  else
    self:unlock_input(input_lock_from.Common)
  end
end

function M:lock_mouse_setup(lock)
  if self:get_control_mode() ~= ActionType.ControlModeType.KeyboardWithMouse then
    return
  end
  if not is_null(self._mouse_manager) then
    self._mouse_manager.lockSetup = lock
    if lock == false and not is_null(self._mouse_manager) then
      if self._mouse_active then
        self._mouse_manager.UnlockMouse()
      else
        self._mouse_manager.LockMouse()
      end
    end
  end
end

return M
