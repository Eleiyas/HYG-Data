local M = G.Class("GeLianFoodMarketMainPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local market_page_service_cls = require("UI/GeLianMarket/GeLianMarketPageService")
local gelian_market_view_model = gelian_market_module.view_model
local sell_adapter = gelian_market_module.sell_adapter
local up_helper = gelian_market_module.up_helper
local sell_confirm_dialog_cls = "UI/ConfirmView/ItemConfirmColumnsDialog"
local left_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketLeftPanel"
local right_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketRightPanel"
local LimitState = {Normal = 0, Limited = 1}
local FriendState = {Self = 0, Friend = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GeLianFoodMarket/GeLianFoodMarketMainPage"
  self.config.type = EUIType.Page
  self.is_show_coin = false
  self.bag_show_type = back_bag_module.bag_show_type.gelian_market
  self.cur_item_select_type = back_bag_module.packet_item_select_type.num_multi_selected
  self._page_service = nil
  self._is_close_requested = false
  self._pending_bag_show = nil
  self._page_view_data = nil
  self._quote_cache = nil
  self._all_price = 0
  self._is_sell_succeed = false
  self._is_waiting_sell_result = false
  self._last_sell_count = 0
  self._pending_sell_gold = 0
  self._all_selected_protected_ids = {}
end

function M:on_create()
  base.on_create(self)
  self._page_service = G.New(market_page_service_cls)
  local back_callback = pack(self, M._on_btn_bg)
  self:bind_callback(self._btn_close, pack(self, M._on_close_requested))
  self:bind_callback(self._btn_bg, back_callback)
  self:bind_callback(self._btn_back, back_callback)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_action_back))
  self._top_bar_panel = self:add_panel("UI/GeLianMarket/Panel/GeLianMarketTopBarPanel", self._trans_top_bar, {
    help_callback = pack(self, M._on_help_requested)
  })
  self._right_panel = self:add_panel(right_panel_cls, self._trans_right_ui, {
    page_service = self._page_service,
    sell_host = {
      request_sell = pack(self, M._on_sell_requested)
    }
  })
  self._left_panel = self:add_panel(left_panel_cls, self._trans_left_ui, {
    page_service = self._page_service,
    host = {
      show_bag = pack(self, M._show_bag),
      hide_bag = pack(self, M._hide_bag)
    },
    sell_host = {
      request_sell = pack(self, M._on_sell_requested)
    }
  })
end

function M:on_enable()
  self._is_close_requested = false
  self._is_sell_succeed = false
  self._is_waiting_sell_result = false
  self._last_sell_count = self:_get_current_market_sell_count()
  self._pending_sell_gold = 0
  base.on_enable(self)
  self._state_group_friend:SetState(self:_is_self_market() and FriendState.Self or FriendState.Friend)
  self._page_service:enter_market_overview()
  CsPacketModuleUtil.StartCacheChangeItemTip()
end

function M:on_disable()
  if self._page_service ~= nil then
    self._page_service:cancel_pending_requests()
  end
  self:_cancel_pending_bag_show()
  CsPacketModuleUtil.StopCacheChangeItemTip()
  CsPacketModuleUtil.ClearChangeItemCache()
  base.on_disable(self)
end

function M:update(delta_time)
  base.update(self, delta_time)
  if not self.is_active then
    return
  end
  self:_try_flush_pending_bag_show()
end

function M:close_self()
  if self:_is_common_bag_panel_ready() then
    self.common_bag_panel:close_self()
  end
  G.UIWindow.close_self(self)
end

function M:on_destroy()
  self:_cancel_pending_bag_show()
  if self._page_service ~= nil then
    self._page_service:dispose()
    self._page_service = nil
  end
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnWorldCropOnShelfNotify, function()
    self:_on_market_data_changed()
  end)
  self:add_evt_listener(EventID.LuaGeLianMarketSellCountUpdate, function()
    self:_on_sell_count_update()
  end)
  self:add_evt_listener(EventID.OnGeLianFoodMarketMessageNotify, function()
    self:_on_market_data_changed()
  end)
  self:add_lua_listener(lua_event_module.event_type.on_gelian_market_leave_message_success, function()
    self:_on_market_data_changed()
  end)
