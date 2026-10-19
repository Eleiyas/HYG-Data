rabbit_tabletop_module = rabbit_tabletop_module or {}
local MAIN_PAGE_CLS = "UI/RabbitTabletop/RabbitTabletopMainPage"

function rabbit_tabletop_module:add_event()
  rabbit_tabletop_module:remove_event()
  self._events = {}
  self._events[EventIDTags.Tags.eventid_tabletopgame_tutucard_startjoingame] = pack(self, rabbit_tabletop_module._on_tutucard_start_join_game)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function rabbit_tabletop_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function rabbit_tabletop_module:_on_tutucard_start_join_game(...)
  UIManagerInstance:pre_open(MAIN_PAGE_CLS)
end

function rabbit_tabletop_module:set_in_game(value)
  self._is_in_game = value
end

function rabbit_tabletop_module:is_in_game()
  return self._is_in_game
end

function rabbit_tabletop_module:generate_and_refresh_items(uiwindow, pool, item_datas, prefab_transform, parent_transform, item_cls, refresh_callback, insert_before_transform)
  if is_null(uiwindow) or is_null(pool) or is_null(prefab_transform) or is_null(parent_transform) then
    return
  end
  self:_reset_items(pool.active, pool.pool)
  for _, item_data in ipairs(item_datas) do
    self:_add_item(uiwindow, pool.pool, pool.active, prefab_transform, parent_transform, item_cls, item_data, refresh_callback, insert_before_transform)
  end
end

function rabbit_tabletop_module:_add_item(uiwindow, item_pool, active_items, prefab_transform, parent_transform, panel_class, item_data, refresh_callback, insert_before_transform)
  local item
  if 0 < #item_pool then
    item = table.remove(item_pool)
  else
    local obj = UIUtil.load_prefab_set_parent(prefab_transform.gameObject, parent_transform)
    if is_null(obj) then
      return nil
    end
    if panel_class then
      item = uiwindow:add_panel(panel_class, obj)
      if is_null(item) then
        return nil
      end
    else
      item = obj
    end
  end
  if item.trans then
    item.trans:SetParent(parent_transform)
    self:_set_item_sibling(item.trans, insert_before_transform)
    item:set_active(true)
  else
    item.transform:SetParent(parent_transform)
    self:_set_item_sibling(item.transform, insert_before_transform)
    UIUtil.set_active(item, true)
  end
  if refresh_callback and type(refresh_callback) == "function" then
    refresh_callback(item, item_data)
  end
  table.insert(active_items, item)
  return item
end

function rabbit_tabletop_module:_set_item_sibling(item_transform, insert_before_transform)
  if not is_null(insert_before_transform) then
    local target_idx = insert_before_transform:GetSiblingIndex()
    local current_idx = item_transform:GetSiblingIndex()
    if target_idx > current_idx then
      target_idx = target_idx - 1
    end
    item_transform:SetSiblingIndex(target_idx)
  else
    item_transform:SetAsLastSibling()
  end
end

function rabbit_tabletop_module:_reset_items(active_items, item_pool)
  for _, item in ipairs(active_items) do
    if item.trans then
      item:set_active(false)
    else
      UIUtil.set_active(item, false)
    end
    table.insert(item_pool, item)
  end
  table.clear(active_items)
end

return rabbit_tabletop_module
