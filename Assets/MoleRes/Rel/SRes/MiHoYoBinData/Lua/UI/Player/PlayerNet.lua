player_module = player_module or {}

function player_module:register_cmd_handler()
  player_module:un_register_cmd_handler()
  self._tbl_rep = {}
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function player_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function player_module:player_take_on_equip(slot_id, make_guid)
  local cur_equip_item = player_module:get_cur_equip_item()
  if cur_equip_item and cur_equip_item.MakeGUID == make_guid then
    return
  end
  local player_data = player_module:get_player_data()
  if not is_null(player_data) and player_data:GetCurHandInItemGuid() == 0 and make_guid <= 0 then
    return
  end
  if cur_equip_item and item_module:is_tool(cur_equip_item.ConFigID) then
    player_module:set_last_equip_make_guid(player_data:GetCurHandInItemGuid())
  end
  if make_guid < 0 then
    make_guid = 0
  end
  self._cut_tool_guid = make_guid
  CommandUtil.AllocateSSSwitchToolByMakeIdCmd(player_module:get_player_guid(), make_guid, 0)
  local item = item_module:get_item_by_make_id(make_guid)
  if not is_null(item) and item_module:is_tool(item.ConFigID, item.idCfg) then
    EventCenter.Broadcast(EventID.ShowStrength, 2)
  end
end

function player_module:_handle_player_take_on_equip_rsp(data)
  self._cur_equip_tool_index = -1
  local is_send_event = false
  local is_cut_type = false
  if player_module:cur_hand_in_type_is_tool() then
    is_send_event = true
  elseif self._cut_tool_guid then
    if self._cut_tool_guid <= 0 then
      is_cut_type = true
    else
      local item_data = item_module:get_item_by_make_id(self._cut_tool_guid)
      if item_module:item_bag_type_is_tool(item_data.ConFigID) then
        is_cut_type = true
      else
        is_send_event = true
      end
    end
    self._cut_tool_guid = nil
  end
  if is_cut_type then
    lua_event_module:send_event(lua_event_module.event_type.cut_cur_hand_in_type, true)
  end
  if is_send_event then
    EventCenter.Broadcast(EventID.LuaCutPlayerEquipTool, nil)
  end
end

function player_module:exchange_quick_slot_req(old_index, now_index)
  if old_index == now_index then
    return
  end
  local change_data = self._tbl_all_tools[old_index] or {}
  self._tbl_all_tools[old_index] = self._tbl_all_tools[now_index] or {}
  self._tbl_all_tools[now_index] = change_data
  self._cur_equip_tool_index = -1
  self._tbl_have_tools = nil
  EventCenter.Broadcast(EventID.LuaUpdateToolsSort, nil)
  NetHandlerIns.net_handler:Request_ExchangeQuickSlotReq(player_module:get_player_data().curHandInType.value__, old_index, now_index)
end

function player_module:set_active_quick_item_slot_type_req(hand_type)
  if player_module:get_player_data().curHandInType == hand_type then
    return
  end
  NetHandlerIns.net_handler:Request_SetActiveQuickItemSlotTypeReq(hand_type.value__)
end

function player_module:free_hand_req()
  local data = {}
  NetHandlerIns:send_data(FreeHandReq, data)
end

return player_module or {}