end

function M:refresh_data()
  back_bag_module:init_tracking_task_filter_lists()
  self:_refresh_market_data()
  if self:_is_common_bag_panel_ready() then
    self:refresh_common_bag_panel_data()
  end
end

function M:_on_btn_bg()
  self._page_service:enter_market_overview()
end

function M:_refresh_market_data()
  local view_data = self:_build_page_view_data()
  self._page_view_data = view_data
  self._quote_cache = {}
  if self._page_service ~= nil then
    self._page_service:refresh(view_data)
  end
  self:_refresh_sell_bar()
end

function M:_build_page_view_data()
  return gelian_market_view_model.build_page_view_data(self:_is_self_market())
end

function M:_on_market_data_changed()
  if not self.is_active then
    return
  end
  self:_refresh_market_data()
end

function M:refresh_ui()
  if self:_is_stack_num_panel_ready() then
    self._stack_num_panel:change_state(EUIState.Hide)
  end
  if not self:_is_common_bag_panel_ready() then
    return
  end
  local is_selling = self._page_service ~= nil and self._page_service:get_mode() == market_page_service_cls.Mode.Selling
  self.common_bag_panel:change_state(is_selling and EUIState.Show or EUIState.Hide)
end

function M:refresh_common_bag_panel_data()
  if self:_is_common_bag_panel_ready() then
    base.refresh_common_bag_panel_data(self)
  end
end

function M:clear_all_select_item_data()
  if self:_is_common_bag_panel_ready() then
    base.clear_all_select_item_data(self)
  end
end

function M:get_lock_state(item)
  if base.get_lock_state(self, item) then
    return true
  end
  if not item_module:is_fruits_crop(item.ConFigID, item.idCfg) then
    return true
  end
  return not sell_adapter.is_item_sellable(item, self:_is_self_market(), self:_get_quote_cache())
end

function M:get_max_select_item_num(server_data, cur_num)
  local cur = cur_num or 0
  local tag_limit, total_limit = self:get_cur_select_sell_limit(server_data.ConfigId, false)
  tag_limit = tag_limit + cur
  total_limit = total_limit + cur
  if tag_limit <= 0 then
    UIUtil.show_tips_by_text_id("CropTrading_Limit_01")
  end
  if total_limit <= 0 then
    UIUtil.show_tips_by_text_id("CropTrading_Limit_02")
  end
  return math.min(server_data.Count, tag_limit, total_limit)
end

function M:should_show_zero_num_item_detail(server_data)
  local tag_limit = self:get_cur_select_sell_limit(server_data.ConfigId, false)
  return tag_limit <= 0
end

function M:get_cur_select_sell_limit(item_config_id, exclude_select)
  local quote = self:_get_market_quote_by_config_id(item_config_id)
  if not (quote ~= nil and quote.is_sellable) or not string.is_valid(quote.matched_tag) then
    return 0, 0
  end
  local select_tag = quote.matched_tag
  local is_self = self:_is_self_market()
  local tag_limit = CsGeLianMarketModuleUtil.GetSellLimitByScope(select_tag, is_self)
  local total_limit = CsGeLianMarketModuleUtil.GetTotalSellLimitByScope(is_self)
  local cur_guid = self:_get_cur_select_item_guid_safe()
  for _, item_data in pairs(self:_get_all_select_item_data_safe()) do
    if not exclude_select or item_data.server_data.StackGuid ~= cur_guid then
      local other_quote = self:_get_market_quote_by_config_id(item_data.server_data.ConfigId)
      if other_quote ~= nil and other_quote.is_sellable and other_quote.matched_tag == select_tag then
        tag_limit = tag_limit - item_data.num
      end
      total_limit = total_limit - item_data.num
    end
  end
  return tag_limit, total_limit
end

