gacha_module = gacha_module or {}
local table_insert = table.insert

function gacha_module:add_event()
  gacha_module:remove_event()
  self._events = {}
  self._events[EventID.GachaDrawResult] = pack(self, self.on_gacha_draw_result)
  self._events[EventID.GachaPoolNotInTime] = pack(self, self.on_gacha_pool_not_in_time)
  self._events[EventID.GachaExchangeResult] = pack(self, self.on_gacha_exchange_result)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function gacha_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function gacha_module:on_gacha_draw_result(draw_rsp)
  self:set_is_in_draw_show(false)
  if draw_rsp == nil then
    self:set_is_request_draw(false)
    return
  end
  self:parse_gacha_draw_result(draw_rsp)
  self:start_draw_show_progress()
  self:calc_accum_reward_red(draw_rsp.GachaId)
end

function gacha_module:on_gacha_exchange_result(exchange_rsp)
  self:set_is_in_draw_show(false)
  self:set_is_request_draw(false)
  lua_event_module:send_event(lua_event_module.event_type.on_gacha_exchange_result, exchange_rsp)
end

function gacha_module:request_query()
  CsGachaModuleUtil.RequestQuery()
end

function gacha_module:request_query_by_entrance()
  if self:get_is_query_by_entrance() then
    return
  end
  self:set_is_query_by_entrance(true)
  CsGachaModuleUtil.RequestQuery()
end

function gacha_module:request_draw(gacha_id, is_ten_pull, slot_index)
  if self:is_request_draw() then
    return
  end
  self:set_is_request_draw(true)
  self:set_is_in_draw_show(true)
  CsGachaModuleUtil.RequestDraw(gacha_id, is_ten_pull, slot_index or 0)
end

function gacha_module:request_exchange(gacha_id, exchange_index, count, price)
  if self:is_request_draw() then
    return
  end
  self:set_is_request_draw(true)
  self:set_is_in_draw_show(true)
  CsGachaModuleUtil.RequestExchange(gacha_id, exchange_index, count or 1, price or 0)
end

function gacha_module:request_detail_url()
  CsGachaModuleUtil.RequestDetailUrl()
end

function gacha_module:request_history_url(gacha_pool_id, cursor_id)
  CsGachaModuleUtil.RequestHistory(gacha_pool_id, cursor_id or "")
end

function gacha_module:request_coin_exchange(args)
  CsGachaModuleUtil.RequestCoinExchange(args)
end

function gacha_module:request_gacha_accum_reward_claim(gacha_pool_id, index)
  CsGachaModuleUtil.RequestGachaAccumRewardClaim(gacha_pool_id, index)
end

function gacha_module:is_unlocked()
  return true
end

function gacha_module:notify_codex_unlock_hud(item_id)
  if item_id == nil or item_id <= 0 then
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.gacha_show_codex_unlock_hud, item_id)
end

function gacha_module:start_draw_show_progress()
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  if last_draw_rsp_lua == nil then
    return
  end
  local gacha_id = last_draw_rsp_lua.gacha_id
  local activity_cfg = self:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local is_skip_anim = self:is_skip_anim(gacha_id)
  local is_t0 = activity_cfg.tab == GachaConst.tab.t0
  local is_cloth = activity_cfg.subtab == GachaConst.sub_tab.cloth
  local is_t1_no_replace = activity_cfg.tab == GachaConst.tab.t1_no_replace
  if is_t0 then
    self:_sort_drawn_item_infos()
    self:set_is_in_draw_show(true)
    
    local function cutscene_finish_callback()
      if not is_skip_anim then
        gacha_module:show_draw_transition_cover_background()
      end
      local is_show_new_obtain, new_obtain_items = self:get_new_obtain_info_drawn(activity_cfg.gachapoolid)
      local cur_new_obtain_data
      if is_show_new_obtain then
        cur_new_obtain_data = {
          gacha_id = gacha_id,
          item_ids = new_obtain_items,
          is_exchange = false,
          is_all_collected = last_draw_rsp_lua.is_all_collected
        }
      end
      gacha_module:open_performance_controller_page({
        gacha_id = gacha_id,
        performance_type = is_show_new_obtain and GachaConst.performance_type.both or GachaConst.performance_type.draw_result,
        new_obtain_data = cur_new_obtain_data
      })
    end
    
    if is_skip_anim then
      cutscene_finish_callback()
    else
      gacha_module:show_draw_transition_cover()
      local is_ten = last_draw_rsp_lua.result_infos and #last_draw_rsp_lua.result_infos > 1 or false
      self:_play_draw_cutscene(is_cloth, is_ten, cutscene_finish_callback)
    end
  elseif is_t1_no_replace then
    gacha_module:open_draw_show_t1()
  else
    gacha_module:open_process_t1_page(is_cloth)
  end
