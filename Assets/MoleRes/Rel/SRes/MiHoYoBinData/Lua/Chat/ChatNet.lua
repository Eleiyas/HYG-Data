chat_module = chat_module or {}

function chat_module:register_cmd_handler()
  chat_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[PrivateChatRsp] = pack(self, chat_module._handle_private_chat_rsp)
  self._tbl_rep[ChannelChatRsp] = pack(self, chat_module._handle_channel_chat_rsp)
  self._tbl_rep[PrivateChatNotify] = pack(self, chat_module._handle_private_chat_notify)
  self._tbl_rep[PullPrivateChatRsp] = pack(self, chat_module._handle_pull_private_chat_rsp)
  self._tbl_rep[ReadPrivateChatRsp] = pack(self, chat_module._handle_read_private_chat_rsp)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function chat_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function chat_module:pull_private_chat_req(uid, sequence, num)
  local data = {
    TargetUid = uid,
    FromSequence = sequence,
    PullNum = num
  }
  NetHandlerIns:send_data(PullPrivateChatReq, data)
  print("[chat_net]pull_private_chat_req:" .. table.serialize(data))
end

function chat_module:read_private_chat_req(uid, sequence)
  local data = {TargetUid = uid, ReadSequence = sequence}
  NetHandlerIns:send_data(ReadPrivateChatReq, data)
  print("[chat_net]read_private_chat_req:" .. table.serialize(data))
end

function chat_module:_handle_private_chat_rsp(data)
  if data == nil then
    return
  end
  if data.Retcode == 0 then
    lua_event_module:send_event(lua_event_module.event_type.on_chat_succ)
  end
  print("[chat_net]_handle_private_chat_rsp:" .. table.serialize(data))
end

function chat_module:_handle_channel_chat_rsp(data)
  if data == nil then
    return
  end
  if data.Retcode == 0 then
    local content = data.Req.Content
    if not is_null(content.PlayerContent) and string.is_valid(content.PlayerContent.InputText) then
      lua_event_module:send_event(lua_event_module.event_type.on_chat_succ)
    end
  end
  if data.Retcode == 8910 then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("CoffeeRp_Chat_Sensitive"))
  end
end

function chat_module:_handle_private_chat_notify(server_data)
  if server_data == nil or is_null(server_data.ChatUnit) then
    return
  end
  local data = {
    uid = server_data.Uid,
    chat_unit = chat_module:_get_chat_uint_data(server_data.ChatUnit, false)
  }
  local self_uid = player_module:get_player_uid()
  local chat_uid = data.uid
  if data.uid == self_uid then
    chat_uid = data.chat_unit.from_uid
    if chat_module:get_cur_chat_uid() ~= chat_uid then
      local friend_data = social_module:get_friend_info_by_uid(chat_uid)
      friend_data.max_sequence = data.chat_unit.sequence
      SocialSaveData.AddChatRecordUID(chat_uid)
    end
  else
    chat_uid = data.uid
  end
  if self._chat_tbl[chat_uid] == nil and data.uid == self_uid and data.chat_unit.sequence > 1 then
    self:pull_private_chat_req(chat_uid, data.chat_unit.sequence - 1, chat_module.MaxPullChatInfoCount)
  end
  self:_intert_chat_uint(chat_uid, data.chat_unit)
  if #self._chat_tbl[chat_uid] > chat_module.chat_data_max_num then
    table.remove(self._chat_tbl[chat_uid], 1)
  end
  social_module:set_last_chat_time_by_uid(chat_uid)
  lua_event_module:send_event(lua_event_module.event_type.on_private_chat_update, chat_uid)
  lua_event_module:send_event(lua_event_module.event_type.on_private_chat_ntf, data.chat_unit)
  lua_event_module:send_event(lua_event_module.event_type.refresh_chat_red_state)
end

function chat_module:check_new_chat_audio()
  local social_page = UIManagerInstance:is_show("UI/Social/SocialPage")
  if social_page ~= nil and social_page._cur_state_index == social_page.UiState.FriendChat then
    return
  end
  AudioManagerIns:post_eventnew(WEvent.Play_ui_fb_friend_newMessage, nil, nil, nil, nil)
end

function chat_module:_handle_pull_private_chat_rsp(server_data)
  if server_data == nil then
    return
  end
  local chat_list = {}
  for _, v in ipairs(array_to_table(server_data.ChatList)) do
    local chat_uint = chat_module:_get_chat_uint_data(v, false)
    table.insert(chat_list, chat_uint)
  end
  local data = {
    retcode = server_data.Retcode,
    chat_list = chat_list,
    read_sequence = server_data.ReadSequence,
    req = {
      target_uid = server_data.Req.TargetUid,
      from_sequence = server_data.Req.FromSequence,
      pull_num = server_data.Req.PullNum
    }
  }
  local uid = data.req.target_uid
  for i = 1, #data.chat_list do
    local chat_unit = data.chat_list[i]
    self:_intert_chat_uint(uid, chat_unit)
    if #self._chat_tbl[uid] > chat_module.chat_data_max_num then
      table.remove(self._chat_tbl[uid], 1)
    end
  end
  self._read_sequence_tbl[data.req.target_uid] = data.read_sequence
  lua_event_module:send_event(lua_event_module.event_type.on_private_chat_update, data.req.target_uid)
  print("[chat_net]_handle_pull_private_chat_rsp:", table.serialize(data), " ChatContent:", table.serialize(self._chat_tbl[uid]))
end

function chat_module:_intert_chat_uint(chat_uid, chat_uint)
  if is_null(chat_uint) then
    return
  end
  if self._chat_tbl[chat_uid] == nil then
    self._chat_tbl[chat_uid] = {}
  end
  for key, value in ipairs(self._chat_tbl[chat_uid]) do
    if value.sequence == chat_uint.sequence then
      self._chat_tbl[chat_uid][key] = chat_uint
      return
    end
  end
  table.insert(self._chat_tbl[chat_uid], chat_uint)
end

function chat_module:_handle_read_private_chat_rsp(server_data)
  if server_data == nil then
    return
  end
  local data = {
    req = {
      target_uid = server_data.Req.TargetUid,
      read_sequence = server_data.Req.ReadSequence
    }
  }
  self._read_sequence_tbl[data.req.target_uid] = data.req.read_sequence
  local friend_data = social_module:get_friend_info_by_uid(data.req.target_uid)
  friend_data.read_sequence = data.req.read_sequence
  lua_event_module:send_event(lua_event_module.event_type.refresh_chat_red_state)
  print("[chat_net]_handle_read_private_chat_rsp:" .. table.serialize(data))
end

return chat_module