function M:on_update_bag_item_selected_num(server_data)
  base.on_update_bag_item_selected_num(self, server_data)
  self:_refresh_sell_bar(server_data)
  if is_null(server_data) then
    return
  end
  if not self:_is_stack_num_panel_ready() then
    return
  end
  if self:_get_cur_select_item_guid_safe() <= 0 then
    self._stack_num_panel:change_state(EUIState.Hide)
    return
  end
  if server_data.StackGuid ~= self:_get_cur_select_item_guid_safe() then
    return
  end
  local cur_num = self:get_cur_select_item_num()
  if cur_num <= 0 then
    self._stack_num_panel:change_state(EUIState.Hide)
    return
  end
  local quote = sell_adapter.get_item_quote(server_data, self:_is_self_market(), self:_get_quote_cache())
  if quote == nil or not quote.is_sellable then
    self._stack_num_panel:change_state(EUIState.Hide)
    return
  end
  local tag_limit, total_limit = self:get_cur_select_sell_limit(server_data.ConfigId, true)
  if 0 >= math.min(tag_limit, total_limit) then
    self._stack_num_panel:change_state(EUIState.Hide)
    return
  end
  self._stack_num_panel:change_state(EUIState.Show)
  self._stack_num_panel:show({
    cur_num = cur_num,
    max_num = math.min(server_data.Count, tag_limit, total_limit),
    server_data = server_data,
    price = quote.final_price,
    num_change_callback = function(new_num)
      self:refresh_cur_select_item_num(new_num)
      self:_refresh_sell_bar()
    end
  })
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  if is_null(select_item_data) and self:_is_stack_num_panel_ready() then
    self._stack_num_panel:change_state(EUIState.Hide)
  end
end

function M:refresh_detail_panel(select_item_data)
  if self.item_detail_panel == nil then
    return
  end
  if not is_null(select_item_data) and not is_null(select_item_data.server_data) then
    if not self:_is_loader_panel_ready(self.item_detail_panel) then
      return
    end
    local trend_value = sell_adapter.calc_display_trend_value(select_item_data.trend_value, select_item_data.server_data)
    self.item_detail_panel:change_state(EUIState.Show)
    self.item_detail_panel:show(select_item_data.server_data, {trend_value = trend_value, is_gelian_market = true})
  else
    self.item_detail_panel:change_state(EUIState.Hide)
  end
end

function M:_on_sell_requested()
  if self._is_waiting_sell_result then
    return
  end
  local select_items = self:_get_all_select_item_data_safe()
  if #select_items <= 0 then
    return
  end
  
  local function sell_callback()
    local items = {}
    for _, item_data in pairs(select_items) do
      items[item_data.server_data.StackGuid] = item_data.num
    end
    self._last_sell_count = self:_get_current_market_sell_count()
    self._pending_sell_gold = self._all_price
    self._is_waiting_sell_result = true
    CsPacketModuleUtil.SellMarketReq(items)
    self:clear_all_select_item_data()
    self:set_select_item_index(0)
    if self:_is_stack_num_panel_ready() then
      self._stack_num_panel:change_state(EUIState.Hide)
    end
    self:_refresh_sell_bar()
  end
  
  local title_str = UIUtil.get_text_by_id("Market_Sell_Confirm_Title")
  if #self._all_selected_protected_ids > 0 then
    title_str = UIUtil.get_text_by_id("Bag_SaleNotice_01")
  end
  local flat_items = self:_build_sell_confirm_items(select_items)
  UIManagerInstance:open(sell_confirm_dialog_cls, {
    title_txt = title_str,
    coin_type = back_bag_module.coin_type.gold,
    all_price = self._all_price,
    items = flat_items,
    groups = self:_build_sell_confirm_groups(flat_items),
    left_txt = UIUtil.get_text_by_id("Sell_TransConfirm_Cancle"),
    right_txt = UIUtil.get_text_by_id("Sell_TransConfirm_OK"),
    right_callback = sell_callback,
    is_show_close_btn = true
  })
end

