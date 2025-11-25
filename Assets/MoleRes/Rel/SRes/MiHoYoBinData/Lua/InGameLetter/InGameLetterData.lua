in_game_letter_module = in_game_letter_module or {}
in_game_letter_module._letter_data_dict = {}

function in_game_letter_module:get_letter_data_arr()
  local ret_tbl = {}
  for _, letter in pairs(self._letter_data_dict) do
    if not is_null(letter) and not letter.IsBuffered then
      table.insert(ret_tbl, letter)
    end
  end
  table.sort(ret_tbl, function(a, b)
    return a.SendTime > b.SendTime
  end)
  return ret_tbl
end

function in_game_letter_module:get_all_letter_count()
  local ret_count = 0
  for _, letter in pairs(self._letter_data_dict) do
    if not is_null(letter) then
      ret_count = ret_count + 1
    end
  end
  return ret_count
end

in_game_letter_module._item_letter_data_dict = {}
in_game_letter_module._max_letter_num = 0
in_game_letter_module._max_buffer_letter_num = 300
in_game_letter_module._warn_letter_num = 50

function in_game_letter_module:update_config_data(warn_letter_num, max_letter_num, max_buffer_letter_num)
  self._warn_letter_num = warn_letter_num
  self._max_letter_num = max_letter_num
  self._max_buffer_letter_num = max_buffer_letter_num + max_letter_num
  lua_event_module:send_event(lua_event_module.event_type.letter_state_update)
end

function in_game_letter_module:get_warn_letter_num()
  return self._warn_letter_num
end

function in_game_letter_module:get_max_letter_num()
  return self._max_letter_num
end

function in_game_letter_module:get_max_buffer_letter_num()
  return self._max_buffer_letter_num
end

function in_game_letter_module:update_server_letter(server_letter)
  if is_null(server_letter) then
    return
  end
  local letter_data = self:server_letter_to_letter_data(server_letter)
  if is_null(letter_data) then
    return
  end
  if letter_data.LetterType == LetterType.Normal then
    self._letter_data_dict[letter_data.Guid] = letter_data
  end
  if letter_data.LetterType == LetterType.Item then
    self._item_letter_data_dict[letter_data.Guid] = letter_data
  end
  lua_event_module:send_event(lua_event_module.event_type.letter_update)
end

function in_game_letter_module:delete_letter(guid)
  if self._letter_data_dict[guid] ~= nil then
    self._letter_data_dict[guid] = nil
  end
  if self._item_letter_data_dict[guid] ~= nil then
    self._item_letter_data_dict[guid] = nil
  end
  lua_event_module:send_event(lua_event_module.event_type.letter_update)
end

function in_game_letter_module:mark_letter_reward_taken(guid)
  print("[InGameLetterData] MarkLetterRewardTaken guid:" .. tostring(guid))
  if self._letter_data_dict[guid] ~= nil then
    self._letter_data_dict[guid].IsRewardTaken = true
    self:_add_npc_action_record(self._letter_data_dict[guid])
  end
  if self._item_letter_data_dict[guid] ~= nil then
    self._item_letter_data_dict[guid].IsRewardTaken = true
  end
  lua_event_module:send_event(lua_event_module.event_type.letter_update)
end

function in_game_letter_module:mark_letter_read(guid)
  if self._letter_data_dict[guid] ~= nil then
    self._letter_data_dict[guid].IsRead = true
  end
  if self._item_letter_data_dict[guid] ~= nil then
    self._item_letter_data_dict[guid].IsRead = true
  end
  lua_event_module:send_event(lua_event_module.event_type.letter_update)
  self:check_unread_letter()
end

function in_game_letter_module:get_letter(letter_type, guid)
  if letter_type == LetterType.Item then
    return self._item_letter_data_dict[guid]
  end
  return self._letter_data_dict[guid]
end

function in_game_letter_module:get_buffered_letter()
  local ret_tbl = {}
  for _, letter in pairs(self._letter_data_dict) do
    if not is_null(letter) and letter.IsBuffered then
      print("[InGameLetterData] GetBufferedLetter:" .. tostring(letter.Guid))
      table.insert(ret_tbl, letter)
    end
  end
  table.sort(ret_tbl, function(a, b)
    return a.SendTime > b.SendTime
  end)
  return ret_tbl
end

function in_game_letter_module:server_letter_to_letter_data(server_letter)
  if is_null(server_letter) then
    return nil
  end
  local letter_data = self:get_letter(server_letter.LetterType, server_letter.Guid)
  if is_null(letter_data) then
    letter_data = G.New("InGameLetter/InGameSingleLetterData")
  end
  letter_data:update_with_server_data(server_letter)
  return letter_data
end

function in_game_letter_module:check_unread_letter(obj)
  for _, letter in pairs(self._letter_data_dict) do
    if not is_null(letter) and not letter.IsRead then
      EventCenter.Broadcast(EventID.LetterBoxStateChange, LetterBoxState.HaveUnRead)
      return
    end
  end
  EventCenter.Broadcast(EventID.LetterBoxStateChange, LetterBoxState.AllRead)
end

function in_game_letter_module:_add_npc_action_record(letter_data)
  if letter_data == nil then
    return
  end
  local is_npc_return_letter = false
  local params = {
    npc_id = nil,
    log_system_type = NpcLogSourceSystemType.Letter,
    system_entry = 1,
    conditions = {},
    effect_params = {}
  }
  for _, reward in ipairs(letter_data.Rewards) do
    table.insert(params.effect_params, reward.ItemConfigId)
  end
  local npcReturnLetterTbl = LocalDataUtil.get_dic_table(typeof(CS.BReturnLetterCfg))
  for npc_id, cfgs in pairs(npcReturnLetterTbl) do
    if params.npc_id == nil then
      for _, cfg in pairs(cfgs) do
        if cfg.letterid == letter_data.ConfigId then
          is_npc_return_letter = true
          params.npc_id = npc_id
          table.insert(params.conditions, cfg.conditionid)
          break
        end
      end
    end
  end
  if is_npc_return_letter then
    CsCompanionStarModuleUtil.AddNpcActionRecord(params.npc_id, params.log_system_type, params.system_entry, params.conditions, params.effect_params)
  end
end

return in_game_letter_module
