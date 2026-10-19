local M = G.Class("NpcClothShopListPanel", G.UIPanel)
local base = G.UIPanel
local DEFAULT_SHOP_ITEM_CLS = "UI/NpcCloth/NpcClothGelianShopItem"
local DEFAULT_SHOP_GROUP_CLS = "UI/NpcCloth/NpcClothGelianShopGroupItem"
local LIMITED_TIME_REFRESH_INTERVAL = 60
local LIMITED_TIME_REFRESH_COUNT_PER_FRAME = 4

function M:init()
  base.init(self)
  self._shop_item_cls = DEFAULT_SHOP_ITEM_CLS
  self._shop_group_cls = DEFAULT_SHOP_GROUP_CLS
  self._shop_groups = {}
  self._shop_items = {}
  self._group_items = {}
  self._limited_time_refresh_items = {}
  self._limited_time_refresh_acc = 0
  self._limited_time_refresh_index = 0
  self._group_signature = nil
  self._item_context = {}
  self._current_node_changed_cb = nil
end

function M:on_destroy()
  self:_clear_current_node_changed_handler()
  if self._scroll_cloth_group then
    self._scroll_cloth_group:Close()
  end
end

function M:update(delta_time)
  self:_update_limited_time_items(delta_time)
end

function M:setup(options)
  options = options or {}
  self._shop_item_cls = options.shop_item_cls or self._shop_item_cls or DEFAULT_SHOP_ITEM_CLS
  self._shop_group_cls = options.shop_group_cls or self._shop_group_cls or DEFAULT_SHOP_GROUP_CLS
end

function M:refresh(groups, item_context)
  self._shop_groups = groups or {}
  self._item_context = item_context or {}
  local old_signature = self._group_signature
  local new_signature = self:_get_group_signature()
  self._group_signature = new_signature
  self:_refresh_grouped_scroller(old_signature ~= new_signature)
end

function M:reset_view_state()
  self._group_signature = nil
  self._limited_time_refresh_acc = 0
  self._limited_time_refresh_index = 0
  table.clear(self._limited_time_refresh_items)
end

function M:scroll_to_group(group_id)
  local node_index = self:_get_group_node_index(group_id)
  if node_index and self._scroll_cloth_group then
    local visible_goods_key_set = self:_collect_visible_goods_key_set()
    self._scroll_cloth_group:MoveToNode(node_index)
    self:_replay_retained_visible_item_enter(visible_goods_key_set)
  end
end

function M:_collect_visible_goods_key_set()
  local result = {}
  for _, item in pairs(self._shop_items) do
    if item.get_goods_key and item:is_active_in_hierarchy() then
      local goods_key = item:get_goods_key()
      if 0 < goods_key then
        result[goods_key] = true
      end
    end
  end
  return result
end

function M:_replay_retained_visible_item_enter(old_goods_key_set)
  for _, item in pairs(self._shop_items) do
    if item.get_goods_key and item.replay_enter_animation and item:is_active_in_hierarchy() and old_goods_key_set[item:get_goods_key()] == true then
      item:replay_enter_animation()
    end
  end
end

function M:refresh_visible_items(item_context)
  if item_context then
    self._item_context = item_context
  end
  if self._scroll_cloth_group then
    self._scroll_cloth_group:RebindAllVisibleItems()
  end
end

function M:refresh_visible_goods(item_context, goods_key_map)
  if item_context then
    self._item_context = item_context
  end
  for _, item in pairs(self._shop_items) do
    if item:is_active_in_hierarchy() and item:has_goods_key(goods_key_map) then
      item:refresh_current(self._item_context)
    end
  end
end

function M:refresh_visible_tracking_items(tracking_context)
  if self._item_context then
    self._item_context.tracking_context = tracking_context
  end
  for _, item in pairs(self._shop_items) do
    if item:is_active_in_hierarchy() then
      item:refresh_tracking_point_state(tracking_context)
    end
  end
end