function M:_build_sell_confirm_items(select_items)
  local items = {}
  for i = 1, #select_items do
    local item_data = select_items[i]
    local server_data = item_data and item_data.server_data
    items[i] = {
      config_id = server_data and (server_data.ConfigId or server_data.ConFigID) or 0,
      num = item_data and item_data.num or 0,
      server_data = server_data
    }
  end
  return items
end

function M:_build_sell_confirm_groups(flat_items)
  local groups = up_helper.group_items(flat_items)
  for i = 1, #groups do
    local title_key = groups[i].key == up_helper.GroupKey.SeasonalUp and "Market_Sell_Group_Up" or "Market_Sell_Group_Normal"
    groups[i].title = UIUtil.get_text_by_id(title_key)
    groups[i].price_fluctuate = self:_get_ordinary_crop_price_fluctuate(groups[i])
  end
  return groups
end

function M:_get_ordinary_crop_price_fluctuate(group)
  if group == nil or group.key ~= up_helper.GroupKey.Ordinary then
    return 0
  end
  return sell_adapter.get_ordinary_discount_basis_points() / 100
end

function M:_on_sell_count_update()
  local current_sell_count = self:_get_current_market_sell_count()
  if self._is_waiting_sell_result and current_sell_count > self._last_sell_count then
    self._is_sell_succeed = true
    self._is_waiting_sell_result = false
    self:_show_sell_reward_dialog()
    self:clear_all_select_item_data()
    self:set_select_item_index(0)
    if self:_is_stack_num_panel_ready() then
      self._stack_num_panel:change_state(EUIState.Hide)
    end
  end
  self._last_sell_count = current_sell_count
  self:_on_market_data_changed()
end

function M:_show_sell_reward_dialog()
  if self._pending_sell_gold == nil or self._pending_sell_gold <= 0 then
    return
  end
  common_ui_module:show_reward_dialog(nil, nil, {
    {
      id = back_bag_module.coin_type.gold,
      num = self._pending_sell_gold
    }
  })
  self._pending_sell_gold = 0
end

function M:_get_current_market_sell_count()
  local total = 0
  local is_self = self:_is_self_market()
  local friend_id = player_module:get_scene_owner_uid()
  local sell_data_dict = dic_to_table(CsGeLianMarketModuleUtil.GetAllSellData()) or {}
  for _, sell_data in pairs(sell_data_dict) do
    if is_self then
      total = total + (sell_data.selfSellCount or 0)
    else
      local count_dict = dic_to_table(sell_data and sell_data.friendSellCountDic)
      total = total + (count_dict and count_dict[friend_id] or 0)
    end
  end
  return total
end

function M:_refresh_sell_bar(focused_server_data)
  local select_items = self:_get_all_select_item_data_safe()
  self._all_price = sell_adapter.get_selected_item_total_price(select_items, self:_is_self_market(), self:_get_quote_cache())
  self._all_selected_protected_ids = {}
  local has_tag_at_limit = false
  for _, item_data in pairs(select_items) do
    if item_data.server_data.isProtectedItem then
      table.insert(self._all_selected_protected_ids, item_data.server_data.ConfigId)
    end
    local quote = self:_get_market_quote_by_config_id(item_data.server_data.ConfigId)
    if quote ~= nil and quote.is_sellable and string.is_valid(quote.matched_tag) then
      local tag_limit_remaining = CsGeLianMarketModuleUtil.GetSellLimitByScope(quote.matched_tag, self:_is_self_market())
      has_tag_at_limit = has_tag_at_limit or tag_limit_remaining <= 0
    end
  end
  if not has_tag_at_limit and not is_null(focused_server_data) then
    local focused_quote = sell_adapter.get_item_quote(focused_server_data, self:_is_self_market(), self:_get_quote_cache())
    has_tag_at_limit = focused_quote ~= nil and focused_quote.is_sellable and 0 >= focused_quote.tag_limit_remaining
  end
  local is_limited = has_tag_at_limit
  self._state_group_limited:SetState(is_limited and LimitState.Limited or LimitState.Normal)
  if is_limited and self:_is_stack_num_panel_ready() then
    self._stack_num_panel:change_state(EUIState.Hide)
  end
  if self._page_service ~= nil then
    local left_area = self._page_service:get_port(market_page_service_cls.Port.LeftArea)
    if left_area ~= nil then
      left_area.refresh_sell_bar({
        total_price = self._all_price,
        select_count = #select_items
      })
    end
  end
