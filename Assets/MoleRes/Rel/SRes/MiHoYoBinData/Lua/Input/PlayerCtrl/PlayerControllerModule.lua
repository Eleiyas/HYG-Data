player_controller_module = player_controller_module or {}
require("Input/PlayerCtrl/PlayerControllerModuleInteraction")
player_controller_module.press_time = 0.4

function player_controller_module:init()
  self:add_event()
  self._pick_data = {}
  self._interact_data = {}
  self._long_pick_data = {}
  self._shake_data = {}
  self._exit_holding_hand_data = {}
  self._special_tool_data = {}
  self._long_press_prop_data = {}
  self._cook_accelerate_data = {}
  self._all_shortcut_data = {}
  self._star_friend_data = {}
  self._star_friend_data_count = 0
  self._last_ui_ctrl_mode = PlayerCtrlUIMode.Common
  self._cur_ui_ctrl_mode = PlayerCtrlUIMode.Common
  self._cur_ui_ctrl_mode_items = nil
end

function player_controller_module:add_event()
  self:remove_event()
  self._events = {}
  self._events[EventID.LuaSetPlayer] = pack(self, self._set_player)
  self._events[EventID.ControllerUIChange] = pack(self, self._on_controller_change)
  self._events[EventID.LuaAddOptionList] = pack(self, self._handle_lua_add_interact_list)
  self._events[EventID.LuaRemoveOptionList] = pack(self, self._handle_lua_remove_interact_list)
  self._events[EventID.ChangeUIControlMode] = pack(self, self._on_ui_ctrl_mode_change)
  self._events[EventID.onCloseFastRunUI] = pack(self, self._close_run_toggle)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function player_controller_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function player_controller_module:_close_run_toggle()
  if player_controller then
    player_controller:close_run_toggle()
  end
end

function player_controller_module:_on_ui_ctrl_mode_change(mode)
  if mode then
    self._last_ui_ctrl_mode = self._cur_ui_ctrl_mode
    self._cur_ui_ctrl_mode = mode
    self:_init_ui_ctrl_mode_item()
    player_controller:refresh_ui_ctrl_mode()
    player_controller:refresh_ui()
  end
end

function player_controller_module:_init_ui_ctrl_mode_item()
  self._cur_ui_ctrl_mode_items = {}
  local items = PlayerControlConfig.GetUICtrlModeConfig(self._cur_ui_ctrl_mode, CsInputManagerUtil.curCtrlModeType)
  if items then
    local item_tb = list_to_table(items)
    for _, item in ipairs(item_tb) do
      self._cur_ui_ctrl_mode_items[item] = 1
    end
  end
end

