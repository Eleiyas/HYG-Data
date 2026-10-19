local M = G.Class("SpringFestivalCoinShoppingCardItem", G.UIPanel)
local base = G.UIPanel
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local empty_state = {
  Normal = 0,
  LightBg = 1,
  DarkBg = 2,
  SoldOut = 3
}

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_select_goods = data.on_select_goods
  self._coin_view = nil
  local coin_host = self._trans_coin_item or self._obj_coin_item
  if coin_host ~= nil then
    self._coin_view = self:add_panel(coin_item_view_cls, coin_host)
  end
  if self._tog_select ~= nil then
    self:bind_callback(self._tog_select, pack(self, M._on_click))
  elseif self._btn_click ~= nil then
    self:bind_callback(self._btn_click, pack(self, M._on_click_btn))
  end
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  data = data or {}
  self._on_select_goods = data.on_select_goods
end

function M:get_goods_id()
  return self._goods ~= nil and (self._goods.goods_id or 0) or 0
end

function M:refresh(goods, selected)
  self._goods = goods
  if self._ui_state_group_state_empty ~= nil then
    self._ui_state_group_state_empty:SetState(empty_state.Normal)
  end
  if self._tog_select ~= nil then
    self._tog_select.interactable = true
  end
  local item_id = goods ~= nil and (goods.item_id or 0) or 0
  local item_cfg = 0 < item_id and item_module:get_cfg_by_id(item_id) or nil
  local item_name = item_cfg ~= nil and (item_cfg.name or "") or ""
  local icon_path = item_cfg ~= nil and (item_cfg.tooltableicon or "") or ""
  if self._txt_label ~= nil then
    UIUtil.set_text(self._txt_label, item_name)
  end
  if self._img_icon ~= nil and icon_path ~= "" then
    UIUtil.set_image(self._img_icon, icon_path, self:get_load_proxy())
  end
  self:_refresh_quality(item_cfg)
  self:_refresh_price(goods)
  self:_refresh_red_point(goods)
  local sold_out = goods.remain_buy_num ~= nil and goods.remain_buy_num == 0
  if self._ui_state_group_state_empty ~= nil then
    self._ui_state_group_state_empty:SetState(sold_out and empty_state.SoldOut or empty_state.Normal)
  end
  local is_locked = goods.is_initial_locked == true
  if self._icon_lock_bg ~= nil then
    UIUtil.set_active(self._icon_lock_bg, is_locked)
  end
  self:_refresh_tracking_point(item_id)
  self:set_selected(selected == true)
end

function M:_refresh_tracking_point(item_id)
  if self._trans_tracking_item == nil then
    return
  end
  if item_id == nil or item_id <= 0 then
    UIUtil.set_active(self._trans_tracking_item, false)
    return
  end
  local tracking_data = tracking_module:get_track_data_by_track_type(tracking_module:get_manager_cur_track_type())
  local is_show = tracking_module:is_show_tracking_point_by_item_id(item_id, tracking_data)
  UIUtil.set_active(self._trans_tracking_item, is_show)
  if is_show and self._ui_state_group_style ~= nil and tracking_data ~= nil then
    local state = tracking_module:get_tracking_point_style(tracking_data.track_type, tracking_data.source_type, tracking_data.source_id)
    self._ui_state_group_style:SetState(state)
  end
end

function M:refresh_tracking_point_state()
  local item_id = self._goods ~= nil and (self._goods.item_id or 0) or 0
  self:_refresh_tracking_point(item_id)
end

function M:_refresh_red_point(goods)
  if is_null(self._red_point) then
    return
  end
  local red_point_type = goods ~= nil and (goods.red_point_type or RedPointType.None) or RedPointType.None
  self._red_point:ShowRedPoint(red_point_type)
end

function M:_refresh_quality(item_cfg)
  if self._ui_state_group_state_quilty == nil then
    return
  end
  if item_cfg == nil then
    self._ui_state_group_state_quilty:SetState(0)
    return
  end
  self._ui_state_group_state_quilty:SetState(item_cfg.rank or 0)
end

function M:_refresh_price(goods)
  local price = goods.price or 0
  local money_id = goods.money_id or 0
  if money_id <= 0 then
    money_id = spring_festival_coin_shop_module:get_coin_item_id() or 0
  end
  if self._coin_view ~= nil and 0 < money_id then
    self._coin_view:set_data({
      coin_id = money_id,
      auto_update = false,
      get_num_func = function()
        return price
      end
    })
    return
  end
end

function M:set_selected(selected)
  if self._tog_select ~= nil then
    self._tog_select:SetIsOnWithoutNotify(selected == true)
  end
end

function M:_on_click(is_on)
  if not is_on then
    self:set_selected(true)
    return
  end
  if self._on_select_goods ~= nil then
    self._on_select_goods(self._goods, self)
  end
end

function M:_on_click_btn()
  if self._on_select_goods ~= nil then
    self._on_select_goods(self._goods, self)
  end
end

function M:set_empty(style)
  self._goods = nil
  if self._ui_state_group_state_empty ~= nil then
    self._ui_state_group_state_empty:SetState(style or empty_state.LightBg)
  end
  if self._tog_select ~= nil then
    self._tog_select:SetIsOnWithoutNotify(false)
    self._tog_select.interactable = false
  end
  if self._trans_disable ~= nil then
    UIUtil.set_active(self._trans_disable, false)
  end
  if self._txt_soldout ~= nil then
    UIUtil.set_active(self._txt_soldout, false)
  end
  if self._icon_lock_bg ~= nil then
    UIUtil.set_active(self._icon_lock_bg, false)
  end
  if self._trans_tracking_item ~= nil then
    UIUtil.set_active(self._trans_tracking_item, false)
  end
  if not is_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

return M
