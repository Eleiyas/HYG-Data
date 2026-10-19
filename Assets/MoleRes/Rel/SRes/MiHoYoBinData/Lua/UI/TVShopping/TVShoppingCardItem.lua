local M = G.Class("TVShoppingCardItem", G.UIPanel)
local base = G.UIPanel
local item_type = {
  Normal = 0,
  Recipe = 1,
  Cookbook = 2,
  AppearanceCard = 3,
  ColorCard = 4
}
local quality_state = {
  Grey = 0,
  Green = 1,
  Purple = 2,
  Gold = 3,
  Prismatic = 4
}
local empty_state = {
  Normal = 0,
  LightBg = 1,
  DarkBg = 2,
  SoldOut = 3
}
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls

function M:on_create()
  base.on_create(self)
  local extra = self:get_extra_data() or {}
  self._load_proxy = extra.load_proxy
  self._select_item_callback = extra.select_item_callback
  self._coin_view = self:add_panel(coin_item_view_cls, self._trans_coin_item)
  self:bind_callback(self._tog_select, pack(self, M._on_click))
  self:bind_callback(self._btn_collection, pack(self, M._on_click_btn_collection))
  self:add_evt_listener(EventID.Tutorial.OnTutorialStart, function()
    if self.game_obj.activeInHierarchy then
      self:set_tutorial_dynamic_key()
    end
  end)
end

function M:refresh(data, tab_type, page_id, index)
  self._raw_data = data.raw_data
  self._tab_type = tab_type
  self._page_id = page_id
  self:_refresh_soldout()
  if not_null(self._tog_select) then
    self._tog_select.interactable = true
  end
  local item_id = self._raw_data.ItemConfigId
  local cfg = item_module:get_cfg_by_id(item_id)
  self:_refresh_icon(item_id, cfg)
  self:_refresh_quality(item_id, cfg)
  self:_refresh_item_type(item_id)
  self:_refresh_price()
  self:_refresh_label(cfg)
  self:_refresh_collection()
  self:_refresh_new(index)
  self:_refresh_tracking_point()
  self:_refresh_time_limit()
  self:set_select(false)
  self:set_tutorial_dynamic_key()
end

function M:_refresh_icon(item_id, cfg)
  if cfg and cfg.tooltableicon then
    item_module:set_item_icon_sprite(self._img_icon, cfg.tooltableicon, self._load_proxy, self._img_icon_prismatic)
  end
end

function M:_refresh_quality(item_id, cfg)
  if cfg == nil then
    self._ui_state_group_state_quilty:SetState(0)
    return
  end
  self._ui_state_group_state_quilty:SetState(cfg.rank or 0)
end

function M:_refresh_item_type(item_id)
  if item_module:item_is_recipe(item_id) then
    self._ui_state_group_state_item:SetState(item_type.Recipe)
  elseif item_module:is_unlock_appearance_card(item_id) then
    if item_module:is_hair_color_unlock(item_id) or item_module:is_eye_color_unlock(item_id) then
      self._ui_state_group_state_item:SetState(item_type.ColorCard)
    else
      self._ui_state_group_state_item:SetState(item_type.AppearanceCard)
    end
  else
    self._ui_state_group_state_item:SetState(item_type.Normal)
  end
end

function M:_refresh_price()
  if not self._coin_view then
    return
  end
  local token_id = self._raw_data.CostTokenId or 0
  local price = self._raw_data.Price or 0
  self._coin_view:set_data({
    coin_id = token_id,
    auto_update = false,
    get_num_func = function()
      return price
    end
  })
  local txt = self._coin_view._txt_coin_num
  if not_null(txt) then
    local owned = CsPacketModuleUtil.GetCoinCountById(token_id)
    if 0 < price and price > owned then
      UIUtil.set_text(txt, "<style=TextWarning_Light>" .. tostring(price) .. "</style>")
    end
  end
end

function M:_refresh_label(cfg)
  if cfg ~= nil then
    UIUtil.set_text(self._txt_label, cfg.name)
  else
    UIUtil.set_text(self._txt_label, "")
  end
end

function M:_refresh_collection()
  local show = tvshop_module:show_btn_like(self._tab_type, self._page_id)
  if not_null(self._btn_collection) then
    UIUtil.set_active(self._btn_collection, show and self._raw_data.IsFavorite)
    if show then
      self._btn_collection:SetSelect(self._raw_data.IsFavorite or false)
    end
  end
end

function M:_refresh_time_limit()
  if is_null(self._icon_time_limit) then
    return
  end
  local is_event = tvshop_module:is_event_page(self._page_id)
  UIUtil.set_active(self._icon_time_limit, is_event)
end

function M:_refresh_soldout()
  local is_soldout = CsShopModuleUtil.shopData:IsTVShopGoodsSoldOut(self._raw_data)
  self._ui_state_group_state_empty:SetState(is_soldout and empty_state.SoldOut or empty_state.Normal)
  UIUtil.set_active(self._txt_soldout, is_soldout)
  UIUtil.set_active(self._trans_coin_item, not is_soldout)
end