end

function gacha_module:_play_draw_cutscene(is_cloth, is_ten, cutscene_finish_callback)
  local ids = GachaConst.draw_cutscene_id
  local cutscene_id = is_cloth and (is_ten and ids.cloth_ten or ids.cloth_single) or is_ten and ids.furniture_ten or ids.furniture_single
  if not is_ten then
    local color = gacha_module:_resolve_single_draw_cutscene_color()
    CsUIUtil.PlayGachaDrawTimeLine(cutscene_id, color, color, false, cutscene_finish_callback, nil, nil)
    return
  end
  local colors = gacha_module:_resolve_ten_draw_cutscene_colors()
  CsUIUtil.PlayGachaTenDrawTimeLine(cutscene_id, colors, cutscene_finish_callback, nil, nil)
end

function gacha_module:_item_rank_to_cutscene_color(rank)
  rank = rank or 0
  if 3 < rank then
    rank = 3
  elseif 0 < rank then
    rank = rank - 1
  end
  return rank
end

function gacha_module:_resolve_single_draw_cutscene_color()
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  if last_draw_rsp_lua == nil or last_draw_rsp_lua.result_infos == nil or #last_draw_rsp_lua.result_infos == 0 then
    return 2
  end
  local item_id = last_draw_rsp_lua.result_infos[1].ItemId or 0
  local rank = item_module:get_item_quality_by_id(item_id) or 0
  return gacha_module:_item_rank_to_cutscene_color(rank)
end

function gacha_module:_resolve_ten_draw_cutscene_colors()
  local colors = {}
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  local result_infos = last_draw_rsp_lua and last_draw_rsp_lua.result_infos or nil
  for i = 1, 10 do
    local color = 0
    if result_infos ~= nil and result_infos[i] ~= nil then
      local item_id = result_infos[i].ItemId or 0
      local rank = item_module:get_item_quality_by_id(item_id) or 0
      color = gacha_module:_item_rank_to_cutscene_color(rank)
    end
    colors[i] = color
  end
  return colors
end

function gacha_module:_sort_drawn_item_infos()
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  if last_draw_rsp_lua == nil then
    return
  end
  local item_2_rank = {}
  local result_infos = last_draw_rsp_lua.result_infos
  for i = 1, #result_infos do
    local result_info = result_infos[i]
    local item_id = result_info.ItemId or 0
    item_2_rank[item_id] = item_module:get_item_quality_by_id(item_id) or 0
  end
  table.sort(result_infos, function(a, b)
    if a.IsDuplicate ~= b.IsDuplicate then
      return not a.IsDuplicate
    end
    local rank_a = item_2_rank[a.ItemId] or 0
    local rank_b = item_2_rank[b.ItemId] or 0
    if rank_a ~= rank_b then
      return rank_a > rank_b
    end
    return a.ItemId < b.ItemId
  end)
  last_draw_rsp_lua.result_infos = result_infos
  gacha_module:set_last_draw_rsp_lua(last_draw_rsp_lua)
end

function gacha_module:parse_gacha_draw_result(draw_rsp)
  if draw_rsp == nil then
    return nil
  end
  local last_draw_rsp_lua = {
    gacha_id = draw_rsp.GachaId,
    is_all_collected = draw_rsp.IsAllCollected
  }
  local result_infos = list_to_table(draw_rsp.DrawResultList)
  local extra_unlock_infos = list_to_table(draw_rsp.ExtraUnlockList)
  last_draw_rsp_lua.result_infos = result_infos
  last_draw_rsp_lua.extra_unlock_infos = extra_unlock_infos
  gacha_module:set_last_draw_rsp_lua(last_draw_rsp_lua)
end