end

function M:_is_self_market()
  return player_module:get_player_uid() == player_module:get_scene_owner_uid()
end

function M:_get_quote_cache()
  if self._quote_cache == nil then
    self._quote_cache = {}
  end
  return self._quote_cache
end

function M:_get_market_quote_by_config_id(config_id)
  if not config_id or config_id <= 0 then
    return nil
  end
  return sell_adapter.get_item_quote_by_config_id(config_id, self:_is_self_market(), self:_get_quote_cache())
end

function M:_get_all_select_item_data_safe()
  if not self:_is_common_bag_panel_ready() then
    return {}
  end
  return self:get_all_select_item_data() or {}
end

function M:_get_cur_select_item_guid_safe()
  if not self:_is_common_bag_panel_ready() then
    return 0
  end
  return self:get_cur_select_item_guid()
end

function M:_show_bag(payload, complete)
  if self:_is_common_bag_panel_ready() then
    self.common_bag_panel:change_state(EUIState.Show)
    self:refresh_common_bag_panel_data()
    if complete ~= nil then
      complete(true)
    end
    return
  end
  if self._pending_bag_show ~= nil then
    self:_cancel_pending_bag_show()
  end
  self._pending_bag_show = {payload = payload, complete = complete}
end

function M:_hide_bag()
  self:_cancel_pending_bag_show()
  if self:_is_common_bag_panel_ready() then
    self.common_bag_panel:change_state(EUIState.Hide)
  end
end

function M:_try_flush_pending_bag_show()
  if self._pending_bag_show == nil then
    return
  end
  if not self:_is_common_bag_panel_ready() then
    return
  end
  local pending = self._pending_bag_show
  self._pending_bag_show = nil
  self.common_bag_panel:change_state(EUIState.Show)
  self:refresh_common_bag_panel_data()
  if pending.complete ~= nil then
    pending.complete(true)
  end
end

function M:_cancel_pending_bag_show()
  local pending = self._pending_bag_show
  self._pending_bag_show = nil
  if pending ~= nil and pending.complete ~= nil then
    pending.complete(false)
  end
end

function M:_is_common_bag_panel_ready()
  return self:_is_loader_panel_ready(self.common_bag_panel)
end

function M:_is_stack_num_panel_ready()
  return self:_is_loader_panel_ready(self._stack_num_panel)
end

function M:_is_loader_panel_ready(panel)
  return panel ~= nil and panel._state_machine ~= nil and panel._state_machine:is_res_loaded()
end

function M:_refresh_coin_panel()
end

function M:_on_close_requested()
  if self._is_close_requested then
    return
  end
  self._is_close_requested = true
  local performance_value = self._is_sell_succeed and 1 or 0
  self._is_sell_succeed = false
  self._is_waiting_sell_result = false
  self:close_self()
  EventCenter.Broadcast(EventID.Performance.OnSellEnd, performance_value)
end

function M:_on_action_back()
  local mode = self._page_service:get_mode()
  if mode == self._page_service.Mode.Selling then
    self:_on_btn_bg()
  elseif mode == self._page_service.Mode.LeaveMessage then
    return
  else
    self:_on_close_requested()
  end
end

function M:_on_help_requested()
  local mode = self._page_service:get_mode()
  if mode == self._page_service.Mode.MarketOverview then
    tutorial_module:open_tutorial_handbook_page_with_tutorial_id(3, 30, 1)
  elseif mode == self._page_service.Mode.Prediction then
    tutorial_module:open_tutorial_handbook_page_with_tutorial_id(3, 31, 1)
  end
end

return M
