local M = G.Class("CommonConfirmExchangeDialog", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonConfirmExchangeDialog"
  self.config.type = EUIType.Dialog
  self._coin_items = {}
  self._target_coin_id = 0
  self._const_coin_id = 0
  self._cost_step = 1
  self._target_per_step = 1
  self._max_num = 0
  self._cur_num = 0
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
  self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange_click))
  self:bind_callback(self._btn_add, pack(self, M._on_btn_add_click))
  self:bind_callback(self._btn_reduce, pack(self, M._on_btn_reduce_click))
  self:bind_callback(self._slider_num, pack(self, M._on_slider_num_value_changed))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_bg_click))
  self:bind_callback(self._btn_max, pack(self, M._on_btn_max_click))
end

function M:_on_btn_exchange_click()
  if not self._target_coin_id or not self._const_coin_id then
    return
  end
  local owned_cost_coin_num = back_bag_module:get_coin_or_item_num(self._const_coin_id) or 0
  if self._cur_num == 0 or owned_cost_coin_num < self._cur_num then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("Gacha_Common_NoCoin_TopUp"), UIUtil.get_text_by_id("Gacha_T0_Confirm_Yes"), UIUtil.get_text_by_id("Gacha_T0_CoinExchange_No"), UIUtil.get_text_by_id("Gacha_T0_Confirm_Title"))
    popup:set_callbacks(function()
      curio_emporium_module:open_curio_emporium_page(curio_emporium_module.entrance_tag_type.top_up_mall)
    end)
    popup:show()
  else
    local target_coin_num = self:_calc_target_num(self._cur_num)
    gacha_module:request_coin_exchange({
      self._target_coin_id,
      target_coin_num,
      self._const_coin_id
    })
  end
  self:_on_btn_cancel_click()
end

function M:_on_btn_add_click()
  self._slider_num.value = self._cur_num + self._cost_step
end

function M:_on_btn_reduce_click()
  self._slider_num.value = self._cur_num - self._cost_step
end

function M:_on_btn_max_click()
  self._slider_num.value = self._max_num
end

function M:_set_add_and_reduce_btn_state()
  if not self._cur_num or not self._max_num then
    return
  end
  local step = self._cost_step
  self._btn_add.interactable = self._cur_num + step <= self._max_num
  self._btn_reduce.interactable = step <= self._cur_num - step
  self._btn_max.interactable = self._cur_num < self._max_num
end

function M:_on_btn_cancel_click()
  self:close_self()
end

function M:_on_btn_bg_click()
  self:close_self()
end

function M:_refresh_coin()
  local coins = {
    self._const_coin_id,
    self._target_coin_id
  }
  local cur_coin_num = math.max(#self._coin_items, #coins)
  for i = 1, cur_coin_num do
    if coins[i] then
      if self._coin_items[i] == nil then
        self._coin_items[i] = self:_create_coin_item(coins[i])
      end
      self._coin_items[i]:set_coin_id(coins[i])
      self._coin_items[i]:set_active(true)
    elseif self._coin_items[i] then
      self._coin_items[i]:set_active(false)
    end
  end
end

function M:_create_coin_item(coin_type)
  local obj = UIUtil.load_prefab_set_parent(self._obj_coin_item, self._right_layout_group.transform, coin_item_view_cls)
  local coin_item = self:add_panel(coin_item_view_cls, obj, {
    coin_id = coin_type,
    auto_update = true,
    show_detail = true
  })
  return coin_item
end

function M:_refresh_view()
  if not self._extra_data then
    return
  end
  self._target_coin_id = self._extra_data.coin_id or 0
  self._const_coin_id = self._extra_data.const_coin_id or 0
  local cost_step, target_per_step = UIUtil.get_coin_exchange_ratio(self._target_coin_id, self._const_coin_id)
  if cost_step <= 0 or target_per_step <= 0 then
    return
  end
  self._cost_step = cost_step
  self._target_per_step = target_per_step
  local target_coin_cfg = item_module:get_cfg_by_id(self._target_coin_id)
  if target_coin_cfg then
    UIUtil.set_text(self._txt_target_coin_name, target_coin_cfg.name)
    UIUtil.set_text(self._txt_target_coin_num, self._target_per_step)
    item_module:set_item_icon(self._img_target_coin_icon, self._target_coin_id, nil, nil, self:get_load_proxy())
  end
  local const_coin_cfg = item_module:get_cfg_by_id(self._const_coin_id)
  if const_coin_cfg then
    UIUtil.set_text(self._txt_cost_coin_name, const_coin_cfg.name)
    UIUtil.set_text(self._txt_cost_coin_num, self._cost_step)
    item_module:set_item_icon(self._img_cost_coin_icon, self._const_coin_id, nil, nil, self:get_load_proxy())
  end
  self._show_num_prefix = UIUtil.get_text_by_id("Gacha_T0_CoinExchange_Content") .. ": \n"
  self:_refresh_coin()
  local owned_cost_coin_num = math.max(back_bag_module:get_coin_or_item_num(self._const_coin_id) or 0, 0)
  self:_refresh_slider_ui(owned_cost_coin_num)
end

function M:_refresh_slider_ui(owned_num)
  local step = self._cost_step
  local max_num = math.floor((owned_num or 0) / step) * step
  local min_num = step
  if step >= max_num then
    self._slider_num.minValue = 0
  else
    self._slider_num.minValue = step
  end
  self._cur_num = min_num
  self._max_num = math.max(max_num, min_num)
  self._slider_num.wholeNumbers = true
  self._slider_num.maxValue = self._max_num
  self._slider_num.value = min_num
  self._slider_num.interactable = step < max_num
  self:_refresh_num_text()
  self:_set_add_and_reduce_btn_state()
end

function M:_calc_target_num(cost_num)
  local step = self._cost_step
  if step <= 0 then
    return 0
  end
  return math.floor(cost_num / step) * self._target_per_step
end

function M:_refresh_num_text()
  if is_null(self._txt_num) then
    return
  end
  UIUtil.set_text(self._txt_num, self._show_num_prefix .. tostring(self:_calc_target_num(self._cur_num)))
end

function M:_on_slider_num_value_changed(value)
  local step = self._cost_step
  local snapped = math.floor(value / step + 0.5) * step
  local min_num = step <= self._max_num and step or 0
  snapped = math.max(math.min(snapped, self._max_num), min_num)
  if snapped ~= value then
    self._slider_num.value = snapped
    return
  end
  if self._cur_num == snapped then
    return
  end
  self._cur_num = snapped
  self:_refresh_num_text()
  self:_set_add_and_reduce_btn_state()
end

return M
