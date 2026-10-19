local M = G.Class("GeLianMarketCropPricePanel", G.UIPanel)
local base = G.UIPanel
local entry_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketCropPriceEntryPanel"
local inventory_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketCropInventoryPanel"
local market_time_util = require("UI/GeLianMarket/GeLianMarketTimeUtil")
local view_model = gelian_market_module.view_model
local REFRESH_INTERVAL = 60
M.Mode = {Market = "market", Compare = "compare"}

function M:init()
  base.init(self)
  self._view_data = nil
  self._page_service = nil
  self._price_items = {}
  self._inventory_items = {}
  self._time_timer = nil
  self._market_owner_name = ""
  self._mode = M.Mode.Market
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._page_service = context and context.page_service or nil
  self._mode = context and context.market_panel_mode or M.Mode.Market
  if self._mode == M.Mode.Market then
    self:bind_callback(self._btn_sell, pack(self, M.request_enter_sell))
    self:bind_callback(self._btn_broadcast, pack(self, M._on_btn_broadcast))
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_time_texts()
  self:_start_time_timer()
  self:_play_price_anims()
end

function M:on_disable()
  self:_stop_time_timer()
  base.on_disable(self)
end

function M:on_destroy()
  self:_stop_time_timer()
  self._page_service = nil
  self._view_data = nil
  self._price_items = {}
  self._inventory_items = {}
  base.on_destroy(self)
end

function M:request_enter_sell(payload)
  if self._page_service ~= nil then
    self._page_service:enter_sell(payload)
  end
end

function M:render(view_data, market_owner_name, show_friend_title, mode)
  self._view_data = view_data
  self._market_owner_name = market_owner_name or ""
  self._mode = mode or self._mode
  self:_refresh_title(show_friend_title == true)
  if self._mode == M.Mode.Market then
    self:_refresh_broadcast_red_point()
  end
  local entries = view_data and view_data.entries or {}
  self:_ensure_items(self._list_item_binder_price, self._price_items, entry_panel_cls, #entries)
  self:_ensure_items(self._list_item_binder_inventory, self._inventory_items, inventory_panel_cls, #entries)
  for i = 1, #self._price_items do
    local entry = entries[i]
    self._price_items[i]:render(entry, pack(self, M._open_price_detail))
    self._inventory_items[i]:render(entry)
  end
  if self.is_active then
    self:_play_price_anims()
  end
end

function M:_ensure_items(binder, items, panel_cls, count)
  for i = #items + 1, count do
    local trans = binder:AddItem(0, true)
    items[i] = self:add_panel(panel_cls, trans)
  end
end

function M:_play_price_anims()
  local view_data = self._view_data
  if view_data == nil then
    return
  end
  local is_self = view_data.is_self == true
  local entries = view_data.entries or {}
  for i = 1, #self._price_items do
    local entry = entries[i]
    if entry ~= nil and view_model.take_price_anim(is_self, entry.tag) then
      self._price_items[i]:play_price_roll()
    end
  end
end

function M:_open_price_detail(entry, target_trans)
  item_module:open_item_info_dialog(entry.display_config_id, back_bag_module:get_item_num(entry.display_config_id))
end

function M:_refresh_title(show_friend_title)
  UIUtil.set_active(self._my_title_group, not show_friend_title)
  UIUtil.set_active(self._friend_title_group, show_friend_title)
  if show_friend_title and not is_null(self._txt_friend_market) then
    UIUtil.set_text_by_id(self._txt_friend_market, "CropTrading_Name_Title", self._market_owner_name)
  end
end

function M:_refresh_time_texts()
  UIUtil.set_text_by_id(self._txt_cycle, "CropTrading_PriceChange_Tips1", market_time_util.get_next_price_refresh_left_time())
  if self._mode == M.Mode.Market then
    UIUtil.set_text(self._txt_date, market_time_util.get_today_text())
  end
end

function M:_start_time_timer()
  self:_stop_time_timer()
  self._time_timer = CsCoroutineManagerUtil.Invoke(REFRESH_INTERVAL, function()
    if self.is_active then
      self:_refresh_time_texts()
      self:_start_time_timer()
    end
  end)
end

function M:_stop_time_timer()
  if self._time_timer ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._time_timer)
    self._time_timer = nil
  end
end

function M:_on_btn_broadcast()
  CsGeLianMarketModuleUtil.HasNewMessages = false
  self:_refresh_broadcast_red_point()
  UIManagerInstance:open("UI/GeLianMarket/GeLianFoodMarketBoardDialog", {
    entries = self._view_data and self._view_data.entries or {}
  })
end

function M:_refresh_broadcast_red_point()
  if self._mode == M.Mode.Market then
    self._red_point_broadcast:ShowRedPoint(CsGeLianMarketModuleUtil.HasNewMessages and RedPointType.NewRp or RedPointType.None)
  end
end

return M
