in_game_letter_module = in_game_letter_module or {}

function in_game_letter_module:register_cmd_handler()
  in_game_letter_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[LetterActionRsp] = pack(self, in_game_letter_module._handle_letter_action_rsp)
  self._tbl_rep[AllLetterNotify] = pack(self, in_game_letter_module._handle_all_letter_notify)
  self._tbl_rep[LetterNotify] = pack(self, in_game_letter_module._handle_letter_notify)
  self._tbl_rep[LetterConfigNotify] = pack(self, in_game_letter_module._handle_letter_config_notify)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function in_game_letter_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function in_game_letter_module:req_read_letter(guid)
  self:_req_letter_action(guid, LetterActionType.LetterActionRead)
end

function in_game_letter_module:req_take_letter_reward(guid)
  self:_req_letter_action(guid, LetterActionType.LetterActionTakeRewards)
end

function in_game_letter_module:req_delete_letter(guid)
  self:_req_letter_action(guid, LetterActionType.LetterActionRemove)
end

function in_game_letter_module:req_get_letter_from_buffer()
  for _, letter in pairs(self._letter_data_dict) do
    if not is_null(letter) and letter.IsBuffered then
      self:_req_letter_action(letter.Guid, LetterActionType.LetterActionGetFromBuffer)
    end
  end
end

function in_game_letter_module:_req_letter_action(guid, actionType)
  local data = {Guid = guid, Action = actionType}
  print("[InGameLetterNet] _req_letter_action" .. tostring(guid) .. " " .. tostring(actionType))
  NetHandlerIns:send_data(LetterActionReq, data)
end

function in_game_letter_module:_handle_letter_action_rsp(server_data)
  if is_null(server_data) then
    return
  end
  print("======================[InGameLetterNet] _handle_letter_action_rsp" .. tostring(server_data))
  if server_data.Retcode > 0 then
    local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), server_data.Retcode)
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  if server_data.Req.Action == LetterActionType.LetterActionTakeRewards then
    self:mark_letter_reward_taken(server_data.Req.Guid)
    return
  end
  if server_data.Req.Action == LetterActionType.LetterActionRead then
    self:mark_letter_read(server_data.Req.Guid)
    return
  end
  if server_data.Req.Action == LetterActionType.LetterActionRemove then
    self:delete_letter(server_data.Req.Guid)
    return
  end
end

function in_game_letter_module:_handle_all_letter_notify(server_data)
  if is_null(server_data) then
    return
  end
  print("======================[InGameLetterNet] _handle_all_letter_notify" .. tostring(server_data))
  if not is_null(server_data.NormalLetterList) then
    for _, server_letter in ipairs(array_to_table(server_data.NormalLetterList)) do
      self:update_server_letter(server_letter)
    end
  end
  if not is_null(server_data.ItemLetterList) then
    for _, server_letter in ipairs(array_to_table(server_data.ItemLetterList)) do
      self:update_server_letter(server_letter)
    end
  end
  self:check_unread_letter()
end

function in_game_letter_module:_handle_letter_notify(server_data)
  if is_null(server_data) then
    return
  end
  if server_data.Action == LetterActionType.LetterActionRemove then
    self:delete_letter(server_data.Letter.Guid)
    return
  end
  print("======================[InGameLetterNet] _handle_letter_notify" .. tostring(server_data))
  self:update_server_letter(server_data.Letter)
  self:check_unread_letter()
end

function in_game_letter_module:_handle_letter_config_notify(server_data)
  if is_null(server_data) then
    return
  end
  print("====================[InGameLetterNet] _handle_letter_config_notify" .. tostring(server_data))
  self:update_config_data(server_data.WarnLetterNum, server_data.MaxLetterNum, server_data.MaxBufferLetterNum)
end

return in_game_letter_module