function gacha_module:get_new_obtain_info_drawn(pool_id)
  if self._last_draw_rsp_lua == nil then
    return false, nil
  end
  local result_infos = self._last_draw_rsp_lua.result_infos
  local new_obtain_items = {}
  for i = 1, #result_infos do
    if not result_infos[i].IsDuplicate and self:is_new_item_show_tag(pool_id, result_infos[i].ItemId) then
      table_insert(new_obtain_items, result_infos[i].ItemId)
    end
  end
  return 0 < #new_obtain_items, new_obtain_items
end

function gacha_module:on_gacha_pool_not_in_time()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Gacha_Common_Pool_Forbidden"), UIUtil.get_text_by_id("Common_Yes"))
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_callbacks(function()
    gacha_module:set_cur_gacha_id(0)
    gacha_module:request_query()
    local sub_pages = {
      GachaConst.page_path.exchange,
      GachaConst.page_path.cloth_pool_show,
      GachaConst.page_path.description,
      GachaConst.page_path.accum_reward
    }
    for i = 1, #sub_pages do
      local win = UIManagerInstance:is_show(sub_pages[i])
      if win ~= nil then
        win:close_self()
      end
    end
  end)
  popup:show()
end

function gacha_module:is_pool_in_open_time(start_time, end_time)
  local now = TimeUtil.ServerUtcTimeSeconds
  if 0 < start_time and start_time > now then
    return false
  end
  if 0 < end_time and end_time <= now then
    return false
  end
  return true
end

function gacha_module:format_remain_time(remain_seconds)
  remain_seconds = remain_seconds or 0
  if remain_seconds <= 0 then
    return ""
  end
  local day = math.floor(remain_seconds / 86400)
  local hour = math.floor(remain_seconds % 86400 / 3600)
  local minute = math.floor(remain_seconds % 3600 / 60)
  if 1 <= day then
    return UIUtil.get_text_by_id("Gacha_Common_CountDown_01", day, hour)
  elseif 1 <= hour then
    return UIUtil.get_text_by_id("Gacha_Common_CountDown_02", hour)
  else
    if minute < 1 then
      minute = 1
    end
    return UIUtil.get_text_by_id("Gacha_Common_CountDown_03", minute)
  end
end

function gacha_module:calc_draw_cost(activity_cfg, draw_count, next_draw_index)
  if activity_cfg == nil then
    return nil, 0, 0
  end
  local price_cfg, total
  if activity_cfg.pricestrategyid == GachaConst.price_strategy.no_replace then
    price_cfg = self:get_price(activity_cfg.pricestrategyid, next_draw_index or 1)
    total = price_cfg and price_cfg.price or 0
  else
    price_cfg = self:get_price(activity_cfg.pricestrategyid, GachaConst.replace_price_strategy_index)
    local single_cost = price_cfg and price_cfg.price or 0
    total = single_cost * draw_count
  end
  local cost_item_id = price_cfg and price_cfg.cointype or 0
  return price_cfg, total, cost_item_id
end

function gacha_module:get_owned_coin_count(coin_type)
  if coin_type == nil or coin_type == 0 then
    return 0
  end
  return back_bag_module:get_coin_or_item_num(coin_type) or 0
end

function gacha_module:is_coin_enough(coin_type, need)
  return self:get_owned_coin_count(coin_type) >= (need or 0)
end

function gacha_module:is_draw_result_to_coin(draw_result_info)
  return draw_result_info ~= nil and draw_result_info.IsDuplicate == true and 0 < (draw_result_info.CoinGained or 0)
end

function gacha_module:is_t0_cloth_pool(activity_cfg)
  return activity_cfg ~= nil and activity_cfg.tab == GachaConst.tab.t0 and activity_cfg.subtab == GachaConst.sub_tab.cloth
end

function gacha_module:is_cloth_no_replace_pool(activity_cfg)
  return activity_cfg ~= nil and activity_cfg.tab == GachaConst.tab.t1_no_replace and activity_cfg.subtab == GachaConst.sub_tab.cloth
end

function gacha_module:is_cloth_pool(activity_cfg)
  return activity_cfg ~= nil and activity_cfg.subtab == GachaConst.sub_tab.cloth
end

