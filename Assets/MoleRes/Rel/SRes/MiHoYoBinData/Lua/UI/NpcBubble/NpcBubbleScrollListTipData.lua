local RECORD_LIMIT = 4
local M = {
  remove_source_on_overflow = true,
  _records = {},
  _edge_guids = {},
  _visibility = {},
  _limit_owners = {},
  _display_limit = 4,
  _view = nil
}

local function remove_guid(list, guid)
  for index = #list, 1, -1 do
    if list[index] == guid then
      table.remove(list, index)
      return true
    end
  end
  return false
end

function M:_notify_view()
  if self._view and self._view.on_edge_bubble_data_changed then
    self._view:on_edge_bubble_data_changed(self:get_edge_records(), self._display_limit)
  end
end

function M:_append_to_edge(record)
  remove_guid(self._edge_guids, record.key)
  table.insert(self._edge_guids, record.key)
  record.is_in_edge = true
end

function M:_remove_from_edge(record)
  if remove_guid(self._edge_guids, record.key) then
    record.is_in_edge = false
    return true
  end
  record.is_in_edge = false
  return false
end

function M:_enforce_limit()
  while #self._edge_guids > RECORD_LIMIT do
    local key = table.remove(self._edge_guids, 1)
    local record = self._records[key]
    if record then
      record.is_in_edge = false
      if self.remove_source_on_overflow then
        local finish_source = record.finish_source
        self._records[key] = nil
        self._visibility[key] = nil
        if finish_source then
          finish_source()
        end
      else
        record.overflow_hidden = true
      end
    end
  end
end

function M:bind_view(view)
  self._view = view
  self:_notify_view()
end

function M:unbind_view(view)
  if self._view == view then
    self._view = nil
  end
end

function M:_refresh_limit()
  local limit = 4
  for _, value in pairs(self._limit_owners) do
    limit = math.min(limit, value)
  end
  if self._display_limit == limit then
    return
  end
  self._display_limit = limit
  self:_notify_view()
end

function M:set_limit(owner, max_count)
  if not owner then
    return
  end
  self._limit_owners[owner] = max_count
  self:_refresh_limit()
end

function M:clear_limit(owner)
  if not owner or self._limit_owners[owner] == nil then
    return
  end
  self._limit_owners[owner] = nil
  self:_refresh_limit()
end

function M:register_bubble(guid, icon_path, finish_source)
  if not guid or guid == 0 then
    return
  end
  local key = tostring(guid)
  local record = self._records[key]
  if not record then
    record = {
      guid = guid,
      key = key,
      world_visible = self._visibility[key] ~= false
    }
    self._records[key] = record
  else
    self:_remove_from_edge(record)
  end
  record.icon_path = icon_path
  record.finish_source = finish_source
  record.overflow_hidden = false
  if not record.world_visible then
    self:_append_to_edge(record)
    self:_enforce_limit()
  end
  self:_notify_view()
end

function M:update_text(guid, text)
  local record = self._records[tostring(guid)]
  if not record then
    return
  end
  record.text = text or ""
  self:_notify_view()
end

function M:set_world_visible(guid, is_visible)
  local key = tostring(guid)
  self._visibility[key] = is_visible
  local record = self._records[key]
  if not record or record.world_visible == is_visible then
    return
  end
  record.world_visible = is_visible
  if is_visible then
    record.overflow_hidden = false
    self:_remove_from_edge(record)
  elseif not record.overflow_hidden then
    self:_append_to_edge(record)
    self:_enforce_limit()
  end
  self:_notify_view()
end

function M:remove_bubble(guid)
  local key = tostring(guid)
  local record = self._records[key]
  if record then
    self:_remove_from_edge(record)
    self._records[key] = nil
  end
  self._visibility[key] = nil
  self:_notify_view()
end

function M:clear()
  table.clear(self._records)
  table.clear(self._edge_guids)
  table.clear(self._visibility)
  self:_notify_view()
end

function M:get_edge_records()
  local records = {}
  local first_index = math.max(1, #self._edge_guids - self._display_limit + 1)
  for index = first_index, #self._edge_guids do
    local key = self._edge_guids[index]
    local record = self._records[key]
    if record then
      table.insert(records, record)
    end
  end
  return records
end

return M
