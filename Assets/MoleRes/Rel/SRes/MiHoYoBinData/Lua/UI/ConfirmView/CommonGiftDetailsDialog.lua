local M = G.Class("CommonGiftDetailsDialog", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local item_v2_cls = item_module.item_v2_panel_cls_name
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
  ColorCard = 4,
  Suits = 5
}
local price_state = {
  Normal = 0,
  DiscountWithValue = 1,
  DiscountWithoutValue = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ConfirmView/CommonGiftDetailsDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_bg, pack(self, M._on_close))
  self:bind_callback(self._btn_close_popup, pack(self, M._on_close))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm))
  self:bind_callback(self._btn_item, pack(self, M._on_gift_item_click))
  self._coin_view_top = self:add_panel(coin_item_view_cls, self._trans_coin_item_top)
  self._gift_items = {}
  self._gift_list_inited = false
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_bg)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  if data == nil then
    return
  end
  self._items_data = data.items or {}
  self._is_obtained_func = data.is_obtained_func
  self._item_click_handler = data.on_item_click
  self._on_close_callback = data.on_close
  self._on_cancel_callback = data.on_cancel
  self._on_confirm_callback = data.on_confirm
  self._view_only = data.view_only
  self._ui_state_group_state_canbuy:SetState(self._view_only and 1 or 0)
  if not_null(self._btn_cancel) then
    UIUtil.set_active(self._btn_cancel, self._on_cancel_callback ~= nil)
  end
  if not_null(self._btn_confirm) then
    UIUtil.set_active(self._btn_confirm, self._on_confirm_callback ~= nil)
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, "CommonGiftDetails_Title")
  end
  if not_null(self._txt_gift_name) then
    UIUtil.set_text(self._txt_gift_name, data.title or "")
  end
  if not_null(self._txt_gift_content) then
    UIUtil.set_text(self._txt_gift_content, data.content_desc or "")
  end
  self:_refresh_gift_item(data)
  local coin_id = data.coin_id or 0
  local show_top_coin = data.show_top_coin ~= false and 0 < coin_id
  if show_top_coin and self._coin_view_top then
    UIUtil.set_active(self._trans_coin_item_top, true)
    self._coin_view_top:set_data({coin_id = coin_id, auto_update = true})
  else
    UIUtil.set_active(self._trans_coin_item_top, false)
  end
  self:_refresh_price(data, coin_id)
  if not_null(self._txt_limit) then
    if data.limit_text and data.limit_text ~= "" then
      UIUtil.set_active(self._txt_limit, true)
      UIUtil.set_text(self._txt_limit, data.limit_text)
    else
      UIUtil.set_active(self._txt_limit, false)
    end
  end
  self:_refresh_items()
  local quality = self:_get_max_quality()
  if not_null(self._ui_state_group_qual) then
    self._ui_state_group_qual:SetState(quality)
  end
end

function M:_refresh_price(data, coin_id)
  local is_sdk_goods = data.price_text ~= nil
  local price = tonumber(data.price) or 0
  local original_price = tonumber(data.original_price) or 0
  local has_price = is_sdk_goods or 0 < price or data.has_sale_tag == true
  UIUtil.set_active(self._trans_coin_item, has_price)
  if not has_price then
    UIUtil.set_active(self._obj_num_group, false)
    UIUtil.set_active(self._img_coin_icon_card, false)
    UIUtil.set_text(self._txt_coin_num_card, "")
    if not is_null(self._ui_state_group_price) then
      self._ui_state_group_price:SetState(price_state.Normal)
    end
    return
  end
  if is_sdk_goods then
    UIUtil.set_active(self._img_coin_icon, false)
    UIUtil.set_active(self._img_coin_icon_card, false)
    local current_price_display = data.price_text or ""
    UIUtil.set_text(self._txt_coin_num, current_price_display)
    UIUtil.set_text(self._txt_coin_num_card, current_price_display)
  else
    local show_coin_icon = 0 < coin_id
    UIUtil.set_active(self._img_coin_icon, show_coin_icon)
    UIUtil.set_active(self._img_coin_icon_card, show_coin_icon)
    if show_coin_icon then
      item_module:set_item_icon(self._img_coin_icon, coin_id, nil, nil, self:get_load_proxy())
      item_module:set_item_icon(self._img_coin_icon_card, coin_id, nil, nil, self:get_load_proxy())
    end
    local current_price_display = tostring(price)
    UIUtil.set_text(self._txt_coin_num, current_price_display)
    UIUtil.set_text(self._txt_coin_num_card, current_price_display)
  end
  local has_discount_with_value = not is_sdk_goods and 0 < original_price and price < original_price
  local has_original_price = data.is_sdk_discount == true or has_discount_with_value
  UIUtil.set_active(self._obj_num_group, has_original_price)
  if has_original_price then
    local original_price_display = is_sdk_goods and (data.original_price_text or "") or tostring(original_price)
    UIUtil.set_text(self._txt_coin_num_discount, original_price_display)
  end
  if not is_null(self._ui_state_group_price) then
    if has_discount_with_value then
      self._ui_state_group_price:SetState(price_state.DiscountWithValue)
      local discount_pct = math.floor((original_price - price) * 100 / original_price)
      UIUtil.set_text(self._txt_discount, "-" .. tostring(discount_pct) .. "%")
    elseif data.is_sdk_discount == true or data.has_sale_tag == true then
      self._ui_state_group_price:SetState(price_state.DiscountWithoutValue)
    else
      self._ui_state_group_price:SetState(price_state.Normal)
    end
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  if self._gift_items then
    for _, cls in pairs(self._gift_items) do
      if not_null(cls) then
        self:remove_panel(cls)
      end
    end
  end
  self._gift_items = nil
  self._gift_list_inited = false
  base.on_destroy(self)
