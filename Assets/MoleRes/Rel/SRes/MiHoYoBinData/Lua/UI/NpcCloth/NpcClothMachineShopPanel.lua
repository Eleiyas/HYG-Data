local M = G.Class("NpcClothMachineShopPanel", G.UIPanel)
local base = G.UIPanel
local SHOP_LIST_PANEL_CLS = "UI/NpcCloth/NpcClothShopListPanel"
local SHOP_ITEM_CLS = "UI/NpcCloth/NpcClothMachineShopItem"
local CATEGORY_PANEL_CLS = "UI/NpcCloth/NpcClothMachineCategoryPanel"
local HOT_GROUP_ID = 999
local CATEGORY_STOCK_STATE_IN_STOCK = 0
local CATEGORY_STOCK_STATE_HOT = 2

local function reuse_table(tab)
  if tab then
    table.clear(tab)
    return tab
  end
  return {}
end

function M:init()
  base.init(self)
  self._shop_groups = {}
  self._goods_guid_map = {}
  self._categories = {}
  self._type_cfg_map = nil
  self._view_context = {}
  self._callbacks = {}
  self._shop_id = 0
  self._shop_level = 0
  self._tracking_context = nil
end

function M:on_create()
  base.on_create(self)
  self._category_panel = self:add_panel(CATEGORY_PANEL_CLS, self.trans)
  self._shop_list_panel = self:add_panel(SHOP_LIST_PANEL_CLS, self.trans)
  self._shop_list_panel:setup({shop_item_cls = SHOP_ITEM_CLS})
end

function M:show(data, callbacks)
  data = data or {}
  self._callbacks = callbacks or data.callbacks or self._callbacks or {}
  self._shop_id = data.shop_id or data.shopId or self._shop_id or 0
  self._shop_level = data.level or data.shop_level or data.shopLevel or self._shop_level or 0
  self._view_context = data.view_context or self._view_context or {}
  self:_refresh_all()
end

function M:update_view_context(view_context, changed_goods_key_map)
  self._view_context = view_context or self._view_context or {}
  if changed_goods_key_map and self._shop_list_panel then
    self:_refresh_shop_list_context(changed_goods_key_map)
    return
  end
  self:_refresh_shop_list_panel()
end

function M:refresh_visible_item_context(view_context)
  self._view_context = view_context or self._view_context or {}
  if self._shop_list_panel then
    self._shop_list_panel:refresh_visible_items(self:_build_shop_item_context())
  end
end

function M:clear_shop_groups()
  table.clear(self._shop_groups)
  table.clear(self._goods_guid_map)
  table.clear(self._categories)
  self._view_context.current_category_id = 0
  self:_refresh_shop_list_panel()
  self:_refresh_category_panel(true)
end

function M:refresh_category_panel(reset_position, force_reinit)
  self:_refresh_category_panel(reset_position == true, force_reinit == true)
end

function M:scroll_to_category(category_id)
  if self._shop_list_panel then
    self._shop_list_panel:scroll_to_group(category_id)
  end
end

function M:_refresh_all()
  self:_build_shop_groups()
  self:_refresh_tracking_context()
  self:_refresh_categories()
  self:_refresh_shop_list_panel()
end

function M:_build_shop_groups()
  table.clear(self._shop_groups)
  self:_build_type_cfg_map()
  local slot_groups = self:_collect_shop_slot_groups()
  for _, group_data in ipairs(slot_groups) do
    table.insert(self._shop_groups, group_data)
  end
  self:_move_hot_group_to_front()
  npc_cloth_module.build_goods_guid_map(self._shop_groups, self._goods_guid_map)
end

function M:_collect_shop_slot_groups()
  local shop_data = CsShopModuleUtil.GetNpcFriendShopData()
  if is_null(shop_data) then
    return {}
  end
  if 0 < (self._shop_id or 0) and shop_data.Id ~= self._shop_id then
    return {}
  end
  if 0 < (self._shop_level or 0) and shop_data.Level ~= self._shop_level then
    return {}
  end
  self._shop_id = shop_data.Id or self._shop_id or 0
  self._shop_level = shop_data.Level or self._shop_level or 0
  return self:_build_groups_from_slots(list_to_table(shop_data.SlotList) or {})
end

function M:_build_groups_from_slots(slot_list)
  local result = {}
  for _, slot in ipairs(slot_list) do
    local slot_id = slot.Id or 0
    local cfg = self._type_cfg_map[slot_id]
    local items = {}
    for _, goods in ipairs(list_to_table(slot.GoodsList) or {}) do
      local goods_snapshot = npc_cloth_module.copy_shop_goods(goods)
      if goods_snapshot then
        table.insert(items, goods_snapshot)
      end
    end
    if 0 < #items then
      table.insert(result, {
        group_id = slot_id,
        category_id = slot_id,
        title = self:_get_cfg_title(cfg, slot_id),
        icon = cfg and cfg.clothtypeicon or nil,
        cfg = cfg,
        items = items
      })
    end
  end
  return result
end

function M:_move_hot_group_to_front()
  for index, group_data in ipairs(self._shop_groups) do
    if group_data.group_id == HOT_GROUP_ID then
      table.remove(self._shop_groups, index)
      table.insert(self._shop_groups, 1, group_data)
      return
    end
  end
