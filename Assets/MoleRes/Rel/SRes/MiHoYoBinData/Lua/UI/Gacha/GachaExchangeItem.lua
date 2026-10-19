local M = G.Class("GachaExchangeItem", G.UIPanel)
local base = G.UIPanel
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local item_type = {
  Normal = 0,
  Recipe = 1,
  AppearanceCard = 3,
  Suit = 5
}

function M:init()
  base.init(self)
  self._on_click = nil
  self._item_cfg = nil
  self._is_exchange = false
  self._is_selected = false
  self._discount_price = 0
  
  function self._get_num_func()
    return self._discount_price
  end
end

function M:on_create()
  base.on_create(self)
  self._coin_view = self:add_panel(coin_item_view_cls, self._trans_coin_item)
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_select_click))
  end
  self:add_lua_listener(lua_event_module.event_type.gacha_exchange_item_selected, pack(self, self._on_select_changed))
end

function M:refresh(item_info)
  self._item_cfg = item_info.pool_cfg
  self._on_click = item_info.on_click
  self._is_exchange = item_info.is_exchange
  if self._item_cfg == nil then
    return
  end
  self:_refresh_icon(self._item_cfg)
  self:_refresh_owned(self._item_cfg, item_info.drawn_map, item_info.exchanged_map)
  self:_refresh_price(self._item_cfg, item_info.drawn_map, item_info.exchanged_map)
  self:_refresh_select_state(item_info.selected)
end

function M:refresh_base(drawn_map, exchanged_map)
  local item_cfg = self._item_cfg
  if item_cfg == nil then
    return
  end
  self:_refresh_owned(item_cfg, drawn_map, exchanged_map)
  self:_refresh_price(item_cfg, drawn_map, exchanged_map)
end

function M:_refresh_icon(item_cfg)
  local item_id = item_cfg.itemid
  local cur_item_type = item_type.Normal
  if item_module:item_is_recipe(item_id) then
    cur_item_type = item_type.Recipe
  end
  self._ui_state_item_type:SetState(cur_item_type)
  local rank = item_module:get_item_quality_by_id(item_id) or 0
  self._state_group_quality:SetState(rank)
  item_module:set_item_big_icon_with_prismatic(self._img_icon, item_id, nil, self:get_load_proxy(), self._img_icon_prismatic)
end

function M:_refresh_owned(item_cfg, drawn_map, exchanged_map)
  local gacha_id = gacha_module:get_cur_gacha_id()
  local show_item_num = ""
  if item_cfg.unitcount and item_cfg.unitcount > 1 then
    show_item_num = tostring(item_cfg.unitcount)
  end
  UIUtil.set_text(self._txt_item_num, show_item_num)
  UIUtil.set_text(self._txt_item_name, item_cfg.name)
  local owned_count = gacha_module:get_item_owned_count(gacha_id, item_cfg.itemid, drawn_map, exchanged_map)
  UIUtil.set_text_by_id(self._txt_owner_num, "Gacha_T0_ClothShop_ItemObtainNum", tostring(owned_count))
  local state = GachaConst.exchange_state.not_owned
  if self._is_exchange then
    state = gacha_module:get_exchange_item_state(gacha_id, item_cfg, owned_count, drawn_map, exchanged_map)
  else
    state = gacha_module:get_pool_item_state(gacha_id, item_cfg, drawn_map, exchanged_map)
  end
  self._ui_state_owner:SetState(state)
end

function M:_refresh_price(shop_cfg, drawn_map, exchanged_map)
  if not self._coin_view then
    return
  end
  if not self._is_exchange then
    if not_null(self._txt_coin_num_original) then
      UIUtil.set_text(self._txt_coin_num_original, "")
    end
    if not_null(self._ui_state_discount) then
      self._ui_state_discount:SetState(0)
    end
    if not_null(self._discount_tip) then
      UIUtil.set_active(self._discount_tip, false)
    end
    self._coin_view:set_active(false)
    self._discount_price = 0
    return
  end
  self._coin_view:set_active(true)
  local token_id = shop_cfg.cointype or 0
  local price, discount_price, is_discount = gacha_module:get_shop_price_info(gacha_module:get_cur_gacha_id(), shop_cfg, drawn_map, exchanged_map)
  self._discount_price = discount_price
  UIUtil.set_text(self._txt_coin_num_original, is_discount and tostring(price) or "")
  self._coin_view:set_data({
    coin_id = token_id,
    auto_update = false,
    get_num_func = self._get_num_func
  })
  local txt = self._coin_view._txt_coin_num
  if not_null(txt) then
    local owned = gacha_module:get_owned_coin_count(token_id)
    if 0 < discount_price and discount_price > owned then
      local show_txt = gacha_module:wrap_style(tostring(discount_price), GachaConst.price_not_enough_style)
      UIUtil.set_text(txt, show_txt)
    end
  end
  self._ui_state_discount:SetState(is_discount and 1 or 0)
  if not_null(self._discount_tip) then
    local show_discount = is_discount and 0 < price
    UIUtil.set_active(self._discount_tip, show_discount)
    if show_discount then
      local discount_rate = math.ceil((price - discount_price) / price * 100)
      UIUtil.set_text(self._txt_discount_rate, "-" .. tostring(discount_rate) .. "%")
    end
  end
end

function M:_refresh_select_state(is_selected)
  if not_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(is_selected)
    self._is_selected = is_selected
  end
end

function M:_on_select_click(is_on)
  if self._item_cfg == nil then
    return
  end
  if not is_on and self._is_selected then
    self:_refresh_select_state(true)
    return
  end
  if is_on and self._on_click ~= nil then
    self._on_click(self._item_cfg)
    lua_event_module:send_event(lua_event_module.event_type.gacha_exchange_item_selected, self._item_cfg.index)
  end
end

function M:_on_select_changed(index)
  if self._item_cfg == nil then
    return
  end
  if index == self._item_cfg.index then
    self:_refresh_select_state(true)
  else
    self:_refresh_select_state(false)
  end
end

return M