function gacha_module:get_cloth_core_item(gacha_id)
  local activity_cfg = self:get_activity_cfg(gacha_id)
  if not self:is_cloth_no_replace_pool(activity_cfg) then
    return nil
  end
  local pool_list = self:get_pool_cfg_list(activity_cfg.gachapoolid)
  for i = 1, #pool_list do
    if pool_list[i].itemtype == GachaConst.item_type.core then
      return pool_list[i]
    end
  end
  return nil
end

function gacha_module:get_item_exchanged_count(gacha_id, item_id, exchanged_map)
  local activity_cfg = self:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return 0
  end
  exchanged_map = exchanged_map or self:get_pool_exchanged_map(gacha_id)
  local pool_list = self:get_exchange_shop_list(activity_cfg.gachapoolid)
  for _, pool_cfg in ipairs(pool_list) do
    if pool_cfg.itemid == item_id then
      return (exchanged_map[pool_cfg.index] or 0) * (pool_cfg.unitcount or 1)
    end
  end
  return 0
end

function gacha_module:build_owned_data_snapshot(gacha_id)
  local pool_info = self:get_pool_info(gacha_id)
  return self:get_pool_drawn_map(gacha_id, pool_info), self:get_pool_exchanged_map(gacha_id, pool_info)
end

function gacha_module:get_pool_drawn_map(gacha_id, pool_info)
  local drawn_map = {}
  pool_info = pool_info or self:get_pool_info(gacha_id)
  if pool_info ~= nil and not is_null(pool_info.DrawnItemIdList) then
    local drawn = list_to_table(pool_info.DrawnItemIdList)
    for i = 1, #drawn do
      drawn_map[drawn[i]] = true
    end
  end
  return drawn_map
end

function gacha_module:get_pool_exchanged_map(gacha_id, pool_info)
  local exchanged_map = {}
  pool_info = pool_info or self:get_pool_info(gacha_id)
  if pool_info ~= nil and not is_null(pool_info.ExchangeCountMap) then
    exchanged_map = dic_to_table(pool_info.ExchangeCountMap)
  end
  return exchanged_map
end

function gacha_module:is_item_owned(gacha_id, item_id, drawn_map, exchanged_map)
  if item_id == nil or item_id <= 0 then
    return false
  end
  drawn_map = drawn_map or self:get_pool_drawn_map(gacha_id)
  if drawn_map[item_id] then
    return true
  end
  return 0 < self:get_item_exchanged_count(gacha_id, item_id, exchanged_map)
end

function gacha_module:get_item_owned_count(gacha_id, item_id, drawn_map, exchanged_map)
  if item_id == nil or item_id <= 0 then
    return 0
  end
  local owned_count = 0
  drawn_map = drawn_map or self:get_pool_drawn_map(gacha_id)
  if drawn_map[item_id] then
    owned_count = owned_count + 1
  end
  owned_count = owned_count + self:get_item_exchanged_count(gacha_id, item_id, exchanged_map)
  return owned_count
end

function gacha_module:_count_owned_total(gacha_id, list, predicate, drawn_map, exchanged_map)
  drawn_map = drawn_map or self:get_pool_drawn_map(gacha_id)
  exchanged_map = exchanged_map or self:get_pool_exchanged_map(gacha_id)
  local total, owned = 0, 0
  for i = 1, #list do
    local cfg = list[i]
    if predicate(cfg) then
      total = total + 1
      if self:is_item_owned(gacha_id, cfg.itemid, drawn_map, exchanged_map) then
        owned = owned + 1
      end
    end
  end
  return owned, total
end

function gacha_module:get_collect_progress(gacha_id, shop_tag, drawn_map, exchanged_map)
  gacha_id = gacha_id or self:get_cur_gacha_id()
  local activity_cfg = self:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return 0, 0
  end
  local is_no_replace_pool = activity_cfg.tab == GachaConst.tab.t1_no_replace
  if is_no_replace_pool then
    local pool_list = self:get_pool_cfg_list(activity_cfg.gachapoolid)
    return self:_count_owned_total(gacha_id, pool_list, function(c)
      return true
    end, drawn_map, exchanged_map)
  else
    local filter_tag = shop_tag
    if filter_tag == nil and self:is_cloth_pool(activity_cfg) then
      filter_tag = GachaConst.shop_category.suit
    end
    local exchange_list = self:get_exchange_shop_list(activity_cfg.gachapoolid)
    return self:_count_owned_total(gacha_id, exchange_list, function(c)
      return filter_tag == nil or filter_tag == -1 or c.shoptag == filter_tag
    end, drawn_map, exchanged_map)
  end
