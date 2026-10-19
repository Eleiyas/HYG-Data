local M = G.Class("GeLianMarketSocialPage", G.UIWindow)
local base = G.UIWindow
local gelian_market_view_model = gelian_market_module.view_model
local friend_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketFriendPricePanel"
local return_panel_cls = "UI/GeLianMarket/Panel/GeLianMarketReturnRankPanel"
local sold_gold_tip_item_cls = "UI/GeLianMarket/Panel/GeLianMarketSoldGoldTipItem"
local market_time_util = require("UI/GeLianMarket/GeLianMarketTimeUtil")
local sold_gold_tip_item = require("UI/GeLianMarket/Panel/GeLianMarketSoldGoldTipItem")
local NEXT_REFRESH_COUNTDOWN_INTERVAL = 60

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GeLianFoodMarket/GeLianFoodMarketReturnRankPanel"
  self.config.type = EUIType.Page
  self._friend_panel = nil
  self._galactic_friend_panel = nil
  self._return_panel = nil
  self._sold_gold_tip_item = nil
  self._coin_view = nil
  self._is_galactic = false
  self._next_refresh_timer = 0
end

function M:on_create()
  base.on_create(self)
  self._friend_panel = self:add_panel(friend_panel_cls, self._trans_friend_price_group)
  self._galactic_friend_panel = self:add_panel(friend_panel_cls, self._trans_galactic_friend_price_group)
  self._return_panel = self:add_panel(return_panel_cls, self._trans_return_rank_group)
  self._sold_gold_tip_item = self:add_panel(sold_gold_tip_item_cls, self._trans_tip)
  self._coin_view = self:add_panel("UI/CommonUI/CommonCoinItemView", self._trans_coin_item, {
    coin_id = back_bag_module.coin_type.gold,
    auto_update = true,
    show_detail = true
  })
  self._coin_view:set_show_add(false)
  self:bind_close_btn(self._btn_back)
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._tog_friend_price, pack(self, M._on_tog_friend_price))
  self:bind_callback(self._tog_return_rank, pack(self, M._on_tog_return_rank))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help))
  self:_init_toggle_titles()
end

function M:_init_toggle_titles()
  UIUtil.set_text_by_id(self._txt_tab_friend_title, "Market_Social_Tab_FriendPrice")
  UIUtil.set_text_by_id(self._txt_tab_return_rank_title, "Market_Social_Tab_ReturnRank")
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data()
  self._is_galactic = extra_data ~= nil and extra_data.is_galactic == true
  self._state_group_galactic:SetState(self._is_galactic and 1 or 0)
  self._next_refresh_timer = NEXT_REFRESH_COUNTDOWN_INTERVAL
  self:_refresh_view()
  self:show_friend_price()
end

function M:register_events()
  base.register_events(self)
  local on_friend_data_changed_handler = pack(self, M._on_friend_data_changed)
  self:add_evt_listener(EventID.OnFriendListNotify, on_friend_data_changed_handler)
  self:add_evt_listener(EventID.OnFriendChangeNotify, on_friend_data_changed_handler)
  self:add_evt_listener(EventID.LuaGeLianMarketSellCountUpdate, on_friend_data_changed_handler)
  self:add_evt_listener(EventID.LuaGeLianMarketRandomPlayerUpdate, on_friend_data_changed_handler)
end

function M:_on_friend_data_changed()
  if not self.is_active then
    return
  end
  self:_refresh_view()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._is_galactic then
    self:_refresh_next_refresh_countdown(deltaTime)
  end
end

function M:_refresh_next_refresh_countdown(deltaTime)
  self._next_refresh_timer = self._next_refresh_timer + (deltaTime or 0)
  if self._next_refresh_timer < NEXT_REFRESH_COUNTDOWN_INTERVAL then
    return
  end
  self._next_refresh_timer = 0
  local remain = (CsGeLianMarketModuleUtil.NextRefreshTime or 0) - TimeUtil.ServerUtcTimeSeconds
  if remain <= 0 then
    UIUtil.set_text(self._txt_next_refresh, "")
    return
  end
  local countdown = UIUtil.format_left_time(remain)
  UIUtil.set_text_by_id(self._txt_next_refresh, "Market_InfoBoard_Refresh_Countdown", countdown)
end

function M:_refresh_view()
  self:_refresh_market_period()
  if self._is_galactic then
    self._galactic_friend_panel:render(gelian_market_view_model.build_random_player_price_view_data())
    return
  end
  local is_self_page = player_module:get_player_uid() == player_module:get_scene_owner_uid()
  local social_data = gelian_market_view_model.build_social_view_data(is_self_page)
  self._friend_panel:render(social_data)
  self._return_panel:render(social_data)
end

function M:_refresh_sold_gold_tip()
  if CsGeLianMarketModuleUtil.IsProfitRankEligible == true then
    self._sold_gold_tip_item:set_active(false)
    return
  end
  self._sold_gold_tip_item:render({
    threshold = sold_gold_tip_item.get_profit_threshold(),
    current_gold = sold_gold_tip_item.get_current_sold_gold()
  })
end

function M:_refresh_market_period()
  local start_text, end_text = market_time_util.get_market_period_texts()
  if not string.is_valid(start_text) or not string.is_valid(end_text) then
    UIUtil.set_text(self._txt_time, "")
    return
  end
  UIUtil.set_text_by_id(self._txt_time, "Market_CurrentPeriod", start_text, end_text)
end

function M:show_friend_price()
  self._tog_friend_price:SetIsOnWithoutNotify(true)
  self._tog_return_rank:SetIsOnWithoutNotify(false)
  self:_set_content_active(true)
end

function M:show_return_rank()
  self._tog_friend_price:SetIsOnWithoutNotify(false)
  self._tog_return_rank:SetIsOnWithoutNotify(true)
  self:_set_content_active(false)
end

function M:_on_tog_friend_price(is_on)
  if is_on then
    self:_set_content_active(true)
  end
end

function M:_on_tog_return_rank(is_on)
  if is_on then
    self:_set_content_active(false)
  end
end

function M:_set_content_active(show_friend)
  if self._is_galactic then
    self._galactic_friend_panel:set_active(true)
    self._friend_panel:set_active(false)
    self._return_panel:set_active(false)
    self._sold_gold_tip_item:set_active(false)
    return
  end
  self._galactic_friend_panel:set_active(false)
  self._friend_panel:set_active(show_friend)
  self._return_panel:set_active(not show_friend)
  self._sold_gold_tip_item:set_active(false)
end

function M:_on_btn_help()
  tutorial_module:open_tutorial_handbook_page_with_tutorial_id(3, 32, 1)
end

return M
