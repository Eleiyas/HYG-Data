player_module = player_module or {}

function player_module:add_event()
  player_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOnPlayerEquipRsp] = pack(self, self._handle_player_take_on_equip_rsp)
  self._events[EventID.LuaOpenMainPageMask] = pack(self, self._handle_set_player_interaction_mask_state)
  self._events[EventID.LuaReloadToolData] = pack(self, self._handle_reload_tool_data)
  self._events[EventID.LuaSetAbilityAvailabilityState] = pack(self, self._handle_set_ability_availability_state)
  self._events[EventID.LuaAddOptionList] = pack(self, self._handle_lua_add_option_list)
  self._events[EventID.LuaRemoveOptionList] = pack(self, self._handle_lua_remove_option_list)
  self._events[EventID.CSEquipItem] = pack(self, self._handle_cs_equip_item)
  self._events[EventID.LuaSetLoadingState] = pack(self, self._handle_lua_set_loading_state)
  self._events[EventID.ShowCardLearnTips] = pack(self, self._show_card_learn_tips)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function player_module:_handle_lua_add_option_list(add_data)
  if is_null(add_data) or add_data.argType == nil then
    return
  end
  if add_data.numArg <= 0 or add_data.interactShowType ~= InteractShowType.PutBack.value__ then
    return
  end
  self:_handle_set_ability_availability_state(false)
end

function player_module:_handle_lua_remove_option_list(remove_data)
  if is_null(remove_data) or remove_data.argType == nil then
    return
  end
  if remove_data.numArg <= 0 or remove_data.interactShowType ~= InteractShowType.PutBack.value__ then
    return
  end
  self:_handle_set_ability_availability_state(true)
end

function player_module:_handle_cs_equip_item(make_id)
  player_module:player_take_on_equip(0, make_id)
end

function player_module:_handle_lua_set_loading_state(state)
  if state then
  end
end

function player_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function player_module:_handle_set_player_interaction_mask_state(show_mask)
  self._interaction_mask_is_open = show_mask
end

function player_module:_handle_reload_tool_data()
  self._tbl_all_tools = nil
  self._cur_equip_tool_index = -1
  self._tbl_have_tools = nil
  self:get_all_tool()
  self:get_cur_equip_tool_index()
  self:get_tbl_have_tools()
  EventCenter.Broadcast(EventID.OnUpdatePlayTool, true)
end

function player_module:_handle_set_ability_availability_state(state)
  self._ability_availability_state = state or false
  lua_event_module:send_event(lua_event_module.event_type.set_ability_availability)
end

function player_module:get_ability_availability_state()
  return self._ability_availability_state or false
end

function player_module:ui_default_validate_player_states()
  return GameplayUtility.Player.UIDefaultValidatePlayerStates()
end

function player_module:play_anim(anim_name, exit_call_back, event_call_back)
  local avatar_entity = player_module:get_player_entity()
  if not is_null(avatar_entity) then
    avatar_entity:PlayTalkAnim(anim_name, exit_call_back, event_call_back)
  end
end

function player_module:get_obj_by_type(ref_obj_type)
  local avatar_entity = player_module:get_player_entity()
  if not is_null(avatar_entity) then
    return avatar_entity.RefTool:GetObjByType(ref_obj_type)
  end
  return nil
end

function player_module:cur_hand_in_type_is_tool()
  return player_module:get_player_data().curHandInType == QuickSlotType.Tool
end

function player_module:tool_is_null()
  local tool_tbl = list_to_table(player_module:get_player_data():GetQuickItemList(QuickSlotType.Tool))
  if tool_tbl == nil or #tool_tbl <= 0 then
    return true
  end
  for _, v in ipairs(tool_tbl) do
    if 0 < v.ConfigId then
      return false
    end
  end
  return true
end

function player_module:weapon_is_null()
  if player_module:get_player_data().curHandWeaponGuid <= 0 then
    return true
  end
  return false
end

function player_module:pack_up_tool(call_back)
  local tool = player_module:get_cur_equip_item()
  if tool and tool.MakeGUID > 0 then
    CommandUtil.AllocateTryToggleItemCmd(player_module:get_player_entity().guid, true, EntityCmdExecuteType.EnQueue, false)
    if call_back then
      CommandUtil.AllocateEntityCallBackCmd(player_module:get_player_entity().guid, function()
        call_back()
      end)
    end
  end
end

function player_module:take_out_tool(call_back)
  local tool = player_module:get_cur_equip_item()
  CommandUtil.AllocateTryToggleItemCmd(player_module:get_player_entity().guid, false)
  if call_back then
    CommandUtil.AllocateEntityCallBackCmd(player_module:get_player_entity().guid, function()
      call_back()
    end)
  end
end

function player_module:play_learn_anim(learn_item_cfg_id, callback)
  lua_event_module:send_event(lua_event_module.event_type.show_packet_page_mask, 10)
  self._learn_item_cfg_id = learn_item_cfg_id
  self._learn_tips_action = callback
  CsGameplayUtilitiesInteractionUtil.PlayLearnDIYCardEffect(learn_item_cfg_id)
end

function player_module:play_exit_learn_anim()
  if self._learn_item_cfg_id <= 0 then
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.bag_select_next_item)
  item_module:auto_use_recipe()
  self._learn_tips_action = nil
  self._learn_item_cfg_id = 0
end

function player_module:_show_card_learn_tips()
  if self._learn_tips_action then
    self._learn_tips_action()
  end
end

return player_module or {}