end

function gacha_module:_tab_group_by(list, key_func, group_init, order_sort, item_sort)
  local group_map = {}
  local order = {}
  for i = 1, #list do
    local cfg = list[i]
    if cfg ~= nil then
      local key = key_func(cfg)
      local group = group_map[key]
      if group == nil then
        group = group_init(cfg)
        group.items = {}
        group_map[key] = group
        table_insert(order, key)
      end
      table_insert(group.items, cfg)
    end
  end
  table.sort(order, order_sort)
  local groups = {}
  for i = 1, #order do
    if item_sort then
      table.sort(group_map[order[i]].items, item_sort)
    end
    table_insert(groups, group_map[order[i]])
  end
  return groups, group_map
end

function gacha_module:get_exchange_item_state(gacha_id, shop_cfg, exchanged_count, drawn_map, exchanged_map)
  if shop_cfg == nil then
    return GachaConst.exchange_state.not_owned
  end
  local is_owned = self:is_item_owned(gacha_id, shop_cfg.itemid, drawn_map, exchanged_map)
  if not is_owned then
    return GachaConst.exchange_state.not_owned
  end
  if (shop_cfg.ownedlock or 0) == 1 then
    return GachaConst.exchange_state.owned_not_exchangeable
  end
  if 0 < (shop_cfg.limitcount or 0) and (exchanged_count or 0) >= shop_cfg.limitcount then
    return GachaConst.exchange_state.owned_not_exchangeable
  end
  return GachaConst.exchange_state.owned_exchangeable
end

function gacha_module:get_pool_item_state(gacha_id, pool_cfg, drawn_map, exchanged_map)
  if pool_cfg == nil then
    return GachaConst.exchange_state.not_owned_cloth
  end
  local is_owned = self:is_item_owned(gacha_id, pool_cfg.itemid, drawn_map, exchanged_map)
  if not is_owned then
    return GachaConst.exchange_state.not_owned_cloth
  end
  return GachaConst.exchange_state.owned_cloth
end

function gacha_module:get_collect_progress_by_item_type(gacha_id, pool_id, item_type, drawn_map, exchanged_map)
  local pool_list = self:get_pool_cfg_list(pool_id)
  return self:_count_owned_total(gacha_id, pool_list, function(c)
    return c.itemtype == item_type
  end, drawn_map, exchanged_map)
end

function gacha_module:get_shop_price_info(gacha_id, shop_cfg, drawn_map, exchanged_map)
  if shop_cfg == nil then
    return 0, 0, false
  end
  if (shop_cfg.ownedlock or 0) == 0 and 0 < (shop_cfg.saleprice or 0) and self:is_item_owned(gacha_id, shop_cfg.itemid, drawn_map, exchanged_map) then
    return shop_cfg.price, shop_cfg.saleprice, true
  end
  return shop_cfg.price, shop_cfg.price, false
end

function gacha_module:get_shop_price_info_with_saleprice(shop_cfg)
  if shop_cfg == nil then
    return 0, 0
  end
  if (shop_cfg.ownedlock or 0) == 0 and 0 < (shop_cfg.saleprice or 0) then
    return shop_cfg.price, shop_cfg.saleprice
  end
  return shop_cfg.price, 0
end

function gacha_module:get_exchange_tab_groups(gacha_pool_id)
  local shop_list = self:get_exchange_shop_list(gacha_pool_id)
  return self:_tab_group_by(shop_list, function(c)
    return c.shoptag or 0
  end, function(c)
    return {
      pool_id = gacha_pool_id,
      pool_index = c.index
    }
  end, nil, function(a, b)
    return a.index < b.index
  end)
end

function gacha_module:get_cloth_pool_tab_groups(gacha_pool_id)
  local pool_list = self:get_pool_cfg_list(gacha_pool_id)
  return self:_tab_group_by(pool_list, function(c)
    return c.itemtype
  end, function(c)
    return {
      pool_id = gacha_pool_id,
      pool_index = c.index
    }
  end, function(a, b)
    if a ~= b then
      return a == GachaConst.item_type.core
    end
    return tostring(a) < tostring(b)
  end, function(a, b)
    return a.index < b.index
  end)
