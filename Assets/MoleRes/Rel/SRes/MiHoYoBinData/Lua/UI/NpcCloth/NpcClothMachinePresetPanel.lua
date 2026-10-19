local M = G.Class("NpcClothMachinePresetPanel", G.UIPanel)
local base = G.UIPanel
local CATEGORY_PANEL_CLS = "UI/NpcCloth/NpcClothMachineCategoryPanel"
local GROUP_ITEM_CLS = "UI/NpcCloth/NpcClothGelianShopGroupItem"
local PRESET_ITEM_CLS = "UI/NpcCloth/NpcClothMachinePresetItem"
local SOURCE_TYPE_PACKET = "packet"
local SOURCE_TYPE_NPC_WAREHOUSE = "npc_warehouse"
local CATEGORY_STOCK_STATE_IN_STOCK = 0
local CATEGORY_STOCK_STATE_EMPTY = 1
local PRESET_CONTENT_STATE_NOT_EMPTY = 0
local PRESET_CONTENT_STATE_EMPTY = 1

function M:init()
  base.init(self)
  self._groups = {}
  self._categories = {}
  self._preset_by_slot = {}
  self._selected_item_key_map = {}
  self._group_items = {}
  self._bag_items = {}
  self._callbacks = {}
  self._current_category_id = 0
  self._group_signature = nil
  self._current_node_changed_cb = nil
  self._store_cfg_map = nil
end

function M:on_create()
  base.on_create(self)
  self._category_panel = self:add_panel(CATEGORY_PANEL_CLS, self.trans)
end

function M:on_destroy()
  self:_clear_current_node_changed_handler()
  if self._scroll_bag_group then
    self._scroll_bag_group:Close()
  end
  base.on_destroy(self)
end

function M:show(data, callbacks)
  data = data or {}
  self._callbacks = callbacks or {}
  self._npc_id = data.npc_id or 0
  self._shape = data.shape or 0
  self._resident_npc_id_set = data.resident_npc_id_set or {}
  self._preset_by_slot = self:_copy_preset_map(data.preset_map or {})
  self:_build_groups()
  self:_refresh_empty_state()
  self:_remove_invalid_presets()
  self:_rebuild_selected_item_key_map()
  self:_refresh_category_panel(true)
  self:_refresh_grouped_scroller(true)
end

function M:get_preset_map()
  return self:_copy_preset_map(self._preset_by_slot)
end

function M:_build_groups()
  table.clear(self._groups)
  table.clear(self._categories)
  local group_map = {}
  self._source_item_key_map = {}
  local source_items = self:_collect_source_items()
  for _, item_data in ipairs(source_items) do
    local fst_id = item_data.slot_key or npc_cloth_module.get_outfit_fst_classify_id(item_data.item_id)
    if 0 < fst_id and npc_cloth_module.is_item_wearable_by_npc(item_data.item_id, self._npc_id, self._shape) then
      if item_data.key ~= nil then
        self._source_item_key_map[item_data.key] = true
      end
      local group = self:_ensure_group(group_map, fst_id)
      group.items[#group.items + 1] = item_data
    end
  end
  table.sort(self._groups, function(a, b)
    return (a.group_id or 0) < (b.group_id or 0)
  end)
  for _, group in ipairs(self._groups) do
    table.sort(group.items, function(a, b)
      return (a.item_id or 0) < (b.item_id or 0)
    end)
  end
  self:_build_categories(group_map)
  if not self:_has_category(self._current_category_id) then
    self._current_category_id = self:_get_first_interactable_category_id()
  end
end

function M:_ensure_group(group_map, fst_id)
  local group = group_map[fst_id]
  if group then
    return group
  end
  group = {
    group_id = fst_id,
    category_id = fst_id,
    title = npc_cloth_module.get_fst_classify_title(fst_id),
    icon = self:_get_category_icon(fst_id),
    items = {}
  }
  group_map[fst_id] = group
  self._groups[#self._groups + 1] = group
  return group
end

function M:_build_categories(group_map)
  local cfg_table = ExcelDataUtil.get_table(typeof(BNpcFstClassifyCfg)) or {}
  for _, cfg in pairs(cfg_table) do
    local fst_id = cfg.fstid or 0
    if 0 < fst_id then
      local group = group_map[fst_id]
      local has_items = group ~= nil and 0 < #(group.items or {})
      self._categories[#self._categories + 1] = {
        category_id = fst_id,
        title = npc_cloth_module.get_fst_classify_title(fst_id),
        icon = self:_get_category_icon(fst_id),
        interactable = has_items,
        stock_state = has_items and CATEGORY_STOCK_STATE_IN_STOCK or CATEGORY_STOCK_STATE_EMPTY
      }
    end
  end
  table.sort(self._categories, function(a, b)
    return (a.category_id or 0) < (b.category_id or 0)
  end)
end

function M:_refresh_empty_state()
  if is_null(self._state_group_empty) then
    return
  end
  local state = #self._groups > 0 and PRESET_CONTENT_STATE_NOT_EMPTY or PRESET_CONTENT_STATE_EMPTY
  self._state_group_empty:SetState(state)
end

function M:_get_category_icon(fst_id)
  self:_build_store_cfg_map()
  local cfg = self._store_cfg_map[fst_id]
  return cfg and cfg.clothtypeicon or nil
end

function M:_build_store_cfg_map()
  if self._store_cfg_map ~= nil then
    return
  end
  self._store_cfg_map = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BNpcClothStoreCfg)) or {}) do
    self._store_cfg_map[cfg.id] = cfg
  end
