local M = G.Class("CommonConfirmBuyItemDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ConfirmView/CommonConfirmBuyItemDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_cancel)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_btn_buy_click))
  self:bind_callback(self._btn_add, pack(self, M._on_btn_add_click))
  self:bind_callback(self._btn_reduce, pack(self, M._on_btn_reduce_click))
  self:bind_callback(self._btn_icon_close, pack(self, M._on_btn_icon_close_click))
  self:bind_callback(self._slider_num, pack(self, M._on_slider_num_value_changed))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_btn_icon_close_click))
  end
  self:bind_callback(self._btn_show_info, pack(self, M._on_btn_show_info_click))
  self:bind_callback(self._btn_discount_tip, pack(self, M._on_btn_discount_tip_click))
  self:bind_callback(self._discount_fullscreen_close, pack(self, M._on_btn_discount_fullscreen_close_click))
end

function M:_on_btn_buy_click()
  if not self._extra_data then
    return
  end
  local can_close = true
  if self._extra_data.buy_callback then
    local _, total_coin = self:_get_exp_coin_info()
    can_close = self._extra_data.buy_callback(self._cur_num, total_coin)
  end
  if can_close ~= false then
    UIManagerInstance:close(self.guid)
  end
end

function M:_on_btn_add_click()
  local coin_id = self._extra_data and self._extra_data.coin_id or 0
  local unit_price = self._extra_data and self._extra_data.unit_price or 0
  if 0 < coin_id and 0 < unit_price then
    local balance = self:_get_available_balance(coin_id)
    local affordable_max = self:_get_affordable_max(balance, unit_price)
    local next_num = self._cur_num + 1
    if affordable_max < next_num then
      if self._extra_data.coin_not_enough_text then
        UIUtil.show_tips(self._extra_data.coin_not_enough_text)
      else
        UIUtil.show_tips_by_text_id("Item_CoinIsDeficiency")
      end
      local target = math.min(affordable_max, self._max_num or affordable_max)
      if 1 <= target then
        self._slider_num.value = target
      end
      return
    end
  end
  self._slider_num.value = self._cur_num + 1
end

function M:_get_available_balance(coin_id)
  local balance_func = self._extra_data and self._extra_data.available_balance_func
  if balance_func then
    return math.max(tonumber(balance_func()) or 0, 0)
  end
  return math.max(back_bag_module:get_coin(coin_id) or 0, 0)
end

function M:_get_affordable_max(balance, unit_price)
  local affordable_max = math.floor(balance / unit_price)
  local discount_price = self._extra_data.discount_price or 0
  if 0 < discount_price then
    local discount_start_num = self._extra_data.discount_start_num or 0
    local cost_before_discount = discount_start_num * unit_price
    if balance >= cost_before_discount then
      affordable_max = discount_start_num + math.floor((balance - cost_before_discount) / discount_price)
    end
  end
  return math.max(affordable_max, 0)
end

function M:_on_btn_reduce_click()
  self._slider_num.value = self._cur_num - 1
end

function M:_on_btn_icon_close_click()
  UIManagerInstance:close(self.guid)
end

function M:_calc_total_price(count)
  local total_price_func = self._extra_data.total_price_func
  if total_price_func then
    local total_price = total_price_func(count)
    if total_price ~= nil then
      return total_price
    end
  end
  local unit_price = self._extra_data.unit_price or 0
  local discount_price = self._extra_data.discount_price or 0
  if 0 < discount_price then
    local start = self._extra_data.discount_start_num or 0
    return math.min(count, start) * unit_price + math.max(0, count - start) * discount_price
  end
  return count * unit_price
end

