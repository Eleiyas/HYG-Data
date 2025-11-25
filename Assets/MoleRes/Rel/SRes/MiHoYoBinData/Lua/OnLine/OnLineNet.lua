on_line_module = on_line_module or {}

function on_line_module:register_cmd_handler()
  on_line_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[GetFishExchangeRsp] = pack(self, on_line_module._handle_get_fish_exchange_rsp)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function on_line_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function on_line_module:give_fish_to_player()
  local data = on_line_module:get_give_fish_data()
  if is_null(data) then
    Logger.LogError("�����������, �޷�����")
    return
  end
  local net_data = {
    FlowUID = data.givePlayerId,
    ItemGUID = data.fishGuid
  }
  NetHandlerIns:send_data(GiveAwayToFlowPlayReq, net_data)
end

function on_line_module:send_quick_chat(send_str)
  MultiplayerUtility.SendChat(send_str)
end

function on_line_module:send_fish_share(fish_id)
  local send_str = string.format("2:%s", fish_id)
  MultiplayerUtility.SendChat(send_str)
end

function on_line_module:send_fish_demand(fish_id)
  local send_str = string.format("3:%s", fish_id)
  MultiplayerUtility.SendChat(send_str)
end

function on_line_module:get_fish_exchange_req(item_guid)
  local net_data = {ItemGUID = item_guid}
  NetHandlerIns:send_data(GetFishExchangeReq, net_data)
end

function on_line_module:_handle_get_fish_exchange_rsp(ntf)
  if ntf.Retcode <= 0 then
  else
  end
end

return on_line_module
