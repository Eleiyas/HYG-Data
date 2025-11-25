chat_module = chat_module or {}

function chat_module:add_event()
  chat_module:remove_event()
  self._events = {}
  self._events[EventID.OnChannelChatNotify] = pack(self, chat_module._on_channel_chat_notify)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function chat_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function chat_module:_on_channel_chat_notify(notify)
  if not is_null(notify.Channel) and not is_null(notify.Channel.System) then
    return
  end
  if not is_null(notify.ChatUnit.SystemHint) then
    if player_module:get_player_uid() ~= notify.Channel.World.OwnerUid then
      return
    end
    if self._sys_hint_queue == nil then
      self._sys_hint_queue = {}
    end
    local sys_hint = notify.ChatUnit.SystemHint
    if string.is_valid(sys_hint.PlayerEnterWorld) then
      table.insert(self._sys_hint_queue, {
        chat_type = chat_module.chat_type.player_enter_world,
        name = sys_hint.PlayerEnterWorld
      })
    elseif string.is_valid(sys_hint.PlayerLeaveWorld) then
      table.insert(self._sys_hint_queue, {
        chat_type = chat_module.chat_type.player_leave_world,
        name = sys_hint.PlayerLeaveWorld
      })
    end
    if level_module:is_multi_scene() then
      chat_module:check_sys_hint_queue()
    end
    return
  end
  local uid = 0
  if not is_null(notify.Channel.PublicScene) then
    uid = notify.Channel.PublicScene.SceneId + chat_module.public_chat_value
  elseif not is_null(notify.Channel.World) then
    uid = notify.Channel.World.OwnerUid + chat_module.public_chat_value
  end
  if self._public_chat_tbl[uid] == nil then
    self._public_chat_tbl[uid] = {}
  end
  local data = chat_module:_get_chat_uint_data(notify.ChatUnit, true)
  if data.chat_type ~= chat_module.chat_type.public_end_input and data.chat_type ~= chat_module.chat_type.public_start_input then
    table.insert(self._public_chat_tbl[uid], data)
    if #self._public_chat_tbl[uid] > chat_module.chat_data_max_num then
      table.remove(self._public_chat_tbl[uid], 1)
    end
  end
  lua_event_module:send_event(lua_event_module.event_type.on_public_chat_ntf, data)
end

function chat_module:remove_chat_cache(uid)
  if self._chat_tbl[uid] then
    self._chat_tbl[uid] = nil
  end
end

function chat_module:clear_private_chat()
  local friend_list = social_module:get_friend_info_tbl()
  for uid, _ in pairs(self._chat_tbl) do
    if is_null(friend_list[uid]) then
      self:remove_chat_cache(uid)
    end
  end
end

function chat_module:_on_set_loading_state(state)
  if state then
    chat_module:close_public_chat_cache()
  elseif level_module:is_multi_scene() then
    if self._sys_hint_queue == nil then
      return
    end
    chat_module:check_sys_hint_queue()
  else
    self._sys_hint_queue = nil
  end
end

function chat_module:send_npc_chat(npc_id, chat_str)
  if self._tbl_all_npc_chat == nil then
    self._tbl_all_npc_chat = {}
  end
  if self._tbl_all_npc_chat[npc_id] == nil then
    self._tbl_all_npc_chat[npc_id] = {}
  end
  chat_module:check_npc_chat_num_by_id(npc_id)
  local send_data = {is_player = true, chat_str = chat_str}
  local reply_data = {
    is_reply_late = false,
    is_player = false,
    chat_str = nil,
    guid = 0
  }
  table.insert(self._tbl_all_npc_chat[npc_id], send_data)
  table.insert(self._tbl_all_npc_chat[npc_id], reply_data)
  local index = #self._tbl_all_npc_chat[npc_id]
  local guid = CsNLPModuleUtil.GetNLPResult(chat_str, chat_module.npc_chat_time_out, function(nlp_data)
    chat_module:_npc_chat_reply(npc_id, index, nlp_data)
  end)
  reply_data.guid = guid
  self._tbl_all_npc_chat_call_back_guid[guid] = 1
end

function chat_module:_npc_chat_reply(npc_id, index, nlp_data)
  local chat_data = chat_module:get_one_npc_chat_by_index(npc_id, index)
  if chat_data == nil then
    return
  end
  local guid = chat_data.guid
  self._tbl_all_npc_chat_call_back_guid[guid] = nil
  chat_data.is_reply_late = true
  if not is_null(nlp_data) then
    chat_data.chat_str = nlp_data.result
  else
    chat_data.chat_str = UIUtil.get_text_by_id("OnlineTalkTips1")
  end
  lua_event_module:send_event(lua_event_module.event_type.on_npc_chat_reply)
end

function chat_module:check_sys_hint_queue()
  if not self._sys_hint_queue or #self._sys_hint_queue <= 0 then
    self._is_show_sys_tips = false
    return
  end
  if self._is_show_sys_tips then
    return
  end
  self._is_show_sys_tips = true
  local sys_hint = self._sys_hint_queue[#self._sys_hint_queue]
  table.remove(self._sys_hint_queue, #self._sys_hint_queue)
  if chat_module:chat_is_enter_world(sys_hint) then
    chat_module:show_player_arrived_tips(sys_hint.name)
  elseif chat_module:chat_is_exit_world(sys_hint) then
    chat_module:show_player_leave_tips(sys_hint.name)
  end
end

function chat_module:chat_is_emoji(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.emoji_id
  end
  return false
end

function chat_module:chat_is_input_txt(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.input_text
  end
  return false
end

function chat_module:chat_is_quick_txt(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.quick_text_id
  end
  return false
end

function chat_module:chat_is_enter_world(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.player_enter_world
  end
  return false
end

function chat_module:chat_is_exit_world(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.player_leave_world
  end
  return false
end

function chat_module:chat_is_start_input(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.public_start_input
  end
  return false
end

function chat_module:chat_is_end_input(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.public_end_input
  end
  return false
end

function chat_module:chat_is_npc_txt(chat)
  if chat then
    return chat.chat_type == chat_module.chat_type.npc_text
  end
  return false
end

return chat_module