function player_controller_module:_handle_lua_add_long_press_prop_data(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  if add_data.interactShowType == InteractShowType.EditFurniture.value__ then
    local add_item = {
      name = add_data.stringArg,
      click_value = add_data.numArg,
      numArg = add_data.numArg,
      arg_type = add_data.argType,
      is_show_option = true,
      is_background = add_data.isBackground,
      entity_guid = add_data.targetGuid,
      is_locked = add_data.isLock,
      is_long_pick = add_data.pickOpt == PickOpt.LongPress,
      is_pick = add_data.interactShowType == InteractShowType.Pick.value__,
      action_type = add_data.interactShowType,
      press_time = add_data.pickOpt == PickOpt.LongPress and player_controller_module.press_time or 0,
      entity = CsEntityManagerUtil.GetEntityByGuid(add_data.targetGuid),
      sort_index = add_data.sortIndex
    }
    for i = #self._long_press_prop_data, 1, -1 do
      if self._long_press_prop_data[i].numArg == add_data.numArg then
        table.remove(self._long_press_prop_data, i)
      end
    end
    table.insert(self._long_press_prop_data, add_item)
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_remove_long_press_prop_data(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if remove_data.interactShowType == InteractShowType.EditFurniture.value__ then
    for i = #self._long_press_prop_data, 1, -1 do
      if self._long_press_prop_data[i].numArg == remove_data.numArg then
        table.remove(self._long_press_prop_data, i)
      end
    end
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_add_special_tool_data(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  if add_data.interactShowType == InteractShowType.UseFlyTool.value__ then
    for i = #self._special_tool_data, 1, -1 do
      if self._special_tool_data[i].numArg == add_data.numArg then
        table.remove(self._special_tool_data, i)
      end
    end
    table.insert(self._special_tool_data, add_data)
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_remove_special_tool_data(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if remove_data.interactShowType == InteractShowType.UseFlyTool.value__ then
    for i = #self._special_tool_data, 1, -1 do
      if self._special_tool_data[i].numArg == remove_data.numArg then
        table.remove(self._special_tool_data, i)
      end
    end
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_add_shake_data(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  if add_data.interactShowType == InteractShowType.Shake.value__ then
    for i = #self._shake_data, 1, -1 do
      if self._shake_data[i].numArg == add_data.numArg then
        table.remove(self._shake_data, i)
      end
    end
    table.insert(self._shake_data, add_data)
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_add_star_friend_data(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  local add_item = {
    click_value = add_data.numArg,
    numArg = add_data.numArg,
    arg_type = add_data.argType,
    is_show_option = true,
    is_background = add_data.isBackground,
    entity_guid = add_data.targetGuid,
    is_locked = add_data.isLock,
    action_type = add_data.interactShowType,
    press_time = add_data.pickOpt == PickOpt.LongPress and player_controller_module.press_time or 0,
    guid = add_data.targetGuid,
    sort_index = add_data.sortIndex
  }
  if not self._star_friend_data[add_data.numArg] then
    self._star_friend_data_count = self._star_friend_data_count + 1
  end
  self._star_friend_data[add_data.numArg] = add_item
end

function player_controller_module:_handle_lua_remove_shake_data(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if remove_data.interactShowType == InteractShowType.Shake.value__ then
    for i = #self._shake_data, 1, -1 do
      if self._shake_data[i].numArg == remove_data.numArg then
        table.remove(self._shake_data, i)
      end
    end
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_add_exit_holding_hand_data(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  if add_data.interactShowType == InteractShowType.ExitHoldingHand.value__ then
    for i = #self._exit_holding_hand_data, 1, -1 do
      if self._exit_holding_hand_data[i].numArg == add_data.numArg then
        table.remove(self._exit_holding_hand_data, i)
      end
    end
    table.insert(self._exit_holding_hand_data, add_data)
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_remove_exit_holding_hand_data(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if remove_data.interactShowType == InteractShowType.ExitHoldingHand.value__ then
    for i = #self._exit_holding_hand_data, 1, -1 do
      if self._exit_holding_hand_data[i].numArg == remove_data.numArg then
        table.remove(self._exit_holding_hand_data, i)
      end
    end
    player_controller:refresh_ui()
  end
end

function player_controller_module:_handle_lua_remove_star_friend_data(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if self._star_friend_data[remove_data.numArg] then
    self._star_friend_data[remove_data.numArg] = nil
    self._star_friend_data_count = self._star_friend_data_count - 1
  end
end

function player_controller_module:need_exit_holding_hand()
  return #self._exit_holding_hand_data > 0
end

function player_controller_module:exit_holding_hand()
  if self:need_exit_holding_hand() then
    local data = self._exit_holding_hand_data[1]
    CsUIUtil.OnOptionItemClick(data.argType, data.numArg)
  end
end

function player_controller_module:_set_player(data)
  if data then
    self.player = InputManagerIns:get_player_input_component()
  else
    Logger.Log("Lua设置Player false")
    self.player = nil
  end
end

function player_controller_module:_on_controller_change(layout_version)
  if is_null(layout_version) == false and not is_null(CsInputManagerUtil) then
    player_controller_module._cur_ctrl_mode = CsInputManagerUtil.GetControlModeType()
    if CsGameManagerUtil.changeControllerWithoutLayout then
      player_controller:reload_ui()
    else
      player_controller:destroy()
    end
    self._all_shortcut_data = {}
    if player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.TouchScreen then
      UIManagerInstance:change_layout_version(LayoutVersion.Mobile, true)
    elseif player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.KeyboardWithMouse then
      UIManagerInstance:change_layout_version(LayoutVersion.PC, true)
    elseif player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.Joypad then
      UIManagerInstance:change_layout_version(LayoutVersion.PS, true)
    end
  end
end

function player_controller_module:get_cur_ctrl_mode()
  if self._cur_ctrl_mode == nil and not is_null(CsInputManagerUtil) then
    player_controller_module._cur_ctrl_mode = CsInputManagerUtil.GetControlModeType()
  end
  return self._cur_ctrl_mode
end

function player_controller_module:get_long_press_prop_data()
  if #self._long_press_prop_data <= 0 then
    return nil
  end
  return self._long_press_prop_data[1]
end

function player_controller_module:is_long_press_lock()
  if #self._long_press_prop_data <= 0 then
    return false
  end
  return self._long_press_prop_data[1].is_locked
end

function player_controller_module:press_long_press_prop_data()
  if #self._long_press_prop_data <= 0 then
    return
  end
  local long_press_prop_data = self:get_long_press_prop_data()
  if long_press_prop_data then
    CsUIUtil.OnOptionItemClick(long_press_prop_data.arg_type, long_press_prop_data.numArg)
  end
end

function player_controller_module:exist_special_tool_data()
  return #self._special_tool_data > 0
end

function player_controller_module:get_star_friend_data()
  return self._star_friend_data
end

function player_controller_module:has_star_friend_data()
  return self._star_friend_data_count > 0
end

function player_controller_module:_get_main_camera()
  if is_null(self._main_camera) then
    self.main_camera = CsCameraManagerUtil.MainCamera
  end
  return self.main_camera
end

function player_controller_module:get_target_star_friend_data()
  if not self:has_star_friend_data() then
    return
  end
  local main_camera = self:_get_main_camera()
  local min_dist = 1
  local min_dist_star
  for _, star_data in pairs(self._star_friend_data) do
    local is_get, x, y, z = EntityUtil.try_get_entity_position_by_guid(star_data.guid)
    if is_get then
      if not self._pos then
        self._pos = Vector3(0, 0, 0)
      end
      self._pos:Set(x, y, z)
      local posInViewPoint = main_camera:WorldToViewportPoint(self._pos)
      local dist = math.abs(posInViewPoint.x - 0.5)
      if min_dist > dist then
        min_dist = dist
        min_dist_star = star_data
      end
    end
  end
  return min_dist_star
end

function player_controller_module:exist_pick_items()
  return #self._pick_data > 0
end

function player_controller_module:press_pick()
  local pick_data = self:get_pick_data()
  if pick_data then
    CsUIUtil.OnOptionItemClick(pick_data.arg_type, pick_data.numArg)
  end
end

function player_controller_module:get_shake_icon()
  return self:get_interact_icon(InteractShowType.Shake)
end

function player_controller_module:get_cook_accelerate_icon()
  if #self._cook_accelerate_data > 0 then
    return self:get_interact_icon(InteractShowType.CookAccelerate)
  end
  return nil
end

function player_controller_module:get_coffee_cup_icon()
  local cup_id = CsCoffeeRpUtil.GetCurrentConfigIdOnTableByBlackboard()
  if cup_id and cup_id ~= 0 then
    local icon_sprite = PlayerControlConfig.GetHandHeldIcon(cup_id)
    return icon_sprite
  end
  return nil
end

function player_controller_module:has_cook_accelerate_data()
  return #self._cook_accelerate_data > 0
end

function player_controller_module:cook_accelerate()
  if #self._cook_accelerate_data > 0 then
    local data = self._cook_accelerate_data[1]
    CsUIUtil.OnOptionItemClick(data.argType, data.numArg)
  end
end

function player_controller_module:get_interact_icon(show_type)
  local show_type_icon = PlayerControlConfig.GetInteractIcon(show_type)
  return show_type_icon
end

function player_controller_module:get_short_cut_cfg(short_cut)
end

function player_controller_module:get_default_farming_icon()
  return PlayerControlConfig.GetDefaultFarmingIcon()
end

function player_controller_module:get_precise_farming_icon()
  return PlayerControlConfig.GetPreciseFarmingIcon()
end

function player_controller_module:is_joystick()
  return is_null(player_controller_module._cur_ctrl_mode) == false and player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.Joypad
end

function player_controller_module:is_key_mouse()
  return is_null(player_controller_module._cur_ctrl_mode) == false and player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.KeyboardWithMouse
end

function player_controller_module:is_touch()
  return is_null(player_controller_module._cur_ctrl_mode) == false and player_controller_module._cur_ctrl_mode == ActionType.ControlModeType.TouchScreen
end

function player_controller_module:is_ctrl_ui_item_active(type)
  if self._cur_ui_ctrl_mode_items == nil then
    self:_init_ui_ctrl_mode_item()
  end
  return self._cur_ui_ctrl_mode_items[type] == 1
end

function player_controller_module:get_cur_ui_ctrl_mode()
  return self._cur_ui_ctrl_mode
end

function player_controller_module:get_no_hand_hold_icon()
  return PlayerControlConfig.GetNoHandHoldIcon()
end

function player_controller_module:get_float_in_water_icon()
  return PlayerControlConfig.GetFishingFloatInWaterIcon()
end

function player_controller_module:get_touch_default_pick_icon()
  return PlayerControlConfig.GetTouchDefaultPickIcon()
end

function player_controller_module:get_touch_pick_icon()
  return PlayerControlConfig.GetTouchPickIcon()
end

function player_controller_module:get_touch_default_interaction_icon()
  return PlayerControlConfig.GetTouchDefaultInteractionIcon()
end

function player_controller_module:get_exit_holding_hand_icon()
  return PlayerControlConfig.GetExitHoldingHandIcon()
end

return player_controller_module
