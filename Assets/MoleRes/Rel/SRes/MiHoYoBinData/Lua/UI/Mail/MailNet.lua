mails_module = mails_module or {}
mails_module._cname = "mails_module"
local MAIL_TYPE_NORMAL = 0

function mails_module:register_cmd_handler()
  mails_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[FetchAllMailRsp] = pack(self, mails_module._handle_fetch_all_mail_rsp)
  self._tbl_rep[MailMultiBatchNotify] = pack(self, mails_module._handle_mail_multi_batch_notify)
  self._tbl_rep[NewMailNotify] = pack(self, mails_module._handle_new_mail_notify)
  self._tbl_rep[ChangeMailNotify] = pack(self, mails_module._handle_change_mail_notify)
  self._tbl_rep[DelMailNotify] = pack(self, mails_module._handle_del_mail_notify)
  self._tbl_rep[ReadMailRsp] = pack(self, mails_module._handle_read_mail_rsp)
  self._tbl_rep[TakeMailAttachmentRsp] = pack(self, mails_module._handle_take_mail_attachment_rsp)
  self._tbl_rep[DelMailRsp] = pack(self, mails_module._handle_del_mail_rsp)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function mails_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function mails_module:fetch_all_mails_req()
  local data = {
    MailType = CS.Proto.MailType.Normal
  }
  NetHandlerIns:send_data(FetchAllMailReq, data)
  print("[mail_net]fetch_all_mails_req:")
end

function mails_module:read_mail_req(id_list)
  local read_mail_req = NetHandlerIns:create_cmd(ReadMailReq)
  for _, id in pairs(id_list) do
    read_mail_req.IdList:Add(id)
  end
  NetHandlerIns:send_msg(read_mail_req, nil)
end

function mails_module:take_mail_attachment_req(id_list)
  local take_mail_attachment_req = NetHandlerIns:create_cmd(TakeMailAttachmentReq)
  for _, id in pairs(id_list) do
    take_mail_attachment_req.IdList:Add(id)
  end
  NetHandlerIns:send_msg(take_mail_attachment_req, nil)
end

function mails_module:del_mail_req(id_list)
  local del_mail_req = NetHandlerIns:create_cmd(DelMailReq)
  for _, id in pairs(id_list) do
    del_mail_req.IdList:Add(id)
  end
  NetHandlerIns:send_msg(del_mail_req, nil)
end

function mails_module:_handle_fetch_all_mail_rsp(data)
  if data == nil then
    return
  end
end

function mails_module:_get_mail_data(data)
  local ret_data = {
    mail_id = data.MailId,
    send_time = data.SendTime,
    expiry_time = data.ExpiryTime,
    importance = data.Importance,
    is_read = data.IsRead,
    attachment = {
      is_taken = data.Attachment.IsTaken,
      item_list = mails_module:_get_mail_item_list(data.Attachment.ItemList)
    },
    config_id = data.config_id,
    text_data = {
      title = data.TextData.Title,
      content = data.TextData.Content,
      sender = data.TextData.Sender,
      argument_list = array_to_table(data.TextData.ArgumentList)
    }
  }
  return ret_data
end

function mails_module:_get_mail_item_list(datas)
  local ret_list = {}
  for _, v in ipairs(array_to_table(datas)) do
    table.insert(ret_list, {
      id = v.Id,
      count = v.Count
    })
  end
  return ret_list
end

function mails_module:_handle_mail_multi_batch_notify(server_data)
  if server_data == nil then
    return
  end
  local mail_datas = {}
  for _, v in ipairs(array_to_table(server_data.MailList)) do
    table.insert(mail_datas, mails_module:_get_mail_data(v))
  end
  local data = {
    req_sequence_id = server_data.ReqSequenceId,
    mail_list = mail_datas,
    from_index = server_data.FromIndex,
    total_count = server_data.TotalCount
  }
  self._mail_datas = {}
  local now_seconds = CsServerTimeModuleUtil.ServerUtcNowTimeStamp()
  for _, mail_data in ipairs(data.mail_list) do
    local is_expire = mails_module.is_expire(mail_data)
    if is_expire == false then
      self._mail_datas[mail_data.mail_id] = mail_data
    else
      self._mail_datas[mail_data.mail_id] = nil
    end
  end
  print("[mail_net]_handle_mail_multi_batch_notify:" .. table.serialize(data))
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_new_mail_notify(server_data)
  if server_data == nil then
    return
  end
  local mail_datas = {}
  for _, v in ipairs(array_to_table(server_data.MailList)) do
    table.insert(mail_datas, mails_module:_get_mail_data(v))
  end
  for _, mail_data in ipairs(mail_datas) do
    self._mail_datas[mail_data.mail_id] = mail_data
  end
  Logger.Log("[mail_net]_handle_new_mail_notify")
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_change_mail_notify(data)
  if data == nil then
    return
  end
  local mail_datas = {}
  for _, v in ipairs(array_to_table(data.MailList)) do
    table.insert(mail_datas, mails_module:_get_mail_data(v))
  end
  for _, mail_data in ipairs(mail_datas) do
    self._mail_datas[mail_data.mail_id] = mail_data
  end
  Logger.Log("[mail_net]_handle_change_mail_notify")
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_del_mail_notify(data)
  if data == nil then
    return
  end
  for _, mail_id in ipairs(array_to_table(data.IdList)) do
    self._mail_datas[mail_id] = nil
  end
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_read_mail_rsp(data)
  if data == nil or data.Req == nil then
    return
  end
  if data.Retcode > 0 then
    return
  end
  for _, mail_id in ipairs(array_to_table(data.Req.IdList)) do
    local mail_data = self._mail_datas[mail_id]
    if mail_data ~= nil then
      mail_data.is_read = true
    end
  end
  Logger.Log("[mail_net]_handle_read_mail_rsp")
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_take_mail_attachment_rsp(data)
  if data == nil then
    return
  end
  if data.Retcode > 0 then
    local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), data.Retcode)
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  if data.Req == nil then
    return
  end
  for _, mail_id in ipairs(array_to_table(data.Req.IdList)) do
    local mail_data = self._mail_datas[mail_id]
    if mail_data ~= nil and mail_data.attachment ~= nil then
      mail_data.attachment.is_taken = true
    end
  end
  Logger.Log("[mail_net]_handle_take_mail_attachment_rsp")
  lua_event_module:send_event(lua_event_module.event_type.on_mails_update)
end

function mails_module:_handle_del_mail_rsp(data)
  if data == nil then
    return
  end
end

local function is_expire(mail_data)
  if mail_data == nil then
    return false
  end
  local now_seconds = CsServerTimeModuleUtil.ServerUtcNowTimeStamp()
  local is_expire = tonumber(now_seconds) >= tonumber(mail_data.expiry_time)
  return is_expire
end

mails_module.is_expire = is_expire
return mails_module or {}
