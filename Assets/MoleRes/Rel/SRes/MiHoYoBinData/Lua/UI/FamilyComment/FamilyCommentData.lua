family_comment_module = family_comment_module or {}

function family_comment_module:_init_data()
  self._mock_permission = 0
  self._next_like_request_time = 0
  self._locally_read_comment_guids = {}
  self._translation_cache = {}
  self._translation_pending = {}
end

function family_comment_module:get_translation_cache_key(guid, target_language)
  return (target_language or "") .. "\000" .. tostring(guid or "")
end

function family_comment_module:get_cached_translation(guid, target_language)
  local cache_key = self:get_translation_cache_key(guid, target_language)
  return self._translation_cache and self._translation_cache[cache_key]
end

function family_comment_module:is_translation_pending(guid, target_language)
  local cache_key = self:get_translation_cache_key(guid, target_language)
  return self._translation_pending and self._translation_pending[cache_key] ~= nil
end

function family_comment_module:get_comments()
  return list_to_table(CsPlayerVisitModuleUtil.VisibleMessageBoardDataList)
end

function family_comment_module:get_like_count()
  return CsPlayerVisitModuleUtil.LikeCount or 0
end

function family_comment_module:is_liked()
  local uid = player_module:get_player_uid()
  return CsPlayerVisitModuleUtil.IsTodayLike(uid)
end

function family_comment_module:is_comment_locally_read(guid)
  return guid ~= nil and self._locally_read_comment_guids ~= nil and self._locally_read_comment_guids[guid] ~= nil
end

function family_comment_module:get_comment_tags(comment)
  local tags = {}
  if is_null(comment) then
    return tags
  end
  local tag_list = comment.TagList
  if type(tag_list) ~= "table" then
    tag_list = list_to_table(tag_list)
  end
  for _, tag_id in ipairs(tag_list or {}) do
    local tag_text = self:get_social_tag_rich_text(tag_id)
    if string.is_valid(tag_text) then
      table.insert(tags, tag_text)
    end
  end
  return tags
end

function family_comment_module:get_permission()
  return self._mock_permission or 0
end

return family_comment_module
