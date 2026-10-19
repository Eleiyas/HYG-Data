family_comment_module = family_comment_module or {}

function family_comment_module:add_event()
  self:remove_event()
  self._events = {
    [EventID.OnPlayerVisitMsgBoardChange] = pack(self, family_comment_module._on_message_board_changed),
    [EventID.LuaMessageBoardLikeChange] = pack(self, family_comment_module._on_like_changed)
  }
  for event_id, callback in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, callback)
  end
end

function family_comment_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, callback in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, callback)
  end
  self._events = nil
end

function family_comment_module:_on_message_board_changed()
  lua_event_module:send_event(lua_event_module.event_type.family_comment_data_changed)
end

function family_comment_module:_on_like_changed()
  self._next_like_request_time = 0
  lua_event_module:send_event(lua_event_module.event_type.family_comment_like_changed)
end

function family_comment_module:set_liked(is_liked)
  local now = TimeUtil.ServerUtcTimeSeconds or 0
  if now < (self._next_like_request_time or 0) then
    return false
  end
  self._next_like_request_time = now + 1
  if is_liked then
    CsPlayerVisitModuleUtil.MessageBoardLikeReq()
  else
    CsPlayerVisitModuleUtil.MessageBoardCancelLikeReq()
  end
  return true
end

function family_comment_module:delete_comments(guid_list)
  CsPlayerVisitModuleUtil.MessageBoardDelMessageReq(guid_list)
end

function family_comment_module:delete_tags(tag_list)
  local tag_ids = CS.System.Collections.Generic.List(CS.System.UInt32)()
  for _, tag in ipairs(tag_list or {}) do
    if tag and tag.id then
      tag_ids:Add(tag.id)
    end
  end
  if tag_ids.Count > 0 then
    CsPlayerVisitModuleUtil.MessageBoardDeleteTagReq(tag_ids)
  end
end

function family_comment_module:read_comment(guid)
  if is_null(guid) then
    return false
  end
  self._locally_read_comment_guids = self._locally_read_comment_guids or {}
  if self._locally_read_comment_guids[guid] then
    return false
  end
  self._locally_read_comment_guids[guid] = true
  return true
end

function family_comment_module:read_all_comments(comments)
  local guid_list = {}
  for _, comment in ipairs(comments or {}) do
    if comment and not comment.IsRead and comment.Guid then
      table.insert(guid_list, comment.Guid)
    end
  end
  self._locally_read_comment_guids = {}
  if #guid_list == 0 then
    return
  end
  CsPlayerVisitModuleUtil.MessageBoardReadMessageReq(guid_list)
end

function family_comment_module:submit_comment(content, tags, callback)
  tags = tags or {}
  local tag_ids = CS.System.Collections.Generic.List(CS.System.UInt32)()
  for _, tag in ipairs(tags) do
    if tag.id then
      tag_ids:Add(tag.id)
    end
  end
  CsPlayerVisitModuleUtil.MessageBoardAddMessageReq(content or "", tag_ids, callback)
end

function family_comment_module:set_permission(permission)
  self._mock_permission = permission
  Logger.LogWarning("[FamilyComment] TODO: waiting for light tower permission protocol")
  return true
end

function family_comment_module:request_comment_translation(guid, content, target_language, callback)
  local cache_key = self:get_translation_cache_key(guid, target_language)
  local cached_translation = self._translation_cache[cache_key]
  if string.is_valid(cached_translation) then
    if callback then
      callback(true, cached_translation)
    end
    return true
  end
  if self._translation_pending[cache_key] ~= nil then
    self._translation_pending[cache_key] = callback or false
    return true
  end
  self._translation_pending[cache_key] = callback or false
  CsChatModuleUtil.RequestTranslateText(content, "", target_language, function(success, result, error_message)
    local latest_callback = self._translation_pending[cache_key]
    self._translation_pending[cache_key] = nil
    if not success or not string.is_valid(result) then
      Logger.LogWarning(string.format("[FamilyComment] Translate comment failed, target_language=%s, error=%s", tostring(target_language), tostring(error_message)))
      if type(latest_callback) == "function" then
        latest_callback(false, content)
      end
      return
    end
    self._translation_cache[cache_key] = result
    if type(latest_callback) == "function" then
      latest_callback(true, result)
    end
  end)
  return true
end

return family_comment_module
