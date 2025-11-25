player_controller_module = player_controller_module or {}

function player_controller_module:_handle_lua_add_interact_list(add_data)
  if is_null(add_data) or add_data.interactShowType == nil then
    return
  end
  if add_data.interactShowType == InteractShowType.ExitHoldingHand.value__ then
    self:_handle_lua_add_exit_holding_hand_data(add_data)
    return
  end
  if add_data.interactShowType == InteractShowType.Shake.value__ then
    self:_handle_lua_add_shake_data(add_data)
    return
  end
  if add_data.interactShowType == InteractShowType.UseFlyTool.value__ then
    self:_handle_lua_add_special_tool_data(add_data)
    return
  end
  if add_data.interactShowType == InteractShowType.EditFurniture.value__ then
    self:_handle_lua_add_long_press_prop_data(add_data)
    return
  end
  if add_data.interactShowType == InteractShowType.FriendStarButton.value__ then
    self:_handle_lua_add_star_friend_data(add_data)
    return
  end
  if self:_check_interact_type(add_data.interactShowType) == false then
    return
  end
  local add_item = {
    name = add_data.stringArg,
    click_value = add_data.numArg,
    numArg = add_data.numArg,
    arg_type = add_data.argType,
    is_show_option = true,
    is_background = add_data.isBackground,
    entity_guid = add_data.targetGuid,
    is_locked = add_data.isLock,
    lock_pass_through = add_data.shouldLockPassthrough,
    is_long_pick = add_data.pickOpt == PickOpt.LongPress,
    is_pick = add_data.interactShowType == InteractShowType.Pick.value__,
    is_buy = add_data.interactShowType == InteractShowType.GeLianShopBuy.value__,
    action_type = add_data.interactShowType,
    press_time = add_data.pickOpt == PickOpt.LongPress and player_controller_module.press_time or 0,
    entity = GameplayUtilities.Entities.GetEntity(add_data.targetGuid),
    guid = add_data.targetGuid,
    sort_index = add_data.sortIndex == 0 and add_data.numArg or add_data.sortIndex
  }
  if add_item.is_long_pick then
    for i = #self._long_pick_data, 1, -1 do
      if self._long_pick_data[i].numArg == add_data.numArg then
        table.remove(self._long_pick_data, i)
      end
    end
    table.insert(self._long_pick_data, add_item)
  else
    for i = #self._interact_data, 1, -1 do
      if self._interact_data[i].numArg == add_data.numArg then
        table.remove(self._interact_data, i)
      end
    end
    table.insert(self._interact_data, add_item)
    table.sort(self._interact_data, function(a, b)
      return a.sort_index > b.sort_index
    end)
  end
  lua_event_module:send_event(lua_event_module.event_type.interaction_list_refresh)
  lua_event_module:send_event(lua_event_module.event_type.update_name_hint_arrow)
end

function player_controller_module:_handle_lua_remove_interact_list(remove_data)
  if is_null(remove_data) or remove_data.interactShowType == nil then
    return
  end
  if remove_data.interactShowType == InteractShowType.ExitHoldingHand.value__ then
    self:_handle_lua_remove_exit_holding_hand_data(remove_data)
    return
  end
  if remove_data.interactShowType == InteractShowType.Shake.value__ then
    self:_handle_lua_remove_shake_data(remove_data)
    return
  end
  if remove_data.interactShowType == InteractShowType.UseFlyTool.value__ then
    self:_handle_lua_remove_special_tool_data(remove_data)
    return
  end
  if remove_data.interactShowType == InteractShowType.EditFurniture.value__ then
    self:_handle_lua_remove_long_press_prop_data(remove_data)
    return
  end
  if remove_data.interactShowType == InteractShowType.FriendStarButton.value__ then
    self:_handle_lua_remove_star_friend_data(remove_data)
    return
  end
  if self:_check_interact_type(remove_data.interactShowType) == false then
    return
  end
  for i = #self._long_pick_data, 1, -1 do
    if self._long_pick_data[i].numArg == remove_data.numArg then
      table.remove(self._long_pick_data, i)
    end
  end
  for i = #self._interact_data, 1, -1 do
    if self._interact_data[i].numArg == remove_data.numArg then
      table.remove(self._interact_data, i)
    end
  end
  table.sort(self._interact_data, function(a, b)
    return a.sort_index > b.sort_index
  end)
  lua_event_module:send_event(lua_event_module.event_type.interaction_list_refresh)
  lua_event_module:send_event(lua_event_module.event_type.update_name_hint_arrow)
end

function player_controller_module:_check_interact_type(show_type)
  if show_type ~= InteractShowType.PutBack.value__ and show_type ~= InteractShowType.Shake.value__ then
    return true
  end
  return false
end

function player_controller_module:has_any_interaction_data()
  return #self._interact_data > 0 or 0 < #self._long_pick_data
end

function player_controller_module:get_pick_data()
  if #self._interact_data <= 0 then
    return nil
  end
  for _, data in ipairs(self._interact_data) do
    if data and data.is_pick then
      return data
    end
  end
  return nil
end

function player_controller_module:get_interaction_data()
  return self._interact_data
end

function player_controller_module:get_all_option_item_arrow_data()
  local option_data = {}
  if player_controller:is_ability_active() then
    for _, data in ipairs(self._interact_data) do
      if not data.is_pick then
        table.insert(option_data, data)
      end
    end
    return option_data
  end
  return {}
end

function player_controller_module:get_all_option_item_entity()
  if (self._interact_data == nil or #self._interact_data == 0) and (self._long_pick_data == nil or #self._long_pick_data == 0) then
    return {}
  end
  local option_data = {}
  if InputManagerIns:is_touch() then
    for _, data in ipairs(self._interact_data) do
      if data and not data.is_pick and is_null(data.entity) == false then
        table.insert(option_data, data.entity)
      end
    end
  elseif self.list_select_index ~= 0 then
    local data = self._interact_data[self.list_select_index]
    if data and not data.is_pick and is_null(data.entity) == false then
      table.insert(option_data, data.entity)
    end
  end
  local long_pick_data = self:get_long_pick_data()
  if long_pick_data and not_null(long_pick_data.entity) and not table.contains(option_data, long_pick_data.entity) then
    table.insert(option_data, long_pick_data.entity)
  end
  return option_data
end

function player_controller_module:set_select_index(index)
  self.list_select_index = index
end

function player_controller_module:get_long_pick_data()
  if #self._long_pick_data == 0 then
    return nil
  end
  return self._long_pick_data[1]
end

function player_controller_module:press_long_pick()
  local long_pick_data = self:get_long_pick_data()
  if long_pick_data and not long_pick_data.is_locked then
    CsUIUtil.OnOptionItemClick(long_pick_data.arg_type, long_pick_data.numArg)
  end
end

return player_controller_module
