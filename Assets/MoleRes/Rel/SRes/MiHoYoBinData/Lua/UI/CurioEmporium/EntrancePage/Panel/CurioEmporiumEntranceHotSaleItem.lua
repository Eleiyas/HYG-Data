local M = G.Class("CurioEmporiumEntranceHotSaleItem", G.UIBase)
local base = G.UIBase
local quality_state = {
  Grey = 0,
  Green = 1,
  Purple = 2,
  Gold = 3
}
local item_type = {
  Normal = 0,
  Recipe = 1,
  Cookbook = 2,
  AppearanceCard = 3,
  Suits = 5
}
local slot_state = {
  Normal = 0,
  Empty = 1,
  SoldOut = 3
}
local price_state = {
  Normal = 0,
  DiscountWithValue = 1,
  DiscountWithoutValue = 2
}

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_click))
  end
end

function M:update(deltaTime)
  if not self._cfg then
    return
  end
  self._time_refresh_timer = (self._time_refresh_timer or 0) + deltaTime
  if self._time_refresh_timer >= 1 then
    self._time_refresh_timer = self._time_refresh_timer - 1
    self:_refresh_time()
  end
end

function M:refresh(cfg, goods_data, on_selected, load_proxy)
  self._cfg = cfg
  self._sdk_goods_data = nil
  self._server_goods_data = nil
  if not cfg:goodsid_is_empty() then
    self._sdk_goods_data = goods_data
  else
    self._server_goods_data = goods_data
  end
  self._on_selected = on_selected
  self._time_refresh_timer = 0
  self:_refresh_icon(cfg.id, load_proxy)
  self:_refresh_label()
  self:_refresh_quality(cfg.id)
  self:_refresh_item_type(cfg.id)
  self:_refresh_price()
  if self:_is_sold_out() then
    self:_hide_discount()
  end
  self:_refresh_slot_state()
  self:_refresh_time()
  self:_refresh_red_point()
end

function M:refresh_red_point()
  self:_refresh_red_point()
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  if not self._cfg then
    self._red_point:ShowRedPoint(RedPointType.None)
    return
  end
  self._red_point:ShowRedPoint(curio_emporium_module:get_gift_red_point_type(self._cfg.id))
end

function M:_refresh_icon(item_id, load_proxy)
  if is_null(self._img_icon) then
    return
  end
  item_module:set_item_icon(self._img_icon, item_id, nil, nil, load_proxy)
  if not is_null(self._img_suits) and curio_emporium_module:is_suit_auto_claim_gift(item_id) then
    item_module:set_item_icon(self._img_suits, item_id, nil, nil, load_proxy)
  end
end

function M:_refresh_label()
  if is_null(self._txt_label) then
    return
  end
  UIUtil.set_text(self._txt_label, item_module:get_item_name_by_id(self._cfg.id) or "")
end

function M:_refresh_quality(item_id)
  if is_null(self._ui_state_group_state_quilty) then
    return
  end
  if not item_id or item_id <= 0 then
    self._ui_state_group_state_quilty:SetState(quality_state.Grey)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._ui_state_group_state_quilty:SetState(quality_state.Grey)
    return
  end
  self._ui_state_group_state_quilty:SetState(cfg.rank or 0)
end

function M:_refresh_item_type(item_id)
  if is_null(self._ui_state_group_state_item) then
    return
  end
  if not item_id or item_id <= 0 then
    self._ui_state_group_state_item:SetState(item_type.Normal)
    return
  end
  if item_module:item_is_recipe(item_id) then
    self._ui_state_group_state_item:SetState(item_type.Recipe)
  elseif item_module:is_unlock_appearance_card(item_id) then
    self._ui_state_group_state_item:SetState(item_type.AppearanceCard)
  elseif curio_emporium_module:is_suit_auto_claim_gift(item_id) then
    self._ui_state_group_state_item:SetState(item_type.Suits)
  else
    self._ui_state_group_state_item:SetState(item_type.Normal)
  end
end

function M:_refresh_price()
  local has_goods_id = not self._cfg:goodsid_is_empty()
  if has_goods_id then
    self:_refresh_price_by_goods_data()
  else
    self:_refresh_price_by_cfg()
  end
end

