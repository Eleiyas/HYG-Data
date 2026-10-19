local M = G.Class("CurioEmporiumEntranceFirstRechargePanel", G.CurioEmporiumEntrancePanelBase)
local base = G.CurioEmporiumEntrancePanelBase
local FIRST_RECHARGE_TYPE = 1
local QUERY_TIMEOUT = 15
local introduction_id = 43

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumSoloSalePanel"
end

function M:on_create()
  self._cfg = nil
  self._sdk_goods_data = nil
  self._server_goods_data = nil
  self._next_gift_time_change = nil
  self._refresh_check_timer = nil
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  if self._query_timer then
    self._query_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOnStoreGoodsInfoRefreshed, pack(self, M._on_store_goods_info_refreshed))
  self:add_evt_listener(EventID.LuaOnOpenConditionNotify, pack(self, M._on_open_condition_notify))
end

function M:_on_open_condition_notify(condition_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if not curio_emporium_module:is_gift_unlock_condition(FIRST_RECHARGE_TYPE, condition_id) then
    return
  end
  self:_try_refresh_gift()
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:_on_store_goods_info_refreshed(config_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if self._query_timer then
    return
  end
  if not curio_emporium_module:is_refreshed_goods_match(self._cfg, config_id) then
    return
  end
  self:_on_sdk_pay_finish(self._cfg)
end

function M:update(deltaTime)
  if self._query_timer then
    self._query_timer = self._query_timer + deltaTime
    if self._query_timer >= QUERY_TIMEOUT then
      self:_on_query_finish(false, nil)
    end
  end
  if self._next_gift_time_change then
    self._refresh_check_timer = (self._refresh_check_timer or 0) + deltaTime
    if self._refresh_check_timer >= 1 then
      self._refresh_check_timer = 0
      if TimeUtil.ServerUtcTimeSeconds >= self._next_gift_time_change then
        self:_try_refresh_gift()
      end
    end
  end
  if self._cfg then
    self._time_refresh_timer = (self._time_refresh_timer or 0) + deltaTime
    if 1 <= self._time_refresh_timer then
      self._time_refresh_timer = self._time_refresh_timer - 1
      self:_refresh_time()
    end
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_buy_click))
  self:bind_callback(self._btn_info, pack(self, M._on_info_click))
  self:bind_callback(self._btn_look, pack(self, M._on_look_click))
end

function M:set_tag_cfg(cfg)
  base.set_tag_cfg(self, cfg)
  if is_null(self._txt_ad_des) then
    return
  end
  UIUtil.set_text(self._txt_ad_des, cfg and cfg.advdesc or "")
end

function M:refresh()
  base.refresh(self)
  local cfgs = curio_emporium_module:get_gift_cfg_by_type(FIRST_RECHARGE_TYPE)
  self._next_gift_time_change = curio_emporium_module:get_next_gift_time_change(FIRST_RECHARGE_TYPE)
  if not cfgs or #cfgs == 0 then
    self._cfg = nil
    self._sdk_goods_data = nil
    self._server_goods_data = nil
    UIUtil.set_active(self._obj_root, false)
    self:_hide_original_price()
    UIUtil.set_active(self._obj_discount, false)
    return
  end
  self._cfg = cfgs[1]
  self._sdk_goods_data = nil
  self._server_goods_data = nil
  if not self._cfg:goodsid_is_empty() then
    self._query_timer = 0
    EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
    UIUtil.set_active(self._obj_root, false)
    curio_emporium_module:query_permanent_item_goods(pack(self, M._on_query_finish))
  else
    UIUtil.set_active(self._obj_root, true)
    self._server_goods_data = CsGameStoreModuleUtil.GetCurioShopGoods(self._cfg.id)
    self:_refresh_detail()
  end
end

function M:_try_refresh_gift()
  if self._query_timer then
    return
  end
  self._next_gift_time_change = curio_emporium_module:get_next_gift_time_change(FIRST_RECHARGE_TYPE)
  local cfgs = curio_emporium_module:get_gift_cfg_by_type(FIRST_RECHARGE_TYPE)
  local cfg = cfgs and cfgs[1] or nil
  local cur_id = self._cfg and self._cfg.id or nil
  local new_id = cfg and cfg.id or nil
  if cur_id == new_id then
    return
  end
  self:refresh()