end

function M:_refresh_categories()
  table.clear(self._categories)
  for _, group_data in ipairs(self._shop_groups) do
    local category_id = group_data.category_id or group_data.group_id
    table.insert(self._categories, {
      category_id = category_id,
      title = group_data.title,
      icon = group_data.icon,
      group = group_data,
      stock_state = category_id == HOT_GROUP_ID and CATEGORY_STOCK_STATE_HOT or CATEGORY_STOCK_STATE_IN_STOCK
    })
  end
  if not self:_has_category(self._view_context.current_category_id) then
    self._view_context.current_category_id = self._categories[1] and self._categories[1].category_id or 0
  end
  self:_refresh_category_panel(true)
end

function M:_refresh_shop_list_panel()
  if not self._shop_list_panel then
    return
  end
  self._shop_list_panel:refresh(self._shop_groups, self:_build_shop_item_context())
end

function M:_refresh_shop_list_context(changed_goods_key_map)
  if not self._shop_list_panel then
    return
  end
  self._shop_list_panel:refresh_visible_goods(self:_build_shop_item_context(), changed_goods_key_map)
end

function M:_build_shop_item_context()
  return {
    shop_level = self._shop_level,
    tracking_context = self._tracking_context,
    selected_goods_id_map = self._view_context and self._view_context.selected_goods_id_map,
    latest_selected_goods = self._view_context and self._view_context.latest_selected_goods,
    mannequin_npc_id = self._view_context and self._view_context.mannequin_npc_id,
    mannequin_shape = self._view_context and self._view_context.mannequin_shape,
    current_group_id = self._view_context and self._view_context.current_category_id,
    on_click_item = pack(self, M._on_click_item),
    on_visible_group_changed = pack(self, M._on_visible_group_changed)
  }
end

function M:_refresh_category_panel(reset_position, force_reinit)
  if not self._category_panel then
    return
  end
  self._category_panel:refresh(self._categories, {
    current_category_id = self._view_context.current_category_id,
    on_click_category = pack(self, M._on_click_category)
  }, reset_position, force_reinit)
end

function M:_on_click_item(goods, view_state)
  if self._callbacks and self._callbacks.on_click_item then
    self._callbacks.on_click_item(goods, view_state)
  end
end

function M:_on_click_category(category_id)
  self._view_context.current_category_id = category_id
  self:_refresh_category_panel(false)
  self:scroll_to_category(category_id)
end

function M:_on_visible_group_changed(category_id)
  if not self:_has_category(category_id) or self._view_context.current_category_id == category_id then
    return
  end
  self._view_context.current_category_id = category_id
  if self._category_panel then
    self._category_panel:set_current_category(category_id, true)
  end
end

function M:_refresh_tracking_context()
  local tracking_data = tracking_module:get_track_data_by_track_type(tracking_module:get_manager_cur_track_type())
  local context = reuse_table(self._tracking_context)
  context.tracking_data = tracking_data
  context.tracking_item_map = {}
  context.tracking_style = nil
  self._tracking_context = context
  if is_null(tracking_data) or is_null(tracking_data.data) or tracking_data.source_type ~= tracking_module.data_source_type.task then
    return
  end
  local item_ids = self:_collect_tracking_check_item_ids()
  if #item_ids <= 0 then
    return
  end
  local tracking_item_ids = list_to_table(tracking_data.data:GetTrackingPointIdsByItemIds(item_ids, nil)) or {}
  for _, item_id in ipairs(tracking_item_ids) do
    context.tracking_item_map[item_id] = true
  end
  context.tracking_style = tracking_module:get_tracking_point_style(tracking_data.track_type, tracking_data.source_type, tracking_data.source_id)
end

function M:_collect_tracking_check_item_ids()
  local item_ids = {}
  local item_id_map = {}
  for _, group_data in ipairs(self._shop_groups or {}) do
    for _, goods in ipairs(group_data.items or {}) do
      local item_id = goods.ItemID or 0
      if 0 < item_id and not item_id_map[item_id] then
        item_id_map[item_id] = true
        table.insert(item_ids, item_id)
      end
    end
  end
  return item_ids
end

function M:_build_type_cfg_map()
  if self._type_cfg_map then
    return
  end
  self._type_cfg_map = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BNpcClothStoreCfg)) or {}) do
    self._type_cfg_map[cfg.id] = cfg
  end
end

function M:_get_cfg_title(cfg, slot_id)
  local cfg_name = self:_try_get_cfg_name(cfg)
  if string.is_valid(cfg_name) then
    return cfg_name
  end
  return tostring(slot_id)
end

function M:_try_get_cfg_name(cfg)
  if not cfg then
    return nil
  end
  local ok, cfg_name = pcall(function()
    return cfg.name
  end)
  return ok and cfg_name or nil
end

function M:_has_category(category_id)
  for _, category in ipairs(self._categories or {}) do
    if category.category_id == category_id then
      return true
    end
  end
  return false
end

function M:_get_category_index(category_id)
  for index, category in ipairs(self._categories or {}) do
    if category.category_id == category_id then
      return index
    end
  end
  return nil
end

function M:get_shop_groups()
  return self._shop_groups or {}
end

function M:get_goods_guid_map()
  return self._goods_guid_map or {}
end

return M