end

function gacha_module:get_model_suit_info(gacha_id, item_id, is_all)
  local result = {
    cloth_ids = {},
    style_color_list = {},
    other_items = {}
  }
  local activity_cfg = self:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return result
  end
  local suit_ids = {}
  if is_all then
    if activity_cfg.tab == GachaConst.tab.t1_no_replace then
      suit_ids = self:get_pool_suit(activity_cfg.gachapoolid)
    else
      suit_ids = self:get_exchange_suit(activity_cfg.gachapoolid)
    end
  end
  table_insert(suit_ids, {config_id = item_id, num = 1})
  result = curio_emporium_module:split_suit_gift_items_handle(result, suit_ids)
  return result
end

function gacha_module:get_pool_suit(pool_id)
  local suit_ids = {}
  local pool_list = self:get_pool_cfg_list(pool_id)
  for _, pool_cfg in ipairs(pool_list) do
    if pool_cfg.guaranteetag and pool_cfg.guaranteetag == 1 then
      table_insert(suit_ids, {
        config_id = pool_cfg.itemid,
        num = 1
      })
    end
  end
  return suit_ids
end

function gacha_module:get_exchange_suit(pool_id)
  local suit_ids = {}
  local exchange_list = self:get_exchange_shop_list(pool_id)
  for _, exchange_cfg in ipairs(exchange_list) do
    if exchange_cfg.shoptag == GachaConst.shop_category.suit then
      table_insert(suit_ids, {
        config_id = exchange_cfg.itemid,
        num = 1
      })
    end
  end
  return suit_ids
end

function gacha_module:get_can_exchangeable_infos(gacha_id)
  local cfg = self:get_activity_cfg(gacha_id)
  if cfg == nil then
    return nil, 0
  end
  local convert_coin_count = self:get_owned_coin_count(cfg.exchangeshopcoinid or 0)
  if convert_coin_count <= 0 then
    return nil, 0
  end
  local drawn_map, exchanged_map = self:build_owned_data_snapshot(gacha_id)
  local exchange_list = self:get_exchange_shop_list(cfg.gachapoolid)
  local can_exchangeable_items = {}
  for _, exchange_cfg in ipairs(exchange_list) do
    local exchanged = self:get_item_owned_count(gacha_id, exchange_cfg.itemid, drawn_map, exchanged_map)
    local exchange_state = gacha_module:get_exchange_item_state(gacha_id, exchange_cfg, exchanged, drawn_map, exchanged_map)
    local _, sale_price, _ = gacha_module:get_shop_price_info(gacha_id, exchange_cfg, drawn_map, exchanged_map)
    if exchange_state ~= GachaConst.exchange_state.owned_not_exchangeable and convert_coin_count >= sale_price then
      table_insert(can_exchangeable_items, {
        index = exchange_cfg.index,
        item_id = exchange_cfg.itemid,
        is_owned = 0 < exchanged,
        sale_price = sale_price
      })
    end
  end
  table.sort(can_exchangeable_items, function(a, b)
    if a.is_owned ~= b.is_owned then
      return not a.is_owned
    end
    if a.sale_price ~= b.sale_price then
      return a.sale_price > b.sale_price
    end
    return a.index < b.index
  end)
  return can_exchangeable_items, #can_exchangeable_items
end

function gacha_module:is_pool_new(gacha_id)
  if gacha_id == nil or gacha_id <= 0 then
    return false
  end
  return not red_point_module:is_recorded_with_id(red_point_module.red_point_type.gacha_new_pool, gacha_id)
end

function gacha_module:mark_pool_seen(gacha_id)
  if gacha_id == nil or gacha_id <= 0 then
    return
  end
  if not red_point_module:is_recorded_with_id(red_point_module.red_point_type.gacha_new_pool, gacha_id) then
    red_point_module:record_with_id(red_point_module.red_point_type.gacha_new_pool, gacha_id)
  end
end

