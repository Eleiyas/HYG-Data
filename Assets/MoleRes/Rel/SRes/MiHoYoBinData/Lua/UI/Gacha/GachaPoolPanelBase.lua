local M = G.Class("GachaPoolPanelBase", G.UIPanel)
local base = G.UIPanel
local draw_progress_type = {
  none = 0,
  in_single_draw = 1,
  in_ten_draw = 2
}

function M:init()
  base.init(self)
  self._activity_cfg = nil
  self._gacha_id = 0
  self._pool_end_time = 0
  self._is_activity_end = false
  self._time_count_down_interval = 1
  self._time_count_down_timer = 0
  self._draw_progress_type = draw_progress_type.none
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_history) then
    self:bind_callback(self._btn_history, pack(self, M._on_btn_history_click))
  end
  if not_null(self._btn_rule) then
    self:bind_callback(self._btn_rule, pack(self, M._on_btn_rule_click))
  end
  if not_null(self._btn_exchange) then
    self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange_click))
  end
  if not_null(self._tog_skip_anim) then
    self:bind_callback(self._tog_skip_anim, function(is_on)
      gacha_module:set_skip_anim(self._gacha_id, is_on)
    end)
  end
  if not_null(self._btn_reward) then
    self:bind_callback(self._btn_reward, pack(self, M._on_btn_reward_click))
  end
  self:_on_create_extend()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.CoinExchangeResult, pack(self, M._on_coin_exchange_result))
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self:_refresh_activity_time(deltaTime)
end

function M:_on_coin_exchange_result(rsp)
  local cur_draw_type = self._draw_progress_type
  self._draw_progress_type = draw_progress_type.none
  if rsp == nil or self._activity_cfg == nil or cur_draw_type == draw_progress_type.none then
    return
  end
  self:_refresh_extend()
  self:do_draw(cur_draw_type == draw_progress_type.in_ten_draw)
end

function M:refresh()
  local gacha_id = self:get_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  self._gacha_id = gacha_id
  self._draw_progress_type = draw_progress_type.none
  self._activity_cfg = activity_cfg
  local pool_info = gacha_module:get_pool_info(self._gacha_id)
  self._pool_end_time = pool_info and pool_info.EndTime or 0
  self._is_activity_end = false
  self._time_count_down_timer = 0
  self:_refresh_common(activity_cfg)
  self:_refresh_extend()
end

function M:get_gacha_id()
  return self._extra_data.gacha_id
end

function M:_refresh_common(activity_cfg)
  if activity_cfg == nil then
    return
  end
  if not_null(self._img_bg_dynamic) then
    UIUtil.set_image(self._img_bg_dynamic, activity_cfg.advpic, self:get_load_proxy())
  end
  if not_null(self._img_card_bg) and activity_cfg.cardbackgroundId ~= nil and activity_cfg.cardbackgroundId ~= "" then
    UIUtil.set_image(self._img_card_bg, activity_cfg.cardbackgroundId, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_theme_title, activity_cfg.name)
  if not_null(self._btn_play_video) then
    UIUtil.set_active(self._btn_play_video, activity_cfg.tab == GachaConst.tab.t0)
  end
  if not_null(self._btn_reward) then
    UIUtil.set_active(self._btn_reward, activity_cfg.gachaaccumulatedtag and activity_cfg.gachaaccumulatedtag == 1)
  end
  self:_refresh_exchange_entry(activity_cfg)
  self:_refresh_reward_entry(activity_cfg)
  self:_refresh_skip_toggle()
  self:_refresh_collect_progress()
  self:_force_refresh_activity_time()
end