function M:_refresh_grouped_scroller(should_move_top)
  if is_null(self._scroll_cloth_group) then
    return
  end
  self:_clear_current_node_changed_handler()
  self._scroll_cloth_group:SetNodeCount(#self._shop_groups)
  for group_index, group_data in ipairs(self._shop_groups) do
    local node_index = group_index - 1
    local item_count = group_data.items and #group_data.items or 0
    self._scroll_cloth_group:Init(node_index, 0, item_count, pack(self, M._on_group_item_bind), pack(self, M._on_group_node_init))
  end
  self._scroll_cloth_group:RebindAllVisibleItems()
  if should_move_top and #self._shop_groups > 0 then
    self._scroll_cloth_group:MoveToNode(0)
  end
  self:_refresh_current_node_changed_handler()
end

function M:_on_group_node_init(node_trans, node_index)
  local instance_id = node_trans:GetInstanceID()
  local group_item = self._group_items[instance_id]
  if not group_item then
    group_item = self:add_panel(self._shop_group_cls, node_trans)
    self._group_items[instance_id] = group_item
  end
  group_item:refresh(self._shop_groups[node_index + 1])
end

function M:_on_group_item_bind(item_trans, node_index, item_index)
  local instance_id = item_trans:GetInstanceID()
  local item = self._shop_items[instance_id]
  if not item then
    item = self:add_panel(self._shop_item_cls, item_trans)
    self._shop_items[instance_id] = item
  end
  local group_data = self._shop_groups[node_index + 1]
  local goods = group_data and group_data.items and group_data.items[item_index + 1] or nil
  item:refresh(goods, self._item_context)
end

function M:_get_group_node_index(group_id)
  for index, group_data in ipairs(self._shop_groups or {}) do
    if group_data.group_id == group_id or group_data.category_id == group_id then
      return index - 1
    end
  end
  return nil
end

function M:_refresh_current_node_changed_handler()
  local callback = self._item_context and self._item_context.on_visible_group_changed
  if not callback then
    self:_clear_current_node_changed_handler()
    return
  end
  if not self._current_node_changed_cb then
    self._current_node_changed_cb = pack(self, M._on_current_node_changed)
  end
  self._scroll_cloth_group:SetCurrentNodeChangedHandler(self._current_node_changed_cb)
end

function M:_clear_current_node_changed_handler()
  if is_null(self._scroll_cloth_group) then
    return
  end
  self._scroll_cloth_group:SetCurrentNodeChangedHandler(nil)
end

function M:_on_current_node_changed(node_index)
  local group_data = self._shop_groups[(node_index or 0) + 1]
  local group_id = group_data and (group_data.group_id or group_data.category_id) or 0
  if (group_id or 0) <= 0 then
    return
  end
  local callback = self._item_context and self._item_context.on_visible_group_changed
  if callback then
    callback(group_id)
  end
end

function M:_get_group_signature()
  local signature = {}
  for index, group_data in ipairs(self._shop_groups or {}) do
    signature[index] = tostring(group_data.group_id or group_data.category_id or 0) .. ":" .. tostring(#(group_data.items or {}))
  end
  return table.concat(signature, "|")
end

function M:_update_limited_time_items(delta_time)
  if self.game_obj and not self.game_obj.activeInHierarchy then
    return
  end
  if self._limited_time_refresh_index > 0 then
    self:_refresh_limited_time_items_by_frame()
    return
  end
  self._limited_time_refresh_acc = (self._limited_time_refresh_acc or 0) + delta_time
  if self._limited_time_refresh_acc < LIMITED_TIME_REFRESH_INTERVAL then
    return
  end
  self._limited_time_refresh_acc = 0
  self:_collect_limited_time_refresh_items()
  self:_refresh_limited_time_items_by_frame()
end

function M:_collect_limited_time_refresh_items()
  table.clear(self._limited_time_refresh_items)
  for _, item in pairs(self._shop_items) do
    if item:is_active_in_hierarchy() and item:need_limited_time_refresh() then
      table.insert(self._limited_time_refresh_items, item)
    end
  end
  self._limited_time_refresh_index = #self._limited_time_refresh_items > 0 and 1 or 0
end

function M:_refresh_limited_time_items_by_frame()
  local start_index = self._limited_time_refresh_index
  if start_index <= 0 then
    return
  end
  local end_index = math.min(start_index + LIMITED_TIME_REFRESH_COUNT_PER_FRAME - 1, #self._limited_time_refresh_items)
  for index = start_index, end_index do
    self._limited_time_refresh_items[index]:refresh_limited_time()
  end
  self._limited_time_refresh_index = end_index >= #self._limited_time_refresh_items and 0 or end_index + 1
end

return M
