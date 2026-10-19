local M = {}

function M.new()
  local instance = {
    _selected_goods_by_slot = {},
    _selected_goods_id_map = {},
    _selected_goods_list = {},
    _selection_order = {},
    _latest_selected_goods = nil
  }
  return setmetatable(instance, {__index = M})
end

function M:clear_selection()
  local removed_goods_list = self:_collect_unique_selected_goods()
  table.clear(self._selected_goods_by_slot)
  table.clear(self._selected_goods_id_map)
  table.clear(self._selected_goods_list)
  table.clear(self._selection_order)
  self._latest_selected_goods = nil
  return self:_build_selection_snapshot(nil, removed_goods_list, nil, 0 < #removed_goods_list)
end

function M:toggle_goods(goods, view_state)
  if is_null(goods) then
    return self:_build_selection_snapshot()
  end
  if view_state and (view_state.is_not_wearable or view_state.is_sold_out) then
    return self:_build_selection_snapshot()
  end
  local slot_list = self:_get_goods_slot_list(goods)
  local goods_key = npc_cloth_module.get_goods_key(goods)
  local changed_goods_key_map = {}
  local removed_goods_list = {}
  local added_goods_list = {}
  self:_mark_changed_goods_key(changed_goods_key_map, self._latest_selected_goods)
  self:_mark_changed_goods_key(changed_goods_key_map, goods)
  if self:_is_goods_in_slot_map(goods_key) then
    local old_goods = self:_remove_goods_from_slot_map(goods_key)
    if old_goods then
      removed_goods_list[#removed_goods_list + 1] = old_goods
    end
    self:_remove_selection_order(goods_key)
    self._latest_selected_goods = old_goods or goods
  else
    local conflict_goods_map = self:_collect_conflict_goods(slot_list)
    for conflict_key, conflict_goods in pairs(conflict_goods_map) do
      self:_mark_changed_goods_key(changed_goods_key_map, conflict_goods)
      removed_goods_list[#removed_goods_list + 1] = conflict_goods
      self:_remove_goods_from_slot_map(conflict_key)
      self:_remove_selection_order(conflict_key)
    end
    self:_write_goods_to_slot_map(goods, slot_list, goods_key)
    self:_push_selection_order(goods_key)
    self._latest_selected_goods = goods
    added_goods_list[#added_goods_list + 1] = goods
  end
  self:_rebuild_selected_cache()
  self:_mark_changed_goods_key(changed_goods_key_map, self._latest_selected_goods)
  return self:_build_selection_snapshot(changed_goods_key_map, removed_goods_list, added_goods_list)
end

function M:revalidate_selection(context)
  local changed_goods_key_map = {}
  local removed_goods_list = {}
  local old_latest_goods = self._latest_selected_goods
  local unique_goods_list = self:_collect_unique_selected_goods()
  for _, goods in ipairs(unique_goods_list) do
    if self:_is_goods_invalid_for_context(goods, context) then
      local goods_key = npc_cloth_module.get_goods_key(goods)
      self:_mark_changed_goods_key(changed_goods_key_map, goods)
      removed_goods_list[#removed_goods_list + 1] = goods
      self:_remove_goods_from_slot_map(goods_key)
      self:_remove_selection_order(goods_key)
    end
  end
  self:_rebuild_selected_cache()
  self:_mark_changed_goods_key(changed_goods_key_map, old_latest_goods)
  self:_mark_changed_goods_key(changed_goods_key_map, self._latest_selected_goods)
  return self:_build_selection_snapshot(changed_goods_key_map, removed_goods_list, nil, next(changed_goods_key_map) ~= nil)
end

function M:reconcile_selection(shop_groups, context)
  local latest_goods_by_guid = self:_build_latest_goods_by_guid(shop_groups)
  local changed_goods_key_map = {}
  local removed_goods_list = {}
  local old_latest_goods = self._latest_selected_goods
  local need_refresh_preview = false
  local unique_goods_list = self:_collect_unique_selected_goods()
  for _, goods in ipairs(unique_goods_list) do
    local goods_key = npc_cloth_module.get_goods_key(goods)
    local latest_goods = latest_goods_by_guid[goods.GUID or 0]
    if is_null(latest_goods) or self:_is_goods_invalid_for_context(latest_goods, context, true) then
      self:_mark_changed_goods_key(changed_goods_key_map, goods)
      removed_goods_list[#removed_goods_list + 1] = goods
      self:_remove_goods_from_slot_map(goods_key)
      self:_remove_selection_order(goods_key)
      need_refresh_preview = true
    elseif not self:_should_keep_selected_goods_snapshot(latest_goods, context) then
      self:_replace_goods_in_slot_map(goods_key, latest_goods)
      self:_mark_changed_goods_key(changed_goods_key_map, goods)
      self:_mark_changed_goods_key(changed_goods_key_map, latest_goods)
      local latest_key = npc_cloth_module.get_goods_key(latest_goods)
      if 0 < latest_key and latest_key ~= goods_key then
        self:_remove_selection_order(goods_key)
        self:_push_selection_order(latest_key)
      end
      if self:_is_same_goods(self._latest_selected_goods, goods) then
        self._latest_selected_goods = latest_goods
      end
      need_refresh_preview = need_refresh_preview or goods ~= latest_goods
    end
  end
  self:_rebuild_selected_cache()
  self:_clear_latest_if_not_selected()
  self:_mark_changed_goods_key(changed_goods_key_map, old_latest_goods)
  self:_mark_changed_goods_key(changed_goods_key_map, self._latest_selected_goods)
  return self:_build_selection_snapshot(changed_goods_key_map, removed_goods_list, nil, need_refresh_preview or next(changed_goods_key_map) ~= nil)
end

function M:get_selected_goods_list()
  local result = {}
  for index, goods in ipairs(self._selected_goods_list or {}) do
    result[index] = goods
  end
  return result
end

function M:_build_latest_goods_by_guid(shop_groups)
  local result = {}
  for _, group_data in ipairs(shop_groups or {}) do
    for _, goods in ipairs(group_data.items or {}) do
      local guid = goods.GUID or 0
      if 0 < guid then
        result[guid] = goods
      end
    end
  end
  return result
end

function M:_is_goods_invalid_for_context(goods, context, is_reconcile)
  local shape = context and context.mannequin_shape or nil
  if goods == nil then
    return true
  end
  if (goods.ItemCount or 0) <= 0 and (not is_reconcile or not self:_should_keep_selected_goods_snapshot(goods, context)) then
    return true
  end
  if goods.IsHostOnly == true and not player_module:is_local_player_scene_owner() then
    return true
  end
  local npc_id = context and context.mannequin_npc_id or 0
  if shape ~= nil then
    if 0 < npc_id then
      if not npc_cloth_module.is_item_wearable_by_npc(goods, npc_id, shape) then
        return true
      end
    elseif not npc_cloth_module.is_goods_wearable_by_shape(goods, shape) then
      return true
    end
  end
  return false
end

function M:_should_keep_selected_goods_snapshot(latest_goods, context)
  local keep_map = context and context.keep_selection_after_buy_guid_map or nil
  local goods_guid = latest_goods and latest_goods.GUID or 0
  return keep_map ~= nil and 0 < goods_guid and keep_map[goods_guid] == true and 0 >= (latest_goods.ItemCount or 0)
end

function M:_get_goods_slot_list(goods)
  local slot_set = npc_cloth_module.get_outfit_slot_set(goods)
  if next(slot_set) ~= nil then
    local slot_list = {}
    for slot_id, _ in pairs(slot_set) do
      slot_list[#slot_list + 1] = slot_id
    end
    return slot_list
  end
  return {
    npc_cloth_module.get_goods_key(goods)
  }
end

function M:_push_selection_order(goods_key)
  self:_remove_selection_order(goods_key)
  self._selection_order[#self._selection_order + 1] = goods_key
end

function M:_remove_selection_order(goods_key)
  for index = #self._selection_order, 1, -1 do
    if self._selection_order[index] == goods_key then
      table.remove(self._selection_order, index)
      return
    end
  end
end

function M:_is_goods_in_slot_map(goods_key)
  for _, goods in pairs(self._selected_goods_by_slot) do
    if npc_cloth_module.get_goods_key(goods) == goods_key then
      return true
    end
  end
  return false
end

function M:_remove_goods_from_slot_map(goods_key)
  local removed_goods
  for slot_id, goods in pairs(self._selected_goods_by_slot) do
    if npc_cloth_module.get_goods_key(goods) == goods_key then
      removed_goods = goods
      self._selected_goods_by_slot[slot_id] = nil
    end
  end
  return removed_goods
end

function M:_write_goods_to_slot_map(goods, slot_list, goods_key)
  for _, slot_id in ipairs(slot_list) do
    self._selected_goods_by_slot[slot_id] = goods
  end
end

function M:_collect_conflict_goods(slot_list)
  local conflict_map = {}
  for _, slot_id in ipairs(slot_list) do
    local existed = self._selected_goods_by_slot[slot_id]
    if existed then
      conflict_map[npc_cloth_module.get_goods_key(existed)] = existed
    end
  end
  return conflict_map
end

function M:_replace_goods_in_slot_map(old_goods_key, latest_goods)
  for slot_id, goods in pairs(self._selected_goods_by_slot) do
    if npc_cloth_module.get_goods_key(goods) == old_goods_key then
      self._selected_goods_by_slot[slot_id] = latest_goods
    end
  end
end

function M:_collect_unique_selected_goods()
  local result = {}
  local seen = {}
  for _, goods in pairs(self._selected_goods_by_slot) do
    local goods_key = npc_cloth_module.get_goods_key(goods)
    if 0 < goods_key and seen[goods_key] == nil then
      seen[goods_key] = true
      result[#result + 1] = goods
    end
  end
  local order_rank = {}
  for index, goods_key in ipairs(self._selection_order) do
    order_rank[goods_key] = index
  end
  table.sort(result, function(a, b)
    local ra = order_rank[npc_cloth_module.get_goods_key(a)] or 999999
    local rb = order_rank[npc_cloth_module.get_goods_key(b)] or 999999
    return ra < rb
  end)
  return result
end

function M:_rebuild_selected_cache()
  table.clear(self._selected_goods_id_map)
  table.clear(self._selected_goods_list)
  for _, goods in ipairs(self:_collect_unique_selected_goods()) do
    self._selected_goods_id_map[npc_cloth_module.get_goods_key(goods)] = true
    self._selected_goods_list[#self._selected_goods_list + 1] = goods
  end
end

function M:_is_same_goods(left, right)
  local left_key = npc_cloth_module.get_goods_key(left)
  local right_key = npc_cloth_module.get_goods_key(right)
  return 0 < left_key and left_key == right_key
end

function M:_clear_latest_if_not_selected()
  if not self._latest_selected_goods then
    return
  end
  local latest_key = npc_cloth_module.get_goods_key(self._latest_selected_goods)
  if 0 < latest_key and self._selected_goods_id_map[latest_key] == true then
    return
  end
  self._latest_selected_goods = nil
end

function M:_mark_changed_goods_key(changed_goods_key_map, goods)
  local goods_key = npc_cloth_module.get_goods_key(goods)
  if 0 < goods_key then
    changed_goods_key_map[goods_key] = true
  end
end

function M:_mark_changed_goods_list_key(changed_goods_key_map, goods_list)
  for _, goods in ipairs(goods_list or {}) do
    self:_mark_changed_goods_key(changed_goods_key_map, goods)
  end
end

function M:_build_selection_snapshot(changed_goods_key_map, removed_goods_list, added_goods_list, need_refresh_preview)
  return {
    selected_goods_by_slot = self._selected_goods_by_slot,
    selected_goods_id_map = self._selected_goods_id_map,
    selected_goods_list = self._selected_goods_list,
    latest_selected_goods = self._latest_selected_goods,
    changed_goods_key_map = changed_goods_key_map,
    removed_goods_list = removed_goods_list,
    added_goods_list = added_goods_list,
    need_refresh_preview = need_refresh_preview == true
  }
end

return M
