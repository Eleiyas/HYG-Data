local M = G.Class("NpcClothGelianShopPanel", G.UIPanel)
local base = G.UIPanel
local SHOP_LIST_PANEL_CLS = "UI/NpcCloth/NpcClothShopListPanel"
local HOT_GROUP_ID = 999
local MAX_BUY_NUM = 99

local function reuse_table(tab)
  if tab then
    table.clear(tab)
    return tab
  else
    return {}
  end
end

function M:init()
  base.init(self)
  self._shop_groups = {}
  self._goods_guid_map = {}
  self._type_cfg_map = {}
  self._shop_id = 0
  self._shop_level = 0
  self._has_requested_shop_data = false
  self._tracking_context = nil
end

function M:on_create()
  base.on_create(self)
  self._coin_panel = self:add_panel(back_bag_module.coin_panel_cls, self._trans_coin_parent)
  self._shop_list_panel = self:add_panel(SHOP_LIST_PANEL_CLS, self.trans)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_coin_panel()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.NpcFriendShopDataChange, pack(self, M._on_shop_data_change))
  self:add_evt_listener(EventID.LuaTrackingChange, pack(self, M._on_tracking_data_change))
  self:add_evt_listener(EventID.LuaChangePacket, pack(self, M._on_tracking_data_change))
end

function M:show(data)
  data = data or {}
  self:set_extra_data(data)
  local shop_id = data.shop_id or data.shopId or self._shop_id or 0
  local shop_level = data.level or data.shop_level or data.shopLevel or self._shop_level or 0
  if shop_id ~= self._shop_id or shop_level ~= self._shop_level then
    self._has_requested_shop_data = false
  end
  self._shop_id = shop_id
  self._shop_level = shop_level
  if self:_request_shop_data_once() then
    self:_clear_shop_groups()
    return
  end
  self:_refresh_shop_groups()
end

function M:reset_request_state()
  self._has_requested_shop_data = false
  if self._shop_list_panel then
    self._shop_list_panel:reset_view_state()
  end
end

function M:_refresh_coin_panel()
  if not self._coin_panel then
    return
  end
  self._coin_panel:set_coin_data({
    coin_types = {
      back_bag_module.coin_type.npc_cloth_ticket
    },
    is_auto_update = true,
    coin_anim_time = 0.5
  })
end

function M:_request_shop_data_once()
  if self._has_requested_shop_data then
    return false
  end
  if (self._shop_id or 0) <= 0 then
    return false
  end
  self._has_requested_shop_data = true
  local request_shop_id = self._shop_id or 0
  local request_level = self._shop_level or 0
  CsShopModuleUtil.NpcFriendShopOpenReq(request_shop_id, request_level, function(retcode)
    if retcode and retcode <= 0 and self._shop_id == request_shop_id and self._shop_level == request_level then
      self:_refresh_shop_groups()
    end
  end)
  return true
end

function M:_on_shop_data_change()
  self:_refresh_shop_groups()
end

function M:_clear_shop_groups()
  table.clear(self._shop_groups)
  table.clear(self._goods_guid_map)
  if self._shop_list_panel then
    self._shop_list_panel:refresh(self._shop_groups, {
      shop_level = self._shop_level,
      tracking_context = self._tracking_context,
      on_click_buy = pack(self, M._on_click_buy),
      on_click_item = pack(self, M._on_click_buy)
    })
  end
end

function M:_refresh_shop_groups()
  self:_build_shop_groups()
  self:_refresh_tracking_context()
  self:_refresh_shop_list_panel()
end

function M:_build_shop_groups()
  table.clear(self._shop_groups)
  self:_build_type_cfg_map()
  local slot_groups = self:_collect_shop_slot_groups()
  for _, slot_group in ipairs(slot_groups) do
    table.insert(self._shop_groups, slot_group)
  end
  self:_move_hot_group_to_front()
  npc_cloth_module.build_goods_guid_map(self._shop_groups, self._goods_guid_map)
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
  local result = {}
  for _, slot in ipairs(list_to_table(shop_data.SlotList) or {}) do
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
        title = self:_get_cfg_title(cfg, slot_id),
        icon = cfg and cfg.clothtypeicon or nil,
        cfg = cfg,
        items = items
      })
    end
  end
  return result
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
  if ok then
    return cfg_name
  end
  return nil
end

function M:_build_type_cfg_map()
  table.clear(self._type_cfg_map)
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BNpcClothStoreCfg)) or {}) do
    self._type_cfg_map[cfg.id] = cfg
  end
end

function M:_refresh_shop_list_panel()
  if not self._shop_list_panel then
    return
  end
  self._shop_list_panel:refresh(self._shop_groups, {
    shop_level = self._shop_level,
    tracking_context = self._tracking_context,
    on_click_buy = pack(self, M._on_click_buy),
    on_click_item = pack(self, M._on_click_buy)
  })