function M:_set_coin()
  if self._extra_data.price_text then
    UIUtil.set_text(self._txt_price, self._extra_data.price_text)
    return
  end
  local exp_coin, total_coin, has_discount = self:_get_exp_coin_info()
  local coin_id = self._extra_data.coin_id or 0
  local not_enough = false
  if 0 < coin_id then
    local balance = self:_get_available_balance(coin_id)
    not_enough = 0 < total_coin and total_coin > balance
  end
  if not_enough then
    UIUtil.set_text(self._txt_price, string.format("<style=TextWarning_Light>%s</style>", tostring(total_coin)))
  else
    UIUtil.set_text(self._txt_price, tostring(total_coin))
  end
  UIUtil.set_text(self._txt_ori_coin_num, tostring(exp_coin))
  UIUtil.set_active(self._txt_ori_coin_num, has_discount)
  UIUtil.set_active(self._btn_discount_tip, has_discount)
  UIUtil.set_active(self._txt_discount_rate, has_discount)
  if has_discount then
    local unit_price = self._extra_data.unit_price or 0
    local discount_price = self._extra_data.discount_price or 0
    local rate = 0 < unit_price and math.ceil((unit_price - discount_price) / unit_price * 100) or 0
    UIUtil.set_text(self._txt_discount_rate, string.format("-%d%%", rate))
  end
  self._ui_state_group_price:SetState(has_discount and 1 or 0)
end

function M:_get_exp_coin_info()
  local exp_coin = math.modf((self._extra_data.unit_price or 0) * self._cur_num)
  local total_coin = math.modf(self:_calc_total_price(self._cur_num))
  return exp_coin, total_coin, exp_coin > total_coin
end

function M:_refresh_coin_icon()
  if is_null(self._img_coin_icon) then
    return
  end
  local coin_id = self._extra_data.coin_id
  if coin_id and 0 < coin_id then
    UIUtil.set_active(self._img_coin_icon, true)
    item_module:set_item_icon(self._img_coin_icon, coin_id, nil, nil, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_coin_icon, false)
  end
end

function M:_refresh_coin_item()
  if is_null(self._trans_coin_item) then
    return
  end
  local coin_id = self._extra_data.coin_id
  local should_show = 0 < (coin_id or 0) and self._extra_data.hide_coin_item ~= true
  if self._coin_item_panel then
    if should_show then
      self._coin_item_panel:set_data({coin_id = coin_id, mute_audio = true})
    end
    self._coin_item_panel:set_active(should_show)
    return
  end
  UIUtil.set_active(self._trans_coin_item, should_show)
  if should_show then
    self._coin_item_panel = self:add_panel(common_ui_module.common_coin_item_view_cls, self._trans_coin_item, {coin_id = coin_id, mute_audio = true})
  end
end

function M:_set_add_and_reduce_btn_state()
  if not self._cur_num or not self._max_num then
    return
  end
  self._btn_add.interactable = self._cur_num < self._max_num and self._max_num > 1
  self._btn_reduce.interactable = self._cur_num > 1
end

function M:_on_btn_cancel_click()
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_show_info_click()
  item_module:open_item_info_dialog(self._item_cfg.id, 0)
end

function M:_on_btn_discount_tip_click()
  self._is_show_discount_tip = true
  self:_set_discount_dialog()
end

function M:_on_btn_discount_fullscreen_close_click()
  self._is_show_discount_tip = false
  self:_set_discount_dialog()
end

function M:_refresh_view()
  if not self._extra_data then
    return
  end
  local data = self._extra_data
  local is_npc_cloth = data.is_npc_cloth == true
  local cfg = item_module:get_cfg_by_id(data.cfg_id)
  if not cfg then
    return
  end
  self._item_cfg = cfg
  UIUtil.set_text(self._txt_name, cfg.name)
  UIUtil.set_text(self._txt_have_num, back_bag_module:get_item_num(data.cfg_id) or 0)
  local show_group_num = data.item_group_num and data.item_group_num > 1 and tostring(data.item_group_num) or ""
  UIUtil.set_text(self._txt_group_num, show_group_num)
  local is_special_icon = item_module:item_is_recipe(data.cfg_id) or item_module:item_is_cooking_recipe(data.cfg_id) or item_module:is_unlock_appearance_card(data.cfg_id)
  if is_special_icon then
    item_module:set_item_big_icon(self._img_icon, 0, cfg, self:get_load_proxy())
    if not is_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
  else
    item_module:set_item_big_icon_with_prismatic(self._img_icon, 0, cfg, self:get_load_proxy(), self._img_icon_prismatic)
  end
  self._state_group_quality:SetState(cfg.rank)
  if self._state_group_npc and not is_null(self._state_group_npc) then
    self._state_group_npc:SetState(is_npc_cloth and 1 or 0)
  end
  self:_refresh_coin_icon()
  self:_refresh_item_size_ui()
  self:_refresh_slider_ui()
  self:_refresh_coin_item()
  self:_refresh_title()
  self:_refresh_discount_tip()
  self:_refresh_buy_text()