end

function M:_on_query_finish(success, goods_dict)
  if not self._query_timer then
    return
  end
  self._query_timer = nil
  EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  if is_null(self.game_obj) then
    return
  end
  local dict = success and goods_dict or nil
  self._sdk_goods_data = curio_emporium_module:get_sdk_goods_data(self._cfg, dict)
  if not curio_emporium_module:is_goods_displayable(self._cfg, dict) then
    UIUtil.set_active(self._obj_root, false)
    return
  end
  UIUtil.set_active(self._obj_root, true)
  self:_refresh_detail()
end

function M:_refresh_detail()
  self._time_refresh_timer = 0
  self:_refresh_name()
  if self:_is_sold_out() then
    self:_hide_original_price()
    UIUtil.set_active(self._obj_discount, false)
  else
    self:_refresh_price()
  end
  self:_refresh_time()
  self:_refresh_buy_btn_state()
  self:_mark_gift_shown()
end

function M:_mark_gift_shown()
  if not self._cfg then
    return
  end
  if curio_emporium_module:is_gift_shown(self._cfg.id) then
    return
  end
  curio_emporium_module:mark_gift_shown(self._cfg.id)
  if self.holder and self.holder.refresh_all_tag_red_point then
    self.holder:refresh_all_tag_red_point()
  end
end

function M:_refresh_name()
  if is_null(self._txt_name) then
    return
  end
  UIUtil.set_text(self._txt_name, item_module:get_item_name_by_id(self._cfg.id) or "")
end

function M:_refresh_price()
  if self._cfg:goodsid_is_empty() then
    self:_refresh_price_by_cfg()
  else
    self:_refresh_price_by_goods()
  end
end

function M:_refresh_price_by_goods()
  local goods = self._sdk_goods_data
  if not goods or is_null(goods.price) then
    if not is_null(self._txt_price) then
      UIUtil.set_text(self._txt_price, "")
    end
    self:_hide_original_price()
    UIUtil.set_active(self._obj_discount, false)
    return
  end
  local price_info = goods.price
  if not is_null(self._txt_price) then
    UIUtil.set_text_by_id(self._txt_price, "Curio_Emporium_Good_Buy_Btn_Txt", price_info.amountDisplay or "")
  end
  local original_display = price_info.originalAmountDisplay
  local has_discount = original_display and original_display ~= ""
  if has_discount then
    if not is_null(self._txt_original_price) then
      UIUtil.set_active(self._txt_original_price, true)
      UIUtil.set_text(self._txt_original_price, original_display)
    end
  else
    self:_hide_original_price()
  end
  UIUtil.set_active(self._obj_discount, has_discount or self._cfg.saletag == 1)
end

function M:_refresh_price_by_cfg()
  local price = self._cfg.price or 0
  if not is_null(self._txt_price) then
    UIUtil.set_text_by_id(self._txt_price, "Curio_Emporium_Good_Buy_Btn_Txt", price)
  end
  local original_price = self._cfg.originalprice or 0
  local has_discount = 0 < original_price and price < original_price
  if has_discount then
    if not is_null(self._txt_original_price) then
      UIUtil.set_active(self._txt_original_price, true)
      UIUtil.set_text(self._txt_original_price, tostring(original_price))
    end
  else
    self:_hide_original_price()
  end
  UIUtil.set_active(self._obj_discount, has_discount or self._cfg.saletag == 1)
end

function M:_hide_original_price()
  if not is_null(self._txt_original_price) then
    UIUtil.set_active(self._txt_original_price, false)
  end
end

function M:_refresh_time()
end

function M:_is_sold_out()
  local cfg = self._cfg
  if not cfg then
    return false
  end
  if not cfg:goodsid_is_empty() then
    if curio_emporium_module:is_sdk_goods_sold_out(self._sdk_goods_data) then
      return true
    end
  else
    local purchase_limit = cfg.purchaselimit
    if purchase_limit and 0 < purchase_limit then
      local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
      local bought_num = 0
      if server_data then
        bought_num = server_data.BoughtNum
      end
      if purchase_limit <= bought_num then
        return true
      end
    end
  end
  return false