end

function M:_on_tracking_data_change()
  self:_refresh_tracking_context()
  self:_refresh_visible_tracking_items()
end

function M:_refresh_tracking_context()
  local tracking_data = tracking_module:get_track_data_by_track_type(tracking_module:get_manager_cur_track_type())
  local context = reuse_table(self._tracking_context)
  context.tracking_data = tracking_data
  context.tracking_item_map = {}
  context.tracking_style = nil
  self._tracking_context = context
  if is_null(tracking_data) or is_null(tracking_data.data) then
    return
  end
  if tracking_data.source_type ~= tracking_module.data_source_type.task then
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

function M:_refresh_visible_tracking_items()
  if self._shop_list_panel then
    self._shop_list_panel:refresh_visible_tracking_items(self._tracking_context)
  end
end

function M:_on_click_buy(goods)
  local goods_id = goods.GUID or 0
  if goods_id <= 0 then
    Logger.LogWarning("[NpcClothGelianShopPanel] missing goods ConfIndex, itemId = " .. tostring(goods.ItemID))
    return
  end
  local max_num = self:_get_max_buy_num(goods)
  if max_num <= 0 then
    return
  end
  local dialog_guid
  dialog_guid = shop_module:open_buy_item_dialog({
    is_npc_cloth = true,
    cfg_id = goods.ItemID,
    coin_id = back_bag_module.coin_type.npc_cloth_ticket,
    unit_price = goods.Price,
    max_num = max_num,
    available_balance_func = function()
      return npc_cloth_module.get_available_buy_balance()
    end,
    title_text = UIUtil.get_text_by_id("NpcCloth_txt_Popup_BuyCloth_Title"),
    coin_not_enough_text = npc_cloth_module.get_coin_not_enough_text(true),
    buy_callback = function(num)
      return self:_buy_goods(goods_id, num, dialog_guid)
    end
  })
end

function M:_build_buy_data(goods_guid, num)
  local latest_goods = npc_cloth_module.find_goods_by_guid(self._shop_groups, goods_guid, self._goods_guid_map)
  local count = math.floor(tonumber(num) or 0)
  if is_null(latest_goods) or goods_guid <= 0 or count <= 0 or count > self:_get_max_buy_num(latest_goods) or not npc_cloth_module.is_goods_buyable(latest_goods) then
    UIUtil.show_tips_by_text_id("NpcCloth_BuyGoods_Lock")
    return nil
  end
  return {
    goods_guid = latest_goods.GUID,
    num = count,
    total_price = (latest_goods.Price or 0) * count
  }
end

function M:_buy_goods(goods_guid, num, dialog_guid)
  local buy_data = self:_build_buy_data(goods_guid, num)
  if buy_data == nil then
    return false
  end
  if buy_data.total_price > npc_cloth_module.get_available_buy_balance() then
    UIUtil.show_tips_by_text_id("NpcCloth_BuyGood_NotEnough")
    return false
  end
  local fragment_cost = npc_cloth_module.get_fragment_deduct_cost(buy_data.total_price)
  if 0 < fragment_cost then
    local pending_data = {
      goods_guid = buy_data.goods_guid,
      num = buy_data.num,
      fragment_cost = fragment_cost
    }
    npc_cloth_module.show_coin_deduct_confirm(fragment_cost, function()
      self:_confirm_coin_deduct_buy(pending_data, dialog_guid)
    end)
    return false
  end
  self:_send_buy_request(buy_data)
  return true
end

function M:_confirm_coin_deduct_buy(pending_data, dialog_guid)
  local buy_data = self:_build_buy_data(pending_data.goods_guid, pending_data.num)
  if buy_data == nil then
    return
  end
  if buy_data.total_price > npc_cloth_module.get_available_buy_balance() then
    UIUtil.show_tips_by_text_id("NpcCloth_BuyGood_NotEnough")
    return
  end
  local fragment_cost = npc_cloth_module.get_fragment_deduct_cost(buy_data.total_price)
  if 0 < fragment_cost and fragment_cost ~= pending_data.fragment_cost then
    pending_data.fragment_cost = fragment_cost
    npc_cloth_module.show_coin_deduct_confirm(fragment_cost, function()
      self:_confirm_coin_deduct_buy(pending_data, dialog_guid)
    end)
    return
  end
  self:_send_buy_request(buy_data)
  if dialog_guid then
    UIManagerInstance:close(dialog_guid)
  end
end

function M:_send_buy_request(buy_data)
  CsShopModuleUtil.NpcFriendShopBatchBuyReq(self._shop_level or 0, {
    buy_data.goods_guid
  }, {
    buy_data.num
  }, nil)
end

function M:_get_max_buy_num(goods)
  if is_null(goods) then
    return 0
  end
  return math.min(goods.CAmount or 1, MAX_BUY_NUM)
end

return M