end

function M:_refresh_discount_tip()
  if self._extra_data.limit_tip then
    UIUtil.set_text(self._txt_limit_tip, self._extra_data.limit_tip)
  end
  UIUtil.set_active(self._txt_limit_tip, self._extra_data.limit_tip ~= nil)
  if self._extra_data.discount_tip_id then
    UIUtil.set_text(self._txt_discount_tip, UIUtil.get_text_by_id(self._extra_data.discount_tip_id))
  end
  UIUtil.set_active(self._txt_discount_tip, self._extra_data.discount_tip_id ~= nil)
  self._is_show_discount_tip = false
  self:_set_discount_dialog()
end

function M:_set_discount_dialog()
  UIUtil.set_active(self._obj_discount_tip, self._is_show_discount_tip)
  UIUtil.set_active(self._discount_fullscreen_close, self._is_show_discount_tip)
end

function M:_refresh_title()
  if self._extra_data.title_text then
    UIUtil.set_text(self._txt_title, self._extra_data.title_text)
  else
    UIUtil.set_text_by_id(self._txt_title, "Common_BuyGoods")
  end
end

function M:_refresh_buy_text()
  if self._extra_data.buy_text then
    UIUtil.set_text(self._txt_buy, self._extra_data.buy_text)
  else
    UIUtil.set_text_by_id(self._txt_buy, "Item_Buy")
  end
end

function M:_refresh_item_size_ui()
  local cfg = self._item_cfg
  local is_furniture = item_module:is_furniture(cfg.id, cfg.idCfg)
  UIUtil.set_active(self._txt_area, is_furniture)
  UIUtil.set_active(self._trans_floor_area.parent, is_furniture)
  if not is_furniture then
    return
  end
  local size_x, size_z = 0, 0
  local entity_cfg = cfg.idCfg.entityCfg
  if entity_cfg then
    size_x = entity_cfg.sizex / 2
    size_z = entity_cfg.sizez / 2
  end
  UIUtil.set_text(self._txt_area, string.format(UIUtil.get_text_by_id("multiplication_sign_fur"), size_x, size_z))
  self._trans_floor_area:SetLocalScale(math.min(size_x, 3), math.min(size_z, 3), 1)
end

function M:_refresh_slider_ui()
  local max_num = self._extra_data.max_num or 1
  self._max_num = max_num
  if max_num <= 1 then
    self._slider_num.minValue = 0
  else
    self._slider_num.minValue = 1
  end
  self._slider_num.maxValue = math.max(max_num, 1)
  self._slider_num.value = 1
  self._slider_num.interactable = 1 < max_num
  self._cur_num = 1
  if not_null(self._txt_num) then
    UIUtil.set_text_by_id(self._txt_num, "SellPacketPage_txt_buynum", "1")
  end
  self:_set_coin()
  self:_set_add_and_reduce_btn_state()
end

function M:_on_slider_num_value_changed(value)
  local target_num = math.modf(value)
  local coin_id = self._extra_data and self._extra_data.coin_id or 0
  local unit_price = self._extra_data and self._extra_data.unit_price or 0
  if 0 < coin_id and 0 < unit_price then
    local affordable_max = self:_get_affordable_max(self:_get_available_balance(coin_id), unit_price)
    local clamped_num = math.max(1, math.min(target_num, affordable_max))
    if clamped_num ~= target_num then
      self._slider_num.value = clamped_num
      if self._extra_data.coin_not_enough_text then
        UIUtil.show_tips(self._extra_data.coin_not_enough_text)
      else
        UIUtil.show_tips_by_text_id("Item_CoinIsDeficiency")
      end
      return
    end
  end
  if self._cur_num == target_num then
    return
  end
  self._cur_num = target_num
  UIUtil.set_text_by_id(self._txt_num, "SellPacketPage_txt_buynum", tostring(self._cur_num))
  self:_set_coin()
  self:_set_add_and_reduce_btn_state()
end

return M