function M:_refresh_exchange_entry(activity_cfg)
  local show = activity_cfg ~= nil and (activity_cfg.exchangeshopflag or 0) == GachaConst.exchange_shop_open
  if not_null(self._btn_exchange) then
    UIUtil.set_active(self._btn_exchange, show)
  end
  if not_null(self._txt_exchange) then
    UIUtil.set_text_by_id(self._txt_exchange, activity_cfg.subtab == GachaConst.sub_tab.cloth and "Gacha_T0_MainScreen_Exchange_Cloth" or "Gacha_T0_MainScreen_Exchange_Furniture")
  end
  if not_null(self._img_exchange_coin) and activity_cfg.exchangeshopcoinid ~= nil then
    item_module:set_item_icon(self._img_exchange_coin, activity_cfg.exchangeshopcoinid, nil, nil, self:get_load_proxy())
  end
  if not_null(self._txt_exchange_discount) and activity_cfg.exchangeshopcoinid ~= nil then
    local num = back_bag_module:get_coin_or_item_num(activity_cfg.exchangeshopcoinid) or 0
    UIUtil.set_text(self._txt_exchange_discount, tostring(num))
  end
end

function M:_refresh_reward_entry(activity_cfg)
  local is_than_max = false
  if not_null(self._txt_reward_count) then
    local max_reward_count = 0
    local reward_list = gacha_module:get_accum_reward_list(activity_cfg.gachapoolid)
    if reward_list ~= nil and 0 < #reward_list then
      max_reward_count = reward_list[#reward_list].times
    end
    local total_draw = gacha_module:get_total_draw_count(self._gacha_id) or 0
    is_than_max = max_reward_count <= total_draw
    UIUtil.set_text(self._txt_reward_count, string.format("%d/%d", total_draw, max_reward_count))
  end
  local red_point_state = gacha_module:get_accum_reward_red_point_type(self._gacha_id)
  if not_null(self._reward_redpoint) then
    self._reward_redpoint:ShowRedPoint(red_point_state)
  end
  local is_completed = is_than_max and red_point_state == RedPointType.None
  UIUtil.set_active(self._img_reward_complete, is_completed)
  UIUtil.set_active(self._reward_progress, not is_completed)
end

function M:_refresh_skip_toggle()
  if not_null(self._tog_skip_anim) then
    self._tog_skip_anim.isOn = gacha_module:is_skip_anim(self._gacha_id)
    UIUtil.set_active(self._tog_skip_anim, gacha_module:is_show_skip_toggle(self._activity_cfg))
  end
end

function M:_refresh_collect_progress()
  local owned, total = gacha_module:get_collect_progress(self._gacha_id)
  local ratio = 0 < total and owned / total or 0
  if not_null(self._txt_collect_progress) then
    UIUtil.set_text_by_id(self._txt_collect_progress, gacha_module:get_collect_desc_txtid(self._activity_cfg.subtab), owned, total)
  end
  if not_null(self._collect_progress) then
    self._collect_progress.value = ratio
  end
end

function M:_force_refresh_activity_time()
  self._time_count_down_timer = self._time_count_down_interval
  self:_refresh_activity_time(0)
end

function M:_refresh_activity_time(deltaTime)
  if self._pool_end_time == 0 or self._is_activity_end then
    return
  end
  self._time_count_down_timer = self._time_count_down_timer + deltaTime
  if self._time_count_down_timer < self._time_count_down_interval then
    return
  end
  self._time_count_down_timer = 0
  local end_time = self._pool_end_time
  if end_time <= 0 then
    self._is_activity_end = true
    UIUtil.set_text(self._txt_timer, "")
    return
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local remain = end_time - now
  if remain <= 0 then
    self._is_activity_end = true
    gacha_module:set_cur_gacha_id(0)
    lua_event_module:send_event(lua_event_module.event_type.gacha_single_activity_end)
    return
  end
  UIUtil.set_text(self._txt_timer, gacha_module:format_remain_time(remain))
end

function M:_on_btn_history_click()
  gacha_module:open_rule_history_dialog(GachaConst.rule_tab.history)
end

function M:_on_btn_rule_click()
  gacha_module:open_rule_history_dialog(GachaConst.rule_tab.details)
end

function M:_on_btn_exchange_click()
  self:on_exchange_click()
end

function M:_on_btn_reward_click()
  gacha_module:open_accum_reward_dialog(self._gacha_id)
end

function M:refresh_draw_ticket_price(draw_count, txt_price, img_coin)
  local activity_cfg = self._activity_cfg
  if activity_cfg == nil then
    return
  end
  local next_draw_index = (gacha_module:get_total_draw_count(self._gacha_id) or 0) + 1
  local price_cfg, total, cost_item_id = gacha_module:calc_draw_cost(activity_cfg, draw_count, next_draw_index)
  local enough = gacha_module:is_coin_enough(cost_item_id, total)
  local show_txt = tostring(total)
  if not enough then
    show_txt = gacha_module:wrap_style(show_txt, GachaConst.price_not_enough_style)
  end
  UIUtil.set_text(txt_price, show_txt)
  if not_null(img_coin) then
    item_module:set_item_icon(img_coin, cost_item_id, nil, nil, self:get_load_proxy())
  end
  if not_null(self._draw_state_group) then
    self._draw_state_group:SetState(0)
  end
end

function M:do_draw(is_ten_pull)
  local activity_cfg = self._activity_cfg
  if activity_cfg == nil then
    return
  end
  self._draw_progress_type = draw_progress_type.none
  self._cur_draw_type = is_ten_pull and draw_progress_type.in_ten_draw or draw_progress_type.in_single_draw
  local draw_count = is_ten_pull and GachaConst.draw_count.ten or GachaConst.draw_count.once
  local next_draw_index = (gacha_module:get_total_draw_count(self._gacha_id) or 0) + 1
  local price_cfg, need_ticket = gacha_module:calc_draw_cost(activity_cfg, draw_count, next_draw_index)
  if price_cfg == nil then
    return
  end
  local ticket_lack = need_ticket - gacha_module:get_owned_coin_count(price_cfg.cointype)
  if ticket_lack <= 0 then
    self:_enter_draw(activity_cfg, is_ten_pull)
    return
  end
  local coin2 = gacha_module:get_exchange_coin_id(price_cfg.cointype)
  if coin2 <= 0 then
    Logger.LogError("[GachaPoolPanelBase] 获取兑换货币 id 失败，目标货币 id: " .. tostring(price_cfg.cointype))
    return
  end
  local target_coin_name = item_module:get_item_name_by_id(price_cfg.cointype)
  local info_data = {
    target_coin_id = price_cfg.cointype,
    target_coin_name = target_coin_name,
    need_target_coin_count = ticket_lack,
    source_coin2_id = coin2
  }
  local need_cost2 = UIUtil.get_exchange_cost_for_lack(price_cfg.cointype, ticket_lack, coin2)
  info_data.need_source_coin2_count = need_cost2
  if gacha_module:is_coin_enough(coin2, need_cost2) then
    self:_show_buy_ticket_popup(info_data)
  else
    local lack_coin2 = need_cost2 - gacha_module:get_owned_coin_count(coin2)
    local coin1 = gacha_module:get_exchange_coin_id(coin2)
    if coin1 <= 0 then
      Logger.LogError("[GachaPoolPanelBase] 获取兑换货币 id 失败，目标货币 id: " .. tostring(coin2))
      return
    end
    local need_coin1 = UIUtil.get_exchange_cost_for_lack(coin2, lack_coin2, coin1)
    info_data.lack_source_coin2_count = lack_coin2
    info_data.source_coin1_id = coin1
    info_data.need_source_coin1_count = need_coin1
    if gacha_module:is_coin_enough(coin1, need_coin1) then
      self:_show_convert_coin_popup(info_data)
    else
      local has_coin1 = gacha_module:get_owned_coin_count(coin1)
      local lack_coin1 = need_coin1 - has_coin1
      info_data.lack_source_coin1_count = lack_coin1
      info_data.has_source_coin1_count = has_coin1
      self:_show_recharge_popup(info_data)
    end
  end
end

function M:_enter_draw(activity_cfg, is_ten_pull)
  gacha_module:request_draw(activity_cfg.gachaid, is_ten_pull, 0)
end

function M:_show_buy_ticket_popup(info_data)
  local coin2_path = item_module:get_item_icon(info_data.source_coin2_id)
  local popup = UIUtil.get_confirm_popup()
  local show_text = UIUtil.get_text_by_id("Gacha_T0_Confirm_Content_03", info_data.need_target_coin_count, info_data.target_coin_name, coin2_path, info_data.need_source_coin2_count)
  popup:set_texts(show_text, UIUtil.get_text_by_id("Common_Action_Confirm_OK"), UIUtil.get_text_by_id("Common_No"), UIUtil.get_text_by_id("Gacha_T0_Confirm_Title"))
  popup:set_callbacks(function()
    self._draw_progress_type = self._cur_draw_type
    local args = {
      info_data.target_coin_id,
      info_data.need_target_coin_count,
      info_data.source_coin2_id
    }
    gacha_module:request_coin_exchange(args)
  end)
  popup:show()
end

function M:_show_convert_coin_popup(info_data)
  local coin2_path = item_module:get_item_icon(info_data.source_coin2_id)
  local popup = UIUtil.get_confirm_popup()
  local show_text = UIUtil.get_text_by_id("Gacha_T0_Confirm_Content_01", info_data.need_target_coin_count, info_data.target_coin_name, coin2_path, info_data.need_source_coin2_count, info_data.need_source_coin1_count)
  popup:set_texts(show_text, UIUtil.get_text_by_id("Gacha_T0_Confirm_Yes"), UIUtil.get_text_by_id("Gacha_T0_Confirm_No"), UIUtil.get_text_by_id("Gacha_T0_Confirm_Title"))
  popup:set_currency_type(info_data.target_coin_id, info_data.source_coin2_id, info_data.source_coin1_id)
  popup:set_callbacks(function()
    self._draw_progress_type = self._cur_draw_type
    local args = {
      info_data.source_coin2_id,
      info_data.lack_source_coin2_count,
      info_data.source_coin1_id,
      info_data.target_coin_id,
      info_data.need_target_coin_count,
      info_data.source_coin2_id
    }
    gacha_module:request_coin_exchange(args)
  end)
  popup:show()
end

function M:_show_recharge_popup(info_data)
  if curio_emporium_module:try_block_recharge_with_tip(item_module:get_coin_lack_tip(info_data.source_coin1_id)) then
    return
  end
  local coin2_path = item_module:get_item_icon(info_data.source_coin2_id)
  local show_text = UIUtil.get_text_by_id("Gacha_T0_Confirm_Content_04", info_data.need_target_coin_count, info_data.target_coin_name, coin2_path, info_data.need_source_coin2_count, info_data.has_source_coin1_count, info_data.lack_source_coin1_count)
  UIManagerInstance:open("UI/ConfirmView/CommonRechargePromptDialog", {
    title = UIUtil.get_text_by_id("CommonRechargePromptDialog_Title"),
    info = show_text,
    confirm_text = UIUtil.get_text_by_id("Gacha_T0_Confirm_To_TopUp"),
    lack_amount = info_data.lack_source_coin1_count,
    coin_ids = {
      info_data.target_coin_id,
      info_data.source_coin2_id,
      info_data.source_coin1_id
    },
    confirm_callback = function()
      curio_emporium_module:open_curio_emporium_page(curio_emporium_module.entrance_tag_type.top_up_mall)
    end
  })
end

function M:_on_create_extend()
end

function M:_refresh_extend()
end

function M:on_exchange_click()
  gacha_module:open_exchange_page()
end

return M
