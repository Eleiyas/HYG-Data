phone_module = phone_module or {}

function phone_module:register_cmd_handler()
  phone_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[PlayRenameNickRsp] = pack(self, phone_module._handle_rename_nick_name_rsp)
  self._tbl_rep[SetSignatureRsp] = pack(self, phone_module._handle_rename_signature_rsp)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function phone_module:rename_nick_name(in_name)
  local data = {Name = in_name}
  NetHandlerIns:send_data(PlayRenameNickReq, data)
end

function phone_module:rename_signature(in_signature)
  local data = {Text = in_signature}
  NetHandlerIns:send_data(SetSignatureReq, data)
end

function phone_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function phone_module:_handle_rename_nick_name_rsp(server_data)
  if server_data.Retcode ~= 0 then
    local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), server_data.Retcode)
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  UIUtil.show_tips_by_text_id("rename_succ")
  lua_event_module:send_event(lua_event_module.event_type.change_name_succ)
end

function phone_module:_handle_rename_signature_rsp(server_data)
  Logger.Log("[PhoneModule] SetSignatureRsp RetCode:" .. tostring(server_data.Retcode))
  if server_data.Retcode ~= 0 and server_data.Retcode ~= 7012 then
    local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), server_data.Retcode)
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  if server_data.Retcode == 0 then
    UIUtil.show_tips_by_text_id("rename_signature_succ")
  end
  lua_event_module:send_event(lua_event_module.event_type.change_signature_succ)
end

return phone_module