end

function M:_refresh_gift_item(data)
  self._gift_item_id = data.gift_item_id
  if self._gift_item_id == nil or self._gift_item_id <= 0 then
    return
  end
  self:_refresh_icon(self._gift_item_id)
  self:_refresh_quality(self._gift_item_id)
  self:_refresh_item_type(self._gift_item_id)
end

function M:_refresh_icon(item_id)
  if is_null(self._img_icon) then
    return
  end
  UIUtil.set_image_color(self._img_icon, Color(1, 1, 1, 1))
  if curio_emporium_module:is_suit_auto_claim_gift(item_id) then
    item_module:set_item_icon(self._img_suits, item_id, nil, nil, self:get_load_proxy())
  elseif item_module:is_appearance_color_unlock_card(item_id) then
    item_module:set_appearance_unlock_image_and_color(self._img_icon, item_id, self:get_load_proxy())
  else
    item_module:set_item_icon(self._img_icon, item_id, nil, nil, self:get_load_proxy())
  end
end

function M:_refresh_quality(item_id)
  if is_null(self._ui_state_group_state_quilty) then
    return
  end
  if not item_id or item_id <= 0 then
    self._ui_state_group_state_quilty:SetState(0)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._ui_state_group_state_quilty:SetState(0)
    return
  end
  local quality = cfg.rank or 0
  self._ui_state_group_state_quilty:SetState(quality)
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
    if item_module:is_appearance_color_unlock_card(item_id) then
      self._ui_state_group_state_item:SetState(item_type.ColorCard)
    else
      self._ui_state_group_state_item:SetState(item_type.AppearanceCard)
    end
  elseif curio_emporium_module:is_suit_auto_claim_gift(item_id) then
    self._ui_state_group_state_item:SetState(item_type.Suits)
  else
    self._ui_state_group_state_item:SetState(item_type.Normal)
  end
end

function M:_refresh_items()
  local count = #self._items_data
  if is_null(self._scroll_item_list) then
    return
  end
  local is_first_list_init = not self._gift_list_inited
  if is_first_list_init then
    self._scroll_item_list:Init(pack(self, M._on_refresh_item), count)
    self._gift_list_inited = true
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      if not_null(self.game_obj) and not_null(self._scroll_item_list) then
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
        self:_refresh_items()
      end
    end)
  else
    self._scroll_item_list:ReLoad(pack(self, M._on_refresh_item), count)
  end
end

function M:_on_refresh_item(trans, index)
  index = index + 1
  local item_data = self._items_data[index]
  local inst_id = trans:GetInstanceID()
  local cls = self._gift_items[inst_id]
  if cls == nil then
    cls = self:add_panel(item_v2_cls, trans)
    self._gift_items[inst_id] = cls
    if cls ~= nil then
      local btn = cls:get_btn()
      if not_null(btn) then
        self:bind_callback(btn, function()
          local data = cls._bound_item_data
          if data then
            self:_on_item_click(data.config_id)
          end
        end)
      end
    end
  end
  if cls == nil then
    return
  end
  cls._bound_item_data = item_data
  if item_data == nil then
    cls:set_active(false)
    return
  end
  cls:set_active(true)
  cls:set_item_data(item_data.config_id, item_data.num)
  local obtained = false
  if self._is_obtained_func then
    obtained = self._is_obtained_func(item_data.config_id)
  end
  if cls.obj_check == nil then
    cls.obj_check = UIUtil.find_gameobject(trans, "Icon_Achieve_Powerful")
  end
  if not_null(cls.obj_check) then
    UIUtil.set_active(cls.obj_check, obtained)
  end
end

function M:_on_item_click(config_id)
  if config_id == nil or config_id <= 0 then
    return
  end
  if self._item_click_handler then
    self._item_click_handler(config_id)
    return
  end
  UIUtil.set_active(self.game_obj, false)
  item_module:open_item_info_dialog_by_data({
    cfg_id = config_id,
    on_close = function()
      if not is_null(self.game_obj) then
        UIUtil.set_active(self.game_obj, true)
      end
    end
  })
end

function M:_get_max_quality()
  local max_rank = 0
  for _, item_data in ipairs(self._items_data) do
    local cfg = item_module:get_cfg_by_id(item_data.config_id)
    if cfg and cfg.rank and max_rank < cfg.rank then
      max_rank = cfg.rank
    end
  end
  return max_rank
end

function M:_on_gift_item_click()
  if self._gift_item_id == nil or self._gift_item_id <= 0 then
    return
  end
  UIUtil.set_active(self.game_obj, false)
  item_module:open_item_info_dialog_by_data({
    cfg_id = self._gift_item_id,
    on_close = function()
      if not is_null(self.game_obj) then
        UIUtil.set_active(self.game_obj, true)
      end
    end
  })
end

function M:_on_btn_cancel()
  if self._on_cancel_callback then
    self._on_cancel_callback()
  end
  self:close_self()
end

function M:_on_btn_confirm()
  if self._on_confirm_callback then
    self._on_confirm_callback()
  end
  self:close_self()
end

function M:_on_close()
  if self._on_close_callback then
    self._on_close_callback()
  end
  self:close_self()
end

return M
