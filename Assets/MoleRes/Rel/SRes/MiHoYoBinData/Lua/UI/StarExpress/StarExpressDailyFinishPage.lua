local M = G.Class("StarExpressDailyFinishPage", G.UIWindow)
local base = G.UIWindow
local complete_order_item_cls_name = "UI/StarExpress/StarExpressManagerOrderItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExpress/StarExpressManagerPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._complete_order_items = {}
  if self._obj_order_item ~= nil then
    UIUtil.set_active(self._obj_order_item.transform, false)
  end
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._played_order_enter_anim = false
  self._played_total_earn_roll = false
  self._pending_total_earn_roll = false
  star_express_module:mark_opened_main_page_today()
  CsStarExpressModuleUtil.RefreshPlayerExpressData()
  self:_refresh_rider_level_ui()
  self:_refresh_redpoint()
  self:_refresh_finished_orders()
  UIUtil.set_text_by_id(self._txt_title_left, "StarExpress_AllDelivered_EndWord1")
  UIUtil.set_text_by_id(self._txt_title_right, "StarExpress_AllDelivered_EndWord2")
  UIUtil.set_text_by_id(self._txt_title, "StarExpress_AllDelivered_TotalEarning")
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_return ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_return)
  end
end

function M:_get_order_item(index)
  if self._complete_order_items[index] ~= nil then
    return self._complete_order_items[index]
  end
  local go = index == 1 and self._obj_order_item or UIUtil.load_prefab_set_parent(self._obj_order_item, self._trans_order_parent)
  local item_cls = self:add_panel(complete_order_item_cls_name, go.transform)
  self._complete_order_items[index] = item_cls
  return item_cls
end

function M:_refresh_finished_orders()
  local finished_orders = star_express_module:get_finished_orders()
  local is_working = star_express_module:is_working()
  local total_earn = 0
  local total_earn_origin = 0
  local ordered_items = {}
  for i, order_data in ipairs(finished_orders) do
    total_earn = total_earn + star_express_module:get_order_earn_money(order_data)
    total_earn_origin = total_earn_origin + (order_data.Reward or 0) + (order_data.ExtraFee or 0)
    if self._obj_order_item ~= nil then
      local item_cls = self:_get_order_item(i)
      item_cls:set_extra_data({order_data = order_data, is_working = is_working})
      item_cls:refresh(false, true)
      item_cls.trans:SetSiblingIndex(i - 1)
      ordered_items[i] = item_cls
    end
  end
  if self._obj_order_item ~= nil then
    for i = #finished_orders + 1, #self._complete_order_items do
      self._complete_order_items[i]:set_extra_data(nil)
      self._complete_order_items[i]:refresh()
    end
  end
  self:_refresh_total_earn(total_earn_origin, total_earn)
  self:_play_order_enter_anim(ordered_items)
end

function M:_play_order_enter_anim(ordered_items)
  if #ordered_items == 0 then
    return
  end
  if self._played_order_enter_anim then
    for _, item_cls in ipairs(ordered_items) do
      item_cls:play_timeout_reward_roll()
    end
    self:_play_total_earn_roll()
    return
  end
  self._played_order_enter_anim = true
  for i, item_cls in ipairs(ordered_items) do
    item_cls:play_order_enter_anim(i == 1 and function()
      self:_play_total_earn_roll()
    end or nil)
  end
end

function M:_refresh_total_earn(total_earn_origin, total_earn)
  if self._txt_curr_all == nil then
    return
  end
  if self._played_total_earn_roll or total_earn_origin == total_earn then
    UIUtil.set_text(self._txt_curr_all, TextMapFormatUtil.FormatInteger(total_earn))
    return
  end
  self._played_total_earn_roll = true
  self._pending_total_earn_roll = true
  self._roll_from_total_earn = total_earn_origin
  self._roll_to_total_earn = total_earn
  UIUtil.set_text(self._txt_curr_all, TextMapFormatUtil.FormatInteger(total_earn_origin))
end

function M:_play_total_earn_roll()
  if not self._pending_total_earn_roll then
    return
  end
  self._pending_total_earn_roll = false
  local txt_total = self._txt_curr_all
  local final_total = self._roll_to_total_earn
  UIUtil.do_anim_txt_number_roll(txt_total, self._roll_from_total_earn, final_total, 0.5, nil, function()
    UIUtil.set_text(txt_total, TextMapFormatUtil.FormatInteger(final_total))
  end)
end

function M:_refresh_rider_level_ui()
  local rider_level = CsStarExpressModuleUtil.Level or 0
  if self._txt_lv_num ~= nil then
    UIUtil.set_text(self._txt_lv_num, TextMapFormatUtil.FormatInteger(rider_level))
  end
  if self._slider ~= nil then
    local cur_exp = star_express_module:get_history().total_count or 0
    local next_need = star_express_module:get_rider_level_required_orders(rider_level + 1)
    if next_need ~= nil and 0 < next_need then
      self._slider.value = math.min(1, math.max(0, cur_exp / next_need))
    else
      self._slider.value = 1
    end
  end
end

function M:_refresh_redpoint()
  if is_null(self._redpoint) then
    return
  end
  self._redpoint:ShowRedPoint(star_express_module:get_award_red_point_type())
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnStarExpressPlayerDataUpdate, function()
    if star_express_module:check_switch_to_order_page(self) then
      return
    end
    self:_refresh_rider_level_ui()
    self:_refresh_redpoint()
    self:_refresh_finished_orders()
  end)
  self:add_lua_listener(lua_event_module.event_type.refresh_star_express_red_point, function()
    self:_refresh_redpoint()
  end)
end

function M:_add_ui_listener()
  if self._btn_return ~= nil then
    self:bind_callback(self._btn_return, pack(self, M._on_btn_close_click))
  end
  if self._btn_lv ~= nil then
    self:bind_callback(self._btn_lv, pack(self, M._on_btn_lv_page_click))
  end
end

function M:_on_btn_lv_page_click()
  star_express_module:open_award_page()
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  star_express_module:check_express_clothes_on_close()
  self:close_self()
end

return M
