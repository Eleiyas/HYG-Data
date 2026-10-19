local M = G.Class("UI/StarExplore/StarExploreBatteryExchangePopup", G.UIWindow)
local base = G.UIWindow
local BATTERY_ITEM_ID = 30200
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExplore/StarExplorePurchaseDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:add_evt_listener(EventID.UpdateTVShopping, pack(self, M._on_update_tvshopping))
  self.goods = self:_get_goods_by_item_id(BATTERY_ITEM_ID)
  local token_cfg = item_module:get_cfg_by_id(self.goods and self.goods.CostTokenId or 0)
  local icon_path = token_cfg and token_cfg.icon or ""
  UIUtil.set_image(self._img_icom_price, icon_path, self:get_load_proxy())
  self._coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item, {coin_id = 200003, auto_update = true})
  self._star_coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item_battery, {coin_id = 30200, auto_update = true})
  self:_on_update_tvshopping()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_buy_num_text()
  local battery_num = tostring(back_bag_module:get_coin_or_item_num(BATTERY_ITEM_ID))
  UIUtil.set_text(self._txt_battery_pack_num, battery_num)
  UIUtil.set_text_by_id(self._txt_title, "UI_StarSea_ExchangeTickets")
  UIUtil.set_text(self._txt_battery_name, item_module:get_item_name_by_id(BATTERY_ITEM_ID))
  UIUtil.set_text_by_id(self._txt_total, "TVShoppingNewPage_txt_29")
  UIUtil.set_text_by_id(self._txt_exchangenum, "UI_StarSea_TicketsCount")
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_cancel)
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_buy_click))
end

function M:_on_update_tvshopping()
  tvshop_module:update_tvshop_data()
  self.goods = self:_get_goods_by_item_id(BATTERY_ITEM_ID)
  self:_refresh_buy_num_text()
  local battery_num = tostring(back_bag_module:get_coin_or_item_num(BATTERY_ITEM_ID))
  UIUtil.set_text(self._txt_battery_pack_num, battery_num)
  local goods = self.goods
  local goods_price = goods and goods.Price or 0
  UIUtil.set_text(self._txt_price_num, tostring(goods_price))
  local cost_token_id = goods and goods.CostTokenId or 0
  local cur_coin = CsPacketModuleUtil.GetCoinCountById(cost_token_id)
  if not is_null(self._coin_view) then
    self._coin_view:set_coin_id(cost_token_id)
  elseif 0 < cost_token_id then
    self._coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item, {coin_id = cost_token_id, auto_update = true})
  end
  Logger.Log(string.format("[StarExploreBatteryExchangePopup] cur_coin=%s, goods.Price=%s", tostring(cur_coin), tostring(goods and goods.Price)))
  if goods_price > cur_coin then
    UIUtil.set_text_color(self._txt_price_num, "#ea7354")
  else
    UIUtil.set_text_color(self._txt_price_num, "#fffad9")
  end
  return
end

function M:_refresh_buy_num_text()
  local goods = self.goods
  local prefix = UIUtil.get_text_by_id("UI_StarSea_ExchangesLeft") or ""
  local remain_num = 0
  local limit_num = 0
  if goods ~= nil then
    limit_num = goods.LimitNum or 0
    local sold_num = goods.SoldNum or 0
    remain_num = math.max(limit_num - sold_num, 0)
  end
  UIUtil.set_text_by_id(self._txt_battery_exchange_num, "UI_StarSea_ExchangesLeft", remain_num, limit_num)
  if remain_num == 0 then
    UIUtil.set_text_color(self._txt_battery_exchange_num, "#ea7354")
  else
    UIUtil.set_text_color(self._txt_battery_exchange_num, "#9b927e")
  end
end

function M:_on_btn_buy_click()
  local goods = self.goods
  if goods == nil then
    UIUtil.show_tips_by_text_id("TVShopping_no_goods")
    return
  end
  if tvshop_module:is_item_sold_out(goods) then
    UIUtil.show_tips_by_text_id("TVShopping_ExpireTip")
    return
  end
  local price = goods.Price or 0
  local cur_coin = CsPacketModuleUtil.GetCoinCountById(goods.CostTokenId or 0)
  if price > cur_coin then
    UIUtil.show_tips_by_text_id("TVShopping_no_money_tip")
    return
  end
  CsShopModuleUtil.TVShopBuyReq(goods.GoodsId, 1, function(rsp)
    if rsp ~= nil and rsp.Retcode == 0 then
      self:_refresh_buy_num_text()
      local battery_num = tostring(back_bag_module:get_coin_or_item_num(BATTERY_ITEM_ID))
      UIUtil.set_text(self._txt_battery_pack_num, battery_num)
      if not is_null(self._star_coin_view) then
        self._star_coin_view:set_coin_id(BATTERY_ITEM_ID)
      else
        self._star_coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item_battery, {coin_id = BATTERY_ITEM_ID, auto_update = true})
      end
    end
  end)
end

function M:_on_btn_cancel_click()
  UIManagerInstance:close(self.guid)
end

function M:_get_goods_by_item_id(item_id)
  local server_data = tvshop_module:get_tvshop_data()
  if server_data == nil then
    return nil
  end
  for _, page_data in ipairs(array_to_table(server_data.PageList)) do
    for _, goods in ipairs(array_to_table(page_data.GoodList)) do
      if goods.ItemConfigId == item_id then
        return goods
      end
    end
  end
  return nil
end

return M
