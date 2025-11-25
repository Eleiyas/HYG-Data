chat_module = chat_module or {}

function chat_module:get_read_sequence(uid)
  if is_null(self._read_sequence_tbl[uid]) then
    return 0
  end
  return self._read_sequence_tbl[uid]
end

function chat_module:get_chat_list(uid)
  if uid == 0 then
    local owner_uid = GameSceneUtility.GetCurrentSceneOwnerUID()
    if owner_uid <= 0 then
      owner_uid = level_module:get_cur_scene_id()
    end
    uid = owner_uid + chat_module.public_chat_value
    return self._public_chat_tbl[uid] or {}
  end
  if is_null(self._chat_tbl[uid]) then
    return nil
  end
  return self._chat_tbl[uid]
end

function chat_module:get_all_npc_chat_by_id(npc_id)
  if npc_id == nil or npc_id <= 0 or self._tbl_all_npc_chat == nil or self._tbl_all_npc_chat[npc_id] == nil then
    return {}
  end
  return self._tbl_all_npc_chat[npc_id]
end

function chat_module:get_one_npc_chat_by_index(npc_id, index)
  local tbl_data = chat_module:get_all_npc_chat_by_id(npc_id)
  return tbl_data[index]
end

function chat_module:check_npc_chat_num_by_id(npc_id)
  if #self._tbl_all_npc_chat[npc_id] >= chat_module.npc_chat_data_max_num then
    table.remove(self._tbl_all_npc_chat[npc_id], 1)
    local rem_data = self._tbl_all_npc_chat[npc_id][1]
    local rem_guid = rem_data.guid
    chat_module:_remove_npc_chat_call_back_by_guid(rem_guid)
    table.remove(self._tbl_all_npc_chat[npc_id], 1)
  end
end

function chat_module:_remove_npc_chat_call_back_by_guid(rem_guid)
  if rem_guid and self._tbl_all_npc_chat_call_back_guid[rem_guid] then
    CsNLPModuleUtil.ClearCb(rem_guid)
    self._tbl_all_npc_chat_call_back_guid[rem_guid] = nil
  end
end

function chat_module:_get_chat_uint_data(data, is_public)
  local content = ""
  local chat_type = 0
  local is_npc = false
  local form_id = data.FromUid
  local name = ""
  if not is_null(data.PlayerContent) or not is_null(data.NpcContent) then
    is_npc = is_null(data.PlayerContent)
    local content_data
    if is_npc then
      content_data = data.NpcContent
      if string.is_valid(content_data.NpcText) then
        content = string.gsub(content_data.NpcText, "{WorldOwnerName}", player_module:get_player_name())
        form_id = content_data.NpcId
        chat_type = chat_module.chat_type.npc_text
        local npc_cfg = npc_module:get_npc_cfg(form_id)
        if npc_cfg then
          name = npc_cfg.name
        end
      end
    else
      content_data = data.PlayerContent
      local entity = EntityUtil.get_player_entity_by_uid(form_id)
      if not is_null(entity) and entity.data then
        name = entity.data.name
      end
      if string.is_valid(content_data.InputText) then
        content = content_data.InputText
        chat_type = chat_module.chat_type.input_text
      elseif 0 < content_data.EmojiId then
        content = content_data.EmojiId
        chat_type = chat_module.chat_type.emoji_id
      elseif 0 < content_data.QuickTextId then
        local quick_chat_cfg = chat_module:get_def_chat_cfg_by_id(content_data.QuickTextId)
        if quick_chat_cfg ~= nil then
          content = quick_chat_cfg.content
        else
          content = "quick text error! id = " .. content_data.QuickTextId
        end
        chat_type = chat_module.chat_type.quick_text_id
      elseif content_data.SpecialHint == ChatSpecialHintType.ChatSpecialHintStartInput then
        chat_type = chat_module.chat_type.public_start_input
      elseif content_data.SpecialHint == ChatSpecialHintType.ChatSpecialHintEndInput then
        chat_type = chat_module.chat_type.public_end_input
      end
    end
  end
  local ret_data = {
    time = data.Time,
    from_uid = form_id,
    sequence = data.Sequence,
    content = content,
    chat_type = chat_type,
    is_public = is_public,
    is_npc = is_npc,
    name = name
  }
  return ret_data
end

function chat_module:get_cur_chat_uid()
  return self._cur_chat_uid or -1
end

function chat_module:set_cur_chat_uid(chat_uid)
  self._cur_chat_uid = chat_uid or -1
end

function chat_module:close_public_chat_cache()
  self._public_chat_tbl = {}
end

return chat_module
