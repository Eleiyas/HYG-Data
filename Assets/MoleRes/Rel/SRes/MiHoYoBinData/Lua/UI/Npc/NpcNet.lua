npc_module = npc_module or {}

function npc_module:register_cmd_handler()
  npc_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._npc_gift_data = {}
  self._give_gift_count = {}
  self._can_express_npc_id = {}
  self._tbl_rep[NpcDailyGiftCountNotify] = pack(self, npc_module._handle_npc_daily_gift_count_ntf)
  self._tbl_rep[GiftByExpressNpcListNotify] = pack(self, npc_module._handle_express_gift_npc_list_ntf)
  self._tbl_rep[NpcRecentGiftRecordNotify] = pack(self, npc_module._handle_npc_recent_gift_record_ntf)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function npc_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function npc_module:get_can_express_npc_id()
  return self._can_express_npc_id or {}
end

function npc_module:get_all_express_give_num()
  if self._give_gift_count == nil then
    return 0
  end
  return self._give_gift_count.all_express_count or 0
end

function npc_module:get_all_talk_give_num()
  if self._give_gift_count == nil then
    return 0
  end
  return self._give_gift_count.all_talk_count or 0
end

function npc_module:get_express_give_num_by_npc_id(npc_id)
  if npc_id and 0 <= npc_id and self._give_gift_count and self._give_gift_count.tbl_npc_count[npc_id] then
    return self._give_gift_count.tbl_npc_count[npc_id].express_count or 0
  end
  return 0
end

function npc_module:get_talk_give_num_by_npc_id(npc_id)
  if npc_id and 0 <= npc_id and self._give_gift_count and self._give_gift_count.tbl_npc_count[npc_id] then
    return self._give_gift_count.tbl_npc_count[npc_id].talk_count or 0
  end
  return 0
end

function npc_module:_handle_npc_daily_gift_count_ntf(data)
  if data then
    local count_data = self._give_gift_count
    if count_data.tbl_npc_count == nil then
      count_data.tbl_npc_count = {}
    end
    count_data.tbl_npc_count[data.NpcConfigId] = {
      talk_count = data.DailyGiftCountMap[npc_module.give_gift_type.talk],
      express_count = data.DailyGiftCountMap[npc_module.give_gift_type.express]
    }
    count_data.all_talk_count = 0
    count_data.all_express_count = 0
    for i, v in pairs(count_data.tbl_npc_count) do
      count_data.all_talk_count = count_data.all_talk_count + v.talk_count
      count_data.all_express_count = count_data.all_express_count + v.express_count
    end
    self._give_gift_count = count_data
  end
end

function npc_module:_handle_express_gift_npc_list_ntf(data)
  if data then
    self._can_express_npc_id = array_to_table(data.NpcConfigIdList)
  end
end

function npc_module:_handle_npc_recent_gift_record_ntf(data)
  if data then
    self._npc_gift_data[data.NpcConfigId] = {
      get_items = array_to_table(data.ReceiveGiftConfigIdList),
      ret_items = array_to_table(data.ReturnGiftConfigIdList)
    }
  end
end

function npc_module:send_give_gift_req(guid)
  if guid == nil or npc_module:get_cur_npc_id() == nil then
    return
  end
  local data = {
    ItemGuid = guid,
    NpcConfigId = npc_module:get_cur_npc_id()
  }
end

function npc_module:_handle_npc_gift_by_talk_rsp(data)
  EventCenter.Broadcast(EventID.LuaGiveGiftRsp, data.Retcode == 0)
end

function npc_module:_handle_npc_gift_by_express_rsp(data)
  EventCenter.Broadcast(EventID.LuaGiveGiftRsp, data.Retcode == 0)
end

function npc_module:_handle_npc_gift_rsp(data)
  if data.Retcode ~= 0 then
    player_module:take_out_tool()
  end
  EventCenter.Broadcast(EventID.LuaGiveGiftRsp, data.Retcode == 0)
end

return npc_module