end

function M:_refresh_buy_btn_state()
  if is_null(self._btn_buy) then
    return
  end
  local cfg = self._cfg
  if not cfg then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  if not cfg:goodsid_is_empty() and not self._sdk_goods_data then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  UIUtil.set_active(self._btn_buy, true)
  local endtime = cfg.endtime
  if endtime and endtime ~= "" then
    local end_ts = curio_emporium_module:parse_endtime(endtime)
    if 0 < end_ts and end_ts <= TimeUtil.ServerUtcTimeSeconds then
      self._btn_buy.interactable = false
      return
    end
  end
  if not cfg:goodsid_is_empty() then
    if not curio_emporium_module:can_buy_sdk_goods(self._sdk_goods_data) then
      self._btn_buy.interactable = false
      return
    end
  elseif self:_is_sold_out() then
    self._btn_buy.interactable = false
    return
  end
  self._btn_buy.interactable = true
end

function M:_on_buy_click()
  if curio_emporium_module:try_block_store_with_tip() then
    return
  end
  if curio_emporium_module:try_block_tag_with_tip(curio_emporium_module.entrance_tag_type.first_recharge) then
    return
  end
  if not self._cfg then
    return
  end
  self:_do_buy()
end

function M:_do_buy()
  local cfg = self._cfg
  if not cfg:goodsid_is_empty() then
    CsGameStoreModuleUtil.PayGoods(cfg.goodsid, function(ret, msg)
      if ret == 0 then
        curio_emporium_module:show_purchase_reward(cfg.id)
      else
        Logger.LogWarning("[CurioEmporiumFirstRecharge] Pay failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
      end
      if is_null(self.game_obj) then
        return
      end
      self:_on_sdk_pay_finish(cfg)
    end)
  else
    if self:_check_currency_lack(cfg) then
      return
    end
    CsGameStoreModuleUtil.CurioShopBuySimple(cfg.id, 1, function(retcode)
      if retcode ~= 0 then
        Logger.LogWarning("[CurioEmporiumFirstRecharge] CurioShopBuy failed, retcode=" .. tostring(retcode))
        return
      end
      curio_emporium_module:show_purchase_reward(cfg.id)
      if is_null(self.game_obj) then
        return
      end
      self:_on_buy_success()
    end)
  end
end

function M:_check_currency_lack(cfg)
  local cost_item_id = cfg.costitemid or 0
  local price = cfg.price or 0
  if cost_item_id <= 0 or price <= 0 then
    return false
  end
  local owned = back_bag_module:get_coin_or_item_num(cost_item_id) or 0
  if price <= owned then
    return false
  end
  local lack = price - owned
  if curio_emporium_module:try_block_recharge_with_tip(item_module:get_coin_lack_tip(cost_item_id)) then
    return true
  end
  UIManagerInstance:open("UI/ConfirmView/CommonRechargePromptDialog", {
    title = UIUtil.get_text_by_id("CommonRechargePromptDialog_Title"),
    info = UIUtil.get_text_by_id("CommonRechargePromptDialog_Info", lack),
    lack_amount = lack,
    confirm_callback = function()
      self.holder:change_tag(curio_emporium_module.entrance_tag_type.top_up_mall)
    end
  })
  return true
end

function M:_on_sdk_pay_finish(cfg)
  if not (cfg and self._cfg) or self._cfg.id ~= cfg.id then
    return
  end
  self._sdk_goods_data = CsGameStoreModuleUtil.GetGoods(cfg.goodsid)
  self:_refresh_detail()
end

function M:_on_buy_success()
  self._server_goods_data = CsGameStoreModuleUtil.GetCurioShopGoods(self._cfg.id)
  self:_refresh_detail()
end

function M:_on_info_click()
  if not self._cfg then
    return
  end
  common_ui_module:show_introduction_dialog(introduction_id)
end

function M:_on_look_click()
  if not self._cfg then
    return
  end
  if self.holder and self.holder.skip_next_resume_refresh then
    self.holder:skip_next_resume_refresh()
  end
  curio_emporium_module:open_item_details_page(self._cfg.id)
end

return M