function gacha_module:get_entrance_red_point_type()
  if not self:is_unlocked() then
    return RedPointType.None
  end
  local pool_info_map = self:get_pool_info_map()
  if pool_info_map == nil then
    return RedPointType.None
  end
  for _, pool_info in pairs(pool_info_map) do
    if self:is_pool_new(pool_info.GachaId) and self:is_pool_in_open_time(pool_info.StartTime, pool_info.EndTime) then
      return RedPointType.NewRp
    end
  end
  for _, pool_info in pairs(pool_info_map) do
    if self:is_pool_in_open_time(pool_info.StartTime, pool_info.EndTime) and self:has_accum_reward_red(pool_info.GachaId) then
      return RedPointType.GiftRP
    end
  end
  return RedPointType.None
end

function gacha_module:has_accum_reward_red(gacha_id)
  local activity_cfg = self:get_activity_cfg(gacha_id)
  local pool_id = activity_cfg and activity_cfg.gachapoolid or 0
  local has_reward = self:get_accum_reward_red_cache(pool_id)
  if has_reward == nil then
    has_reward = self:calc_accum_reward_red(gacha_id)
  end
  return has_reward == true
end

function gacha_module:get_accum_reward_red_point_type(gacha_id)
  return self:has_accum_reward_red(gacha_id) and RedPointType.GiftRP or RedPointType.None
end

function gacha_module:calc_accum_reward_red(gacha_id)
  local activity_cfg = self:get_activity_cfg(gacha_id)
  local pool_id = activity_cfg and activity_cfg.gachapoolid or 0
  local has_reward = false
  if 0 < pool_id and activity_cfg.gachaaccumulatedtag and activity_cfg.gachaaccumulatedtag == 1 then
    has_reward = self:_has_claimable_accum_reward(gacha_id, pool_id)
  end
  self:set_accum_reward_red_cache(pool_id, has_reward)
  return has_reward
end

function gacha_module:_has_claimable_accum_reward(gacha_id, pool_id)
  local reward_list = self:get_accum_reward_list(pool_id)
  if reward_list == nil or #reward_list == 0 then
    return false
  end
  local total_draw = self:get_total_draw_count(gacha_id) or 0
  if total_draw <= 0 then
    return false
  end
  local claimed_set = self:get_claimed_accum_reward_set(gacha_id)
  for i = 1, #reward_list do
    local cfg = reward_list[i]
    if not claimed_set[cfg.index] and total_draw >= cfg.times then
      return true
    end
  end
  return false
end

function gacha_module:get_tab_groups()
  local pool_info_map = self:get_pool_info_map()
  if pool_info_map == nil then
    return {}
  end
  local gacha_id_list = {}
  for _, pool_info in pairs(pool_info_map) do
    if self:is_pool_in_open_time(pool_info.StartTime, pool_info.EndTime) then
      table_insert(gacha_id_list, pool_info.GachaId)
    end
  end
  local group_map = {}
  local type_order = {}
  for _, gid in pairs(gacha_id_list) do
    local cfg = self:get_activity_cfg(gid)
    if cfg ~= nil then
      local gtab = cfg.tab or 0
      local group = group_map[gtab]
      if group == nil then
        group = {
          gacha_id = gid,
          tab = gtab,
          items = {}
        }
        group_map[gtab] = group
        table_insert(type_order, gtab)
      end
      table_insert(group.items, cfg)
    end
  end
  table.sort(type_order)
  local groups = {}
  for _, gtab in ipairs(type_order) do
    local group = group_map[gtab]
    table.sort(group.items, function(a, b)
      return a.gachaid < b.gachaid
    end)
    group.title = self:get_tab_title(gtab)
    table_insert(groups, group)
  end
  return groups
end

function gacha_module:get_tab_title(tab)
  if tab == GachaConst.tab.t0 then
    return "Gacha_T0_MainScreen_Title_02"
  elseif tab == GachaConst.tab.t1_no_replace then
    return "Gacha_T0_MainScreen_Title_03"
  elseif tab == GachaConst.tab.t1_replace then
    return "Gacha_T0_MainScreen_Title_04"
  end
  return ""
end

function gacha_module:get_collect_desc_txtid(sub_tab)
  if sub_tab == GachaConst.sub_tab.furniture then
    return "Gacha_T0_MainScreen_Collection_Furniture"
  end
  return "Gacha_T0_MainScreen_SuitColloection"
end

function gacha_module:wrap_style(txt, style_name)
  return string.format("<style=%s>%s</style>", tostring(style_name), tostring(txt))
end

return gacha_module