function M:_refresh_new(index)
  if tvshop_module:show_tag_new(self._page_id) then
    self.is_new = CsShopModuleUtil.shopData:IsTVShopGoodsNew(self._raw_data)
    if self.is_new then
      self._red_point:ShowRedPoint(RedPointType.NewRp)
    else
      self._red_point:ShowRedPoint(RedPointType.None)
    end
    if self.is_new and index and index == 1 then
      self:_record_new()
    end
  else
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_refresh_tracking_point()
  if is_null(self._trans_tracking_item) then
    return
  end
  if self._raw_data == nil then
    UIUtil.set_active(self._trans_tracking_item, false)
    return
  end
  local tracking_data = tracking_module:get_track_data_by_track_type(tracking_module:get_manager_cur_track_type())
  local is_show = tracking_module:is_show_tracking_point_by_item_id(self._raw_data.ItemConfigId, tracking_data)
  UIUtil.set_active(self._trans_tracking_item, is_show)
  if is_show and self._ui_state_group_style then
    local state = tracking_module:get_tracking_point_style(tracking_data.track_type, tracking_data.source_type, tracking_data.source_id)
    self._ui_state_group_style:SetState(state)
  end
end

function M:refresh_tracking_point_state()
  self:_refresh_tracking_point()
end

function M:_on_click(is_on)
  if not is_on then
    self._tog_select:SetIsOnWithoutNotify(true)
    return
  end
  self:_record_new()
  if self._select_item_callback then
    self._select_item_callback(self)
  end
end

function M:_on_click_btn_collection()
  if self._raw_data then
    local add = not self._raw_data.IsFavorite
    if add and tvshop_module:is_favorite_full() then
      local count = tvshop_module:get_favorite_count()
      local limit = tvshop_module:get_favorite_limit()
      UIUtil.show_tips_by_text_id("TVShopping_FavorLimit", count, limit)
      return
    end
    CsShopModuleUtil.shopData:MarkTVShopGoodsFavoriteLocal(self._raw_data.GoodsId, add)
    CsShopModuleUtil.TVShopFavoriteOperateReq(self._raw_data.GoodsId, add)
    if not_null(self._btn_collection) then
      self._btn_collection:SetSelect(add)
    end
    if add then
      UIUtil.show_tips_by_text_id("TVShopping_FavorSuccess")
    end
  end
end

function M:_record_new()
  if self._raw_data and self.is_new then
    self.is_new = false
    tvshop_module:record_new_goods(self._raw_data.GoodsId)
    tvshop_module:clear_new_goods()
    self._red_point:ShowRedPoint(RedPointType.None)
    lua_event_module:send_event(lua_event_module.event_type.on_tv_shopping_item_new_record)
  end
end

function M:_is_item_locked()
  if self._raw_data then
    local player_uid = player_module:get_player_uid()
    return CsShopModuleUtil.shopData:IsTVShopGoodsLocked(self._raw_data, player_uid)
  end
  return false
end

function M:set_select(select)
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(select)
  end
end

function M:set_empty(style)
  self._raw_data = nil
  self._ui_state_group_state_empty:SetState(style or empty_state.LightBg)
  if not_null(self._tog_select) then
    self._tog_select.interactable = false
  end
  if not_null(self._trans_tracking_item) then
    UIUtil.set_active(self._trans_tracking_item, false)
  end
  self.is_new = false
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:set_item_data(item_id, cost_token_id, price)
  self._raw_data = nil
  local cfg = item_module:get_cfg_by_id(item_id)
  self:_refresh_icon(item_id, cfg)
  self:_refresh_quality(item_id, cfg)
  self:_refresh_item_type(item_id)
  self:_refresh_label(cfg)
  if not_null(self._ui_state_group_state_empty) then
    self._ui_state_group_state_empty:SetState(empty_state.Normal)
  end
  self:_hide_shop_only_features()
  self:_refresh_simple_price(cost_token_id, price)
  if not_null(self._tog_select) then
    self._tog_select.interactable = false
  end
end

function M:_hide_shop_only_features()
  if not_null(self._btn_collection) then
    UIUtil.set_active(self._btn_collection, false)
  end
  if not_null(self._trans_disable) then
    UIUtil.set_active(self._trans_disable, false)
  end
  if not_null(self._txt_soldout) then
    UIUtil.set_active(self._txt_soldout, false)
  end
  if not_null(self._trans_tracking_item) then
    UIUtil.set_active(self._trans_tracking_item, false)
  end
  if not_null(self._icon_time_limit) then
    UIUtil.set_active(self._icon_time_limit, false)
  end
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
  self.is_new = false
end

function M:_refresh_simple_price(cost_token_id, price)
  if is_null(self._trans_coin_item) then
    return
  end
  local token_id = cost_token_id or 0
  local cost = price or 0
  local show = 0 < token_id and 0 < cost
  UIUtil.set_active(self._trans_coin_item, show)
  if not show or not self._coin_view then
    return
  end
  self._coin_view:set_data({
    coin_id = token_id,
    auto_update = false,
    get_num_func = function()
      return cost
    end
  })
  local txt = self._coin_view._txt_coin_num
  if not_null(txt) then
    local owned = CsPacketModuleUtil.GetCoinCountById(token_id)
    if cost > owned then
      UIUtil.set_text(txt, "<style=TextWarning_Light>" .. tostring(cost) .. "</style>")
    end
  end
end

function M:set_tutorial_dynamic_key()
  if self._raw_data and self._raw_data.ItemConfigId then
    local item_id = self._raw_data.ItemConfigId
    local dynamic_tutorial_ui_key = tutorial_module:check_tutorial_dynamic_key(GraphDynamicUIKeyType.TVShoppingItem, item_id)
    if dynamic_tutorial_ui_key and dynamic_tutorial_ui_key ~= 0 then
      self._tutorial_marker:ActiveDynamicTutorialKey(dynamic_tutorial_ui_key)
      return
    end
  end
  if not is_null(self._tutorial_marker) then
    self._tutorial_marker:DeactiveDynamicTutorialKey()
  end
end

return M