function M:_refresh_price_by_goods_data()
  UIUtil.set_active(self._img_coin_icon, false)
  if not self._sdk_goods_data or is_null(self._sdk_goods_data.price) then
    if not is_null(self._txt_price) then
      UIUtil.set_text(self._txt_price, "")
    end
    self:_hide_discount()
    return
  end
  local price_info = self._sdk_goods_data.price
  if not is_null(self._txt_price) then
    UIUtil.set_text(self._txt_price, price_info.amountDisplay or "")
  end
  local original_display = price_info.originalAmountDisplay
  local has_discount = original_display and original_display ~= ""
  local should_show_value_tag = has_discount or self._cfg.saletag == 1
  if should_show_value_tag then
    self:_show_discount_without_value()
  else
    self:_hide_discount()
  end
end

function M:_refresh_price_by_cfg()
  if not is_null(self._img_coin_icon) then
    UIUtil.set_active(self._img_coin_icon, true)
    local cost_item_id = self._cfg.costitemid
    if cost_item_id and 0 < cost_item_id then
      item_module:set_item_icon(self._img_coin_icon, cost_item_id, nil, nil, self:get_load_proxy())
    end
  end
  local price = self._cfg.price or 0
  local original_price = self._cfg.originalprice or 0
  if not is_null(self._txt_price) then
    if 0 < price then
      UIUtil.set_text(self._txt_price, tostring(price))
    else
      UIUtil.set_text(self._txt_price, "")
    end
  end
  local has_discount = 0 < original_price and price < original_price
  if has_discount then
    self:_show_discount_with_value(original_price, price)
  elseif self._cfg.saletag == 1 then
    self:_show_discount_without_value()
  else
    self:_hide_discount()
  end
end

function M:_show_discount_without_value()
  if not is_null(self._ui_state_group_price) then
    self._ui_state_group_price:SetState(price_state.DiscountWithoutValue)
  end
end

function M:_show_discount_with_value(original_price, price)
  if not is_null(self._ui_state_group_price) then
    self._ui_state_group_price:SetState(price_state.DiscountWithValue)
  end
  if not is_null(self._txt_discount) then
    local discount_pct = math.floor((original_price - price) * 100 / original_price)
    UIUtil.set_text(self._txt_discount, "-" .. tostring(discount_pct) .. "%")
  end
end

function M:_hide_discount()
  if not is_null(self._ui_state_group_price) then
    self._ui_state_group_price:SetState(price_state.Normal)
  end
end

function M:_refresh_time()
  local cfg = self._cfg
  if not cfg then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local endtime = cfg.endtime
  if not endtime or endtime == "" then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local end_ts = curio_emporium_module:parse_endtime(endtime)
  if end_ts <= 0 then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local remain_seconds = end_ts - now
  if remain_seconds <= 0 then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local time_text = curio_emporium_module:format_remain_time(remain_seconds)
  UIUtil.set_active(self._txt_time, true)
  UIUtil.set_text(self._txt_time, time_text)
end

function M:_is_sold_out()
  local cfg = self._cfg
  if not cfg then
    return false
  end
  if not cfg:goodsid_is_empty() then
    return curio_emporium_module:is_sdk_goods_sold_out(self._sdk_goods_data)
  end
  local purchase_limit = cfg.purchaselimit
  if purchase_limit and 0 < purchase_limit then
    local bought_num = 0
    if self._server_goods_data then
      bought_num = self._server_goods_data.BoughtNum
    end
    return purchase_limit <= bought_num
  end
  return false
end

function M:_refresh_slot_state()
  if is_null(self._ui_state_group_state_empty) then
    return
  end
  if self:_is_sold_out() then
    self._ui_state_group_state_empty:SetState(slot_state.SoldOut)
  else
    self._ui_state_group_state_empty:SetState(slot_state.Normal)
  end
end

function M:set_empty()
  self._cfg = nil
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(false)
  end
  if not is_null(self._ui_state_group_state_empty) then
    self._ui_state_group_state_empty:SetState(slot_state.Empty)
  end
  if not is_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
  self:_hide_discount()
end

function M:_on_click(is_on)
  if not is_on then
    return
  end
  if self._on_selected and self._cfg then
    self._on_selected(self._cfg, self)
  end
end

function M:set_select(select)
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(select)
  end
end

return M