end

function M:_collect_source_items()
  local result = {}
  self:_append_packet_items(result)
  if self._resident_npc_id_set[self._npc_id] == true then
    self:_append_npc_warehouse_items(result)
  end
  return result
end

function M:_append_packet_items(result)
  for _, item in pairs(CsPacketModuleUtil.GetAllPacketItems()) do
    self:_append_item_snapshot(result, item, SOURCE_TYPE_PACKET, 0)
  end
end

function M:_append_npc_warehouse_items(result)
  local guids = list_to_table(CsWarehouseModuleUtil.GetItemGuidsByNpcId(self._npc_id, 0)) or {}
  for _, guid in ipairs(guids) do
    local item = CsWarehouseModuleUtil.GetNPCWarehouseItemByGUID(self._npc_id, guid)
    self:_append_item_snapshot(result, item, SOURCE_TYPE_NPC_WAREHOUSE, self._npc_id)
  end
end

function M:_append_item_snapshot(result, item, source_type, source_npc_id)
  local snapshot = npc_cloth_module.copy_item_snapshot(item, source_type, source_npc_id)
  if snapshot and npc_cloth_module.is_npc_cloth_item(snapshot.item_id) then
    result[#result + 1] = snapshot
  end
end

function M:_refresh_category_panel(reset_position)
  if not self._category_panel then
    return
  end
  self._category_panel:refresh(self._categories, {
    current_category_id = self._current_category_id,
    on_click_category = pack(self, M._on_click_category)
  }, reset_position, true)
end

function M:_refresh_grouped_scroller(should_move_top)
  if is_null(self._scroll_bag_group) then
    return
  end
  self:_clear_current_node_changed_handler()
  local old_signature = self._group_signature
  local new_signature = self:_get_group_signature()
  self._group_signature = new_signature
  self._scroll_bag_group:SetNodeCount(#self._groups)
  for group_index, group_data in ipairs(self._groups) do
    local node_index = group_index - 1
    local item_count = #(group_data.items or {})
    self._scroll_bag_group:Init(node_index, 0, item_count, pack(self, M._on_group_item_bind), pack(self, M._on_group_node_init))
    local items_per_line = self._scroll_bag_group:GetItemsPerLine(node_index)
    local display_item_count = self:_get_display_item_count(item_count, items_per_line)
    if display_item_count ~= item_count then
      self._scroll_bag_group:Init(node_index, 0, display_item_count, pack(self, M._on_group_item_bind), pack(self, M._on_group_node_init))
    end
  end
  self._scroll_bag_group:RebindAllVisibleItems()
  if should_move_top == true and old_signature ~= new_signature and #self._groups > 0 then
    self._scroll_bag_group:MoveToNode(0)
  end
  self:_refresh_current_node_changed_handler()
end

function M:_get_display_item_count(item_count, items_per_line)
  if item_count <= 0 or items_per_line <= 0 then
    return item_count
  end
  return math.ceil(item_count / items_per_line) * items_per_line
end

function M:_on_group_node_init(node_trans, node_index)
  local instance_id = node_trans:GetInstanceID()
  local group_item = self._group_items[instance_id]
  if not group_item then
    group_item = self:add_panel(GROUP_ITEM_CLS, node_trans)
    self._group_items[instance_id] = group_item
  end
  group_item:refresh(self._groups[node_index + 1])
end

function M:_on_group_item_bind(item_trans, node_index, item_index)
  local instance_id = item_trans:GetInstanceID()
  local item = self._bag_items[instance_id]
  if not item then
    item = self:add_panel(PRESET_ITEM_CLS, item_trans)
    self._bag_items[instance_id] = item
  end
  local group_data = self._groups[node_index + 1]
  local item_data = group_data and group_data.items and group_data.items[item_index + 1] or nil
  item:refresh(item_data, self:_build_item_context())
end

function M:_build_item_context()
  return {
    selected_item_key_map = self._selected_item_key_map,
    on_click_item = pack(self, M._on_click_item)
  }
end

function M:_on_click_item(item_data)
  if is_null(item_data) then
    return
  end
  local slot_key = item_data.slot_key or 0
  if slot_key <= 0 then
    return
  end
  local old_item = self._preset_by_slot[slot_key]
  if old_item and old_item.key == item_data.key then
    self._preset_by_slot[slot_key] = nil
  else
    self._preset_by_slot[slot_key] = self:_copy_item_data(item_data)
  end
  self:_rebuild_selected_item_key_map()
  self:_refresh_visible_items_selected()
  if self._callbacks and self._callbacks.on_preset_changed then
    self._callbacks.on_preset_changed(self:get_preset_map())
  end
end

function M:_refresh_visible_items_selected()
  local context = self:_build_item_context()
  for _, item in pairs(self._bag_items) do
    if item:is_active_in_hierarchy() then
      item:refresh_selected(context)
    end
  end
end

function M:_on_click_category(category_id, category)
  if category and category.interactable == false then
    return
  end
  self._current_category_id = category_id
  if self._scroll_bag_group then
    local node_index = self:_get_group_node_index(category_id)
    if node_index then
      self._scroll_bag_group:MoveToNode(node_index)
    end
  end
end

function M:_refresh_current_node_changed_handler()
  if is_null(self._scroll_bag_group) then
    return
  end
  if not self._current_node_changed_cb then
    self._current_node_changed_cb = pack(self, M._on_current_node_changed)
  end
  self._scroll_bag_group:SetCurrentNodeChangedHandler(self._current_node_changed_cb)
end

function M:_clear_current_node_changed_handler()
  if is_null(self._scroll_bag_group) then
    return
  end
  self._scroll_bag_group:SetCurrentNodeChangedHandler(nil)
end

function M:_on_current_node_changed(node_index)
  local group_data = self._groups[(node_index or 0) + 1]
  local category_id = group_data and (group_data.category_id or group_data.group_id) or 0
  if category_id <= 0 or self._current_category_id == category_id then
    return
  end
  self._current_category_id = category_id
  if self._category_panel then
    self._category_panel:set_current_category(category_id, true)
  end
end

function M:_copy_preset_map(source)
  local result = {}
  for slot_key, item_data in pairs(source or {}) do
    result[slot_key] = self:_copy_item_data(item_data)
  end
  return result
end

function M:_copy_item_data(item_data)
  if item_data == nil then
    return nil
  end
  local result = {}
  for key, value in pairs(item_data) do
    result[key] = value
  end
  return result
end

function M:_rebuild_selected_item_key_map()
  table.clear(self._selected_item_key_map)
  for _, item_data in pairs(self._preset_by_slot or {}) do
    if item_data.key then
      self._selected_item_key_map[item_data.key] = true
    end
  end
end

function M:_remove_invalid_presets()
  local source_item_key_map = self._source_item_key_map or {}
  for slot_key, item_data in pairs(self._preset_by_slot or {}) do
    local item_key = item_data and item_data.key
    local is_valid = item_key ~= nil and source_item_key_map[item_key] == true
    if item_data.source_type == SOURCE_TYPE_NPC_WAREHOUSE then
      is_valid = is_valid and false
    end
    if not is_valid then
      self._preset_by_slot[slot_key] = nil
    end
  end
end

function M:_has_category(category_id)
  for _, category in ipairs(self._categories or {}) do
    if category.category_id == category_id and category.interactable ~= false then
      return true
    end
  end
  return false
end

function M:_get_first_interactable_category_id()
  for _, category in ipairs(self._categories or {}) do
    if category.interactable ~= false then
      return category.category_id
    end
  end
  return 0
end

function M:_get_group_node_index(group_id)
  for index, group_data in ipairs(self._groups or {}) do
    if group_data.group_id == group_id or group_data.category_id == group_id then
      return index - 1
    end
  end
  return nil
end

function M:_get_group_signature()
  local signature = {}
  for index, group_data in ipairs(self._groups or {}) do
    signature[index] = tostring(group_data.group_id or 0) .. ":" .. tostring(#(group_data.items or {}))
  end
  return table.concat(signature, "|")
end

return M
