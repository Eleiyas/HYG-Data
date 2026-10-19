local Base = require("UI/Codex/Module/ListRenderer/CodexListRendererBase")
local M = G.Class("CodexGroupedListRenderer", Base)
local list_item_ctl_class = "UI/Codex/TypePage/SubTypeListItem"
local creature_title_item_class = "UI/Codex/Creature/CodexUnitSetTitleItem"
local creature_title_child_name = "grouptitle"
local codex_module = _ENV.codex_module

function M:__ctor(panel)
  Base.__ctor(self, panel)
  self._creature_title_cls_map = {}
  self._creature_item_cls_map = {}
  self._creature_package_list = {}
  self._sorted_package_item_ids = {}
  self._node_rects = {}
end

function M:render(init_position, cached_collapsed_ids)
  self._last_reward_scroll_index = 0
  local panel = self._panel
  local scroller = panel:get_grouped_scroller()
  local scroll_rect = panel:get_grouped_scroll_rect()
  local flat_sr = panel:get_flat_scroll_rect()
  if not_null(flat_sr) then
    UIUtil.set_active(flat_sr, false)
  end
  local set_sr = panel:get_set_scroll_rect()
  if not_null(set_sr) then
    UIUtil.set_active(set_sr, false)
  end
  if is_null(scroller) then
    return
  end
  UIUtil.set_active(scroller, true)
  local collapsed_pkg_ids = cached_collapsed_ids or {}
  if not cached_collapsed_ids and init_position and self._creature_package_list and not is_null(scroller) then
    for i, group_data in ipairs(self._creature_package_list) do
      if scroller:IsNodeCollapsed(i - 1) then
        local pkg_id = self:_get_group_id(group_data)
        if 0 < pkg_id then
          collapsed_pkg_ids[pkg_id] = true
        end
      end
    end
  end
  self._creature_package_list = self:_collect_packages()
  if #self._creature_package_list == 0 then
    self:_fallback_flat(panel, scroller, scroll_rect, init_position)
    return
  end
  self._sorted_package_item_ids = self:_build_sorted_items()
  scroller:SetNodeCount(#self._creature_package_list)
  local flat_ids = {}
  for i, _ in ipairs(self._creature_package_list) do
    local node_idx = i - 1
    local sorted_ids = self._sorted_package_item_ids[i]
    local item_count = sorted_ids and #sorted_ids or 0
    scroller:Init(node_idx, 0, item_count, pack(self, M._on_item_bind), pack(self, M._on_node_init))
    local group_data = self._creature_package_list[i]
    local pkg_id = self:_get_group_id(group_data)
    if collapsed_pkg_ids[pkg_id] then
      scroller:CollapseNode(node_idx, 0)
    else
      scroller:ExpandNode(node_idx, 0)
    end
    if sorted_ids then
      for _, id in ipairs(sorted_ids) do
        table.insert(flat_ids, id)
      end
    end
  end
  if panel._sub_type_controller then
    panel._sub_type_controller:set_display_sequence(flat_ids)
  end
  scroller:RebindAllVisibleItems()
  if not_null(scroll_rect) then
    scroll_rect.normalizedPosition = init_position or Vector2(0, 1)
  else
    scroller:MoveToNode(0)
  end
end

function M:_fallback_flat(panel, scroller, scroll_rect, init_position)
  if not panel._sub_type_controller then
    return
  end
  local all_data = panel._sub_type_controller._item_id_to_data_tbl
  if not all_data then
    return
  end
  local is_pkg_sub = codex_module:is_package_sub_type(panel._sub_type_controller.sub_type)
  local ids = {}
  for id, data in pairs(all_data) do
    if is_pkg_sub or not data.IsPackage then
      table.insert(ids, id)
    end
  end
  local sort_mode = panel._sort_mode
  local SortMode = codex_module.CodexSortMode
  local seasonal_cache = {}
  for _, id in ipairs(ids) do
    local data = codex_module:get_data_by_id(id)
    seasonal_cache[id] = not is_null(data) and codex_module:is_seasonal(data) or false
  end
  if sort_mode == SortMode.Quality then
    local rank_cache = {}
    for _, id in ipairs(ids) do
      local data = codex_module:get_data_by_id(id)
      rank_cache[id] = not is_null(data) and not_null(data.ItemCfg) and data.ItemCfg.rank or 0
    end
    table.sort(ids, function(a, b)
      local sa, sb = seasonal_cache[a], seasonal_cache[b]
      if sa ~= sb then
        return sa
      end
      local ra, rb = rank_cache[a], rank_cache[b]
      if ra ~= rb then
        return ra > rb
      end
      return a < b
    end)
  elseif sort_mode == SortMode.CollectTime then
    local time_cache = {}
    for _, id in ipairs(ids) do
      local data = codex_module:get_data_by_id(id)
      time_cache[id] = not is_null(data) and (data.ServerData.UnlockTime or 0) or 0
    end
    table.sort(ids, function(a, b)
      local sa, sb = seasonal_cache[a], seasonal_cache[b]
      if sa ~= sb then
        return sa
      end
      local ta, tb = time_cache[a], time_cache[b]
      local ca, cb = 0 < ta, 0 < tb
      if ca ~= cb then
        return ca
      end
      if ca and ta ~= tb then
        return ta > tb
      end
      return a < b
    end)
  else
    table.sort(ids, function(a, b)
      local sa, sb = seasonal_cache[a], seasonal_cache[b]
      if sa ~= sb then
        return sa
      end
      return a < b
    end)
  end
  if panel._sort_order == codex_module.CodexSortOrder.Descending then
    local reversed = {}
    for j = #ids, 1, -1 do
      table.insert(reversed, ids[j])
    end
    ids = reversed
  end
  self._creature_package_list = {}
  self._sorted_package_item_ids = {
    [1] = ids
  }
  scroller:SetNodeCount(1)
  scroller:Init(0, 0, #ids, pack(self, M._on_item_bind), pack(self, M._on_node_init))
  scroller:ExpandNode(0, 0)
  if panel._sub_type_controller then
    panel._sub_type_controller:set_display_sequence(ids)
  end
  scroller:RebindAllVisibleItems()
  if not_null(scroll_rect) then
    scroll_rect.normalizedPosition = init_position or Vector2(0, 1)
  else
    scroller:MoveToNode(0)
  end
end

function M:deactivate()
  local scroller = self._panel:get_grouped_scroller()
  if not_null(scroller) then
    UIUtil.set_active(scroller, false)
  end
end

function M:stop_movement()
  local scroller = self._panel:get_grouped_scroller()
  if not is_null(scroller) then
    scroller:StopMovement()
  end
end

function M:record_position()
  local sr = self:_get_scroll_rect()
  if not_null(sr) then
    return sr.normalizedPosition
  end
  return nil
end

function M:scroll_to(position)
  local sr = self:_get_scroll_rect()
  if not_null(sr) then
    sr.normalizedPosition = position
    sr:StopMovement()
    self._panel:get_grouped_scroller():RebindAllVisibleItems()
  end
end

function M:scroll_to_first_reward_package()
  local scroller = self._panel:get_grouped_scroller()
  if is_null(scroller) then
    return false
  end
  local count = #self._creature_package_list
  if count == 0 then
    return false
  end
  local start = (self._last_reward_scroll_index or 0) + 1
  for offset = 0, count - 1 do
    local i = (start - 1 + offset) % count + 1
    local group_data = self._creature_package_list[i]
    local pkg_data = self:_get_package_data(group_data)
    local suite_data = pkg_data and pkg_data.ServerData and pkg_data.ServerData.Suite
    if not_null(suite_data) and 0 < suite_data.CompleteTime and not suite_data.IsCompleteRewardTaken then
      self._last_reward_scroll_index = i
      scroller:ExpandNode(i - 1, 0)
      scroller:MoveToNode(i - 1)
      scroller:StopMovement()
      scroller:RebindAllVisibleItems()
      return true
    end
  end
  return false
end

function M:_is_reward_claimable(pkg_index)
  local group_data = self._creature_package_list[pkg_index]
  local pkg_data = self:_get_package_data(group_data)
  if is_null(pkg_data) then
    return false
  end
  local suite_data = pkg_data.ServerData and pkg_data.ServerData.Suite
  return not_null(suite_data) and suite_data.CompleteTime > 0 and not suite_data.IsCompleteRewardTaken
end

function M:get_reward_directions()
  local scroll_rect = self._panel:get_grouped_scroll_rect()
  if is_null(scroll_rect) or is_null(scroll_rect.viewport) then
    return false, false
  end
  local scroll_pos = scroll_rect.content.anchoredPosition.y
  local viewport_h = scroll_rect.viewport.rect.height
  local view_top = scroll_pos
  local view_bottom = scroll_pos + viewport_h
  local has_above, has_below = false, false
  for i = 1, #self._creature_package_list do
    if self:_is_reward_claimable(i) then
      local rt = self._node_rects[i]
      if not_null(rt) then
        local node_top = -rt.anchoredPosition.y
        if view_top > node_top then
          has_above = true
        elseif view_bottom <= node_top then
          has_below = true
        end
      end
    end
    if has_above and has_below then
      break
    end
  end
  return has_above, has_below
end

function M:scroll_to_nearest_reward(direction)
  local scroller = self._panel:get_grouped_scroller()
  local scroll_rect = self._panel:get_grouped_scroll_rect()
  if is_null(scroller) or is_null(scroll_rect) or is_null(scroll_rect.viewport) then
    return false
  end
  local scroll_pos = scroll_rect.content.anchoredPosition.y
  local viewport_h = scroll_rect.viewport.rect.height
  local view_top = scroll_pos
  local view_bottom = scroll_pos + viewport_h
  local best_index
  for i = 1, #self._creature_package_list do
    if self:_is_reward_claimable(i) then
      local rt = self._node_rects[i]
      if not_null(rt) then
        local node_top = -rt.anchoredPosition.y
        if direction == "above" and view_top > node_top then
          best_index = i
          break
        elseif direction == "below" and view_bottom <= node_top then
          best_index = i
          break
        end
      end
    end
  end
  if best_index then
    scroller:ExpandNode(best_index - 1, 0)
    scroller:MoveToNode(best_index - 1)
    scroller:StopMovement()
    scroller:RebindAllVisibleItems()
    return true
  end
  return false
end

function M:scroll_to_item_id(id)
  if not id then
    return false
  end
  local scroller = self._panel:get_grouped_scroller()
  if is_null(scroller) then
    return false
  end
  for node_i, ids in ipairs(self._sorted_package_item_ids or {}) do
    for item_i, item_id in ipairs(ids) do
      if item_id == id then
        local node_idx = node_i - 1
        if scroller.ExpandNode then
          scroller:ExpandNode(node_idx, 0)
        end
        if scroller.MoveToItem then
          scroller:MoveToItem(node_idx, item_i - 1)
        elseif scroller.MoveToNode then
          scroller:MoveToNode(node_idx)
        end
        scroller:StopMovement()
        if scroller.RebindAllVisibleItems then
          scroller:RebindAllVisibleItems()
        end
        return true
      end
    end
  end
  return false
end

function M:save_grouped_state()
  local scroller = self._panel:get_grouped_scroller()
  if is_null(scroller) then
    return nil
  end
  local collapsed = {}
  for i, group_data in ipairs(self._creature_package_list) do
    if scroller:IsNodeCollapsed(i - 1) then
      local pkg_id = self:_get_group_id(group_data)
      if 0 < pkg_id then
        collapsed[pkg_id] = true
      end
    end
  end
  local scroll_pos = self:record_position()
  return {collapsed_ids = collapsed, scroll_position = scroll_pos}
end

function M:close()
  local scroller = self._panel:get_grouped_scroller()
  if not is_null(scroller) then
    scroller:Close()
  end
end

function M:_get_scroll_rect()
  return self._panel:get_grouped_scroll_rect()
end

function M:_on_node_init(node_trans, node_index)
  local rt = node_trans:GetComponent(typeof(CS.UnityEngine.RectTransform))
  self._node_rects[node_index + 1] = rt
  local title_trans = node_trans:Find(creature_title_child_name)
  if is_null(title_trans) then
    return
  end
  local obj_id = title_trans:GetInstanceID()
  local title_cls = self._creature_title_cls_map[obj_id]
  if not title_cls then
    title_cls = self._panel:add_panel(creature_title_item_class, title_trans)
    self._creature_title_cls_map[obj_id] = title_cls
  end
  local group_data = self._creature_package_list[node_index + 1]
  local pkg_data = self:_get_package_data(group_data)
  if is_null(pkg_data) then
    title_cls:set_active(false)
    return
  end
  title_cls:set_active(true)
  local scroller = self._panel:get_grouped_scroller()
  title_cls:refresh({
    package_data = pkg_data,
    is_expanded = not scroller:IsNodeCollapsed(node_index),
    scroller = scroller,
    node_index = node_index
  })
  if node_index == 0 then
    if not_null(title_cls._tutorial_grouptitle) then
      title_cls._tutorial_grouptitle:ActiveDynamicTutorialKey(TutorialUIKey.GalleryHandbook_CodexSetTitle)
    end
    if not_null(title_cls._tutorial_reward) then
      title_cls._tutorial_reward:ActiveDynamicTutorialKey(TutorialUIKey.GalleryHandbook_CodexSetReward)
    end
  end
end

function M:_on_item_bind(item_trans, node_index, item_index)
  local item_obj_id = item_trans:GetInstanceID()
  local item_cls = self._creature_item_cls_map[item_obj_id]
  if not item_cls then
    item_cls = self._panel:add_panel(list_item_ctl_class, item_trans)
    self._creature_item_cls_map[item_obj_id] = item_cls
  end
  local sorted_ids = self._sorted_package_item_ids[node_index + 1]
  if not sorted_ids then
    return
  end
  local id = sorted_ids[item_index + 1]
  local data = id and codex_module:get_data_by_id(id) or nil
  if not is_null(data) then
    item_cls:refresh({
      item_obj_id = item_obj_id,
      data = data,
      sequence = item_index + 1,
      group_index = 0
    })
  end
  self._panel:register_visible_new_item_candidate(data, item_trans)
end

function M:_get_package_data(group_data)
  if is_null(group_data) then
    return nil
  end
  return group_data.package_data or group_data
end

function M:_get_group_id(group_data)
  if is_null(group_data) then
    return 0
  end
  if group_data.group_id then
    return group_data.group_id
  end
  local package_data = self:_get_package_data(group_data)
  return package_data and package_data.IdCfg and package_data.IdCfg.id or 0
end

function M:_get_group_item_ids(group_data)
  if is_null(group_data) then
    return {}
  end
  if group_data.item_ids then
    local result = {}
    for _, id in ipairs(group_data.item_ids) do
      table.insert(result, id)
    end
    return result
  end
  local package_data = self:_get_package_data(group_data)
  local result = {}
  if not is_null(package_data) and not is_null(package_data.PackageItemIds) then
    for i = 0, package_data.PackageItemIds.Count - 1 do
      table.insert(result, package_data.PackageItemIds[i])
    end
  end
  return result
end

function M:_collect_packages()
  local panel = self._panel
  local package_list = {}
  if not panel._sub_type_controller then
    return package_list
  end
  if panel._view_strategy and panel._view_strategy.get_grouped_package_list then
    local strategy_groups = panel._view_strategy:get_grouped_package_list(panel._sub_type_controller)
    if strategy_groups and 0 < #strategy_groups then
      return strategy_groups
    end
  end
  local all_data = panel._sub_type_controller._item_id_to_data_tbl
  if not all_data then
    return package_list
  end
  for _, data in pairs(all_data) do
    if data.IsPackage then
      table.insert(package_list, data)
    end
  end
  local priority_cache = {}
  
  local function get_display_priority(data)
    local id = data and data.IdCfg and data.IdCfg.id or 0
    if id <= 0 then
      return 0
    end
    if priority_cache[id] ~= nil then
      return priority_cache[id]
    end
    local codex_cfg = ExcelDataUtil.get_value(typeof(BCodexCfg), id)
    local priority = not is_null(codex_cfg) and codex_cfg.displaypriority or 0
    priority_cache[id] = priority
    return priority
  end
  
  table.sort(package_list, function(a, b)
    local sea_a = codex_module:is_seasonal(a)
    local sea_b = codex_module:is_seasonal(b)
    if sea_a ~= sea_b then
      return sea_a
    end
    local p_a = get_display_priority(a)
    local p_b = get_display_priority(b)
    if p_a ~= p_b then
      return p_a > p_b
    end
    return a.IdCfg.id < b.IdCfg.id
  end)
  return package_list
end

function M:_build_sorted_items()
  local panel = self._panel
  local result = {}
  local sort_mode = panel._sort_mode
  local SortMode = codex_module.CodexSortMode
  for i, group_data in ipairs(self._creature_package_list) do
    local ids = self:_get_group_item_ids(group_data)
    if sort_mode == SortMode.Default then
      table.sort(ids, function(id_a, id_b)
        return id_a < id_b
      end)
    elseif sort_mode == SortMode.Quality then
      local rank_cache = {}
      for _, id in ipairs(ids) do
        local data = codex_module:get_data_by_id(id)
        rank_cache[id] = not is_null(data) and not_null(data.ItemCfg) and data.ItemCfg.rank or 0
      end
      table.sort(ids, function(id_a, id_b)
        local rank_a, rank_b = rank_cache[id_a], rank_cache[id_b]
        if rank_a ~= rank_b then
          return rank_a > rank_b
        end
        return id_a < id_b
      end)
    elseif sort_mode == SortMode.CollectTime then
      local time_cache = {}
      for _, id in ipairs(ids) do
        local data = codex_module:get_data_by_id(id)
        time_cache[id] = not is_null(data) and (data.ServerData.UnlockTime or 0) or 0
      end
      table.sort(ids, function(id_a, id_b)
        local time_a, time_b = time_cache[id_a], time_cache[id_b]
        local collected_a = 0 < time_a
        local collected_b = 0 < time_b
        if collected_a ~= collected_b then
          return collected_a
        end
        if collected_a and time_a ~= time_b then
          return time_a > time_b
        end
        return id_a < id_b
      end)
    end
    if panel._sort_order == codex_module.CodexSortOrder.Descending then
      local reversed = {}
      for j = #ids, 1, -1 do
        table.insert(reversed, ids[j])
      end
      ids = reversed
    end
    result[i] = ids
  end
  return result
end

return M
