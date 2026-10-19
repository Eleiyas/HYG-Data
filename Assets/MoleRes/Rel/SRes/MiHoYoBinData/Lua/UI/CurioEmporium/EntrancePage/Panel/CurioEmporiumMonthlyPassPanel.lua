local M = G.Class("CurioEmporiumMonthlyPassPanel", G.CurioEmporiumEntrancePanelBase)
local base = G.CurioEmporiumEntrancePanelBase
local item_v2_panel_cls = "UI/Item/ItemV2Panel"
local QUERY_TIMEOUT = 15
local introduction_id = 37

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumMonthlyPassPanel"
  self._cfg = nil
  self._sdk_goods_data = nil
  self._query_timer = nil
  self._next_gift_time_change = nil
  self._refresh_check_timer = nil
  self._once_reward_item_id = nil
end

function M:on_create()
  base.on_create(self)
  UIUtil.set_active(self._btn_look, false)
  self._daily_reward_item_panel = self:add_panel(item_v2_panel_cls, self._obj_daily_reward_item)
  self._once_reward_item_panel = self:add_panel(item_v2_panel_cls, self._obj_once_reward_item)
end

function M:on_disable()
  base.on_disable(self)
  if self._query_timer then
    self._query_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
end

function M:update(delta_time)
  if self._query_timer then
    self._query_timer = self._query_timer + delta_time
    if self._query_timer >= QUERY_TIMEOUT then
      self:_on_query_finish(false)
    end
  end
  if self._next_gift_time_change then
    self._refresh_check_timer = (self._refresh_check_timer or 0) + delta_time
    if self._refresh_check_timer >= 1 then
      self._refresh_check_timer = 0
      if TimeUtil.ServerUtcTimeSeconds >= self._next_gift_time_change then
        self:_try_refresh_month_card()
      end
    end
  end
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_btn_buy_click))
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOnStoreGoodsInfoRefreshed, pack(self, M._on_store_goods_info_refreshed))
  self:add_evt_listener(EventID.LuaOnOpenConditionNotify, pack(self, M._on_open_condition_notify))
end

function M:_on_open_condition_notify(condition_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if not curio_emporium_module:is_month_card_unlock_condition(condition_id) then
    return
  end
  self:_try_refresh_month_card()
end

function M:_on_store_goods_info_refreshed(config_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if self._query_timer then
    return
  end
  if not curio_emporium_module:is_refreshed_goods_match(self._cfg, config_id) then
    return
  end
  self._sdk_goods_data = CsGameStoreModuleUtil.GetGoods(self._cfg.goodsid)
  self:_refresh_detail()
end

function M:set_tag_cfg(cfg)
  base.set_tag_cfg(self, cfg)
  UIUtil.set_text(self._txt_ad_des, cfg and cfg.advdesc or "")
end

function M:refresh()
  base.refresh(self)
  self._next_gift_time_change = curio_emporium_module:get_next_month_card_time_change()
  self._cfg = self:_find_month_card_cfg()
  self._sdk_goods_data = nil
  if not self._cfg then
    UIUtil.set_active(self._obj_root, false)
    return
  end
  if self._cfg:goodsid_is_empty() then
    UIUtil.set_active(self._obj_root, true)
    self:_refresh_detail()
    return
  end
  self._query_timer = 0
  EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
  UIUtil.set_active(self._obj_root, false)
  curio_emporium_module:query_vip_card_goods(pack(self, M._on_query_finish))
end

function M:_find_month_card_cfg()
  local all_cfgs = curio_emporium_module:get_all_gift_cfg()
  for _, cfg in pairs(all_cfgs or {}) do
    if curio_emporium_module:is_month_card_gift(cfg) and curio_emporium_module:is_gift_started(cfg) and not curio_emporium_module:is_gift_ended(cfg) and curio_emporium_module:is_gift_unlocked(cfg) then
      return cfg
    end
  end
  return nil
end

function M:_try_refresh_month_card()
  if self._query_timer then
    return
  end
  self._next_gift_time_change = curio_emporium_module:get_next_month_card_time_change()
  local cfg = self:_find_month_card_cfg()
  local cur_id = self._cfg and self._cfg.id or nil
  local new_id = cfg and cfg.id or nil
  if cur_id == new_id then
    return
  end
  self:refresh()
end

function M:_on_query_finish(success, goods_dict)
  if not self._query_timer then
    return
  end
  self._query_timer = nil
  EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  if is_null(self.game_obj) then
    return
  end
  local dict = success and goods_dict or nil
  self._sdk_goods_data = curio_emporium_module:get_sdk_goods_data(self._cfg, dict)
  if not curio_emporium_module:is_goods_displayable(self._cfg, dict) then
    UIUtil.set_active(self._obj_root, false)
    return
  end
  UIUtil.set_active(self._obj_root, true)
  self:_refresh_detail()
end

function M:_refresh_detail()
  UIUtil.set_text(self._txt_name, item_module:get_item_name_by_id(self._cfg.id) or "")
  self:_refresh_price()
  self:_refresh_pass_state()
  self:_refresh_reward_items()
  self:_refresh_buy_btn_state()
end

function M:_refresh_price()
  local price_info = self._sdk_goods_data and self._sdk_goods_data.price or nil
  UIUtil.set_text(self._txt_price, price_info and price_info.amountDisplay or "")
end

function M:_refresh_buy_btn_state()
  if is_null(self._btn_buy) then
    return
  end
  local cfg = self._cfg
  if not cfg then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  if not cfg:goodsid_is_empty() and not self._sdk_goods_data then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  UIUtil.set_active(self._btn_buy, true)
end

function M:_refresh_pass_state()
  local is_valid, left_days = curio_emporium_module:get_month_card_state()
  UIUtil.set_active(self._obj_pass_not_buy, not is_valid)
  UIUtil.set_active(self._obj_bg_time, is_valid)
  UIUtil.set_active(self._obj_pass_time_root, is_valid)
  UIUtil.set_active(self._obj_today_get, is_valid)
  if not is_valid then
    return
  end
  local days_text = curio_emporium_module:get_month_card_left_days_text(left_days)
  UIUtil.set_text_by_id(self._txt_pass_time, "Curio_Emporium_Left_Time_Day", days_text)
end

function M:_refresh_reward_items()
  local vip_card_cfg = curio_emporium_module:get_vip_card_cfg()
  local daily_item_id = vip_card_cfg and tonumber(vip_card_cfg.dailyrewarditemid) or 0
  local daily_item_count = vip_card_cfg and tonumber(vip_card_cfg.dailyrewarditemcount) or 0
  local has_daily_reward = 0 < daily_item_id and 0 < daily_item_count
  UIUtil.set_active(self._obj_daily_reward_item, has_daily_reward)
  if has_daily_reward then
    self._daily_reward_item_panel:set_item_data(daily_item_id, daily_item_count)
    self._daily_reward_item_panel:bind_item_info_btn(daily_item_id)
  end
  local once_reward_items = curio_emporium_module:get_gift_item_list(self._cfg.id)
  local once_reward_item = once_reward_items[1]
  self._once_reward_item_id = once_reward_item and once_reward_item.config_id or nil
  UIUtil.set_active(self._obj_once_reward_item, self._once_reward_item_id ~= nil)
  if self._once_reward_item_id then
    self._once_reward_item_panel:set_item_data(self._once_reward_item_id, once_reward_item.num)
    self._once_reward_item_panel:bind_item_info_btn(self._once_reward_item_id)
  end
end

function M:_on_btn_buy_click()
  if curio_emporium_module:try_block_store_with_tip() then
    return
  end
  if curio_emporium_module:try_block_tag_with_tip(curio_emporium_module.entrance_tag_type.monthly_pass) then
    return
  end
  if self._cfg and curio_emporium_module:is_gift_ended(self._cfg) then
    self:_try_refresh_month_card()
    return
  end
  if not self._cfg or curio_emporium_module:try_block_month_card_day_limit_with_tip() then
    return
  end
  if self._cfg:goodsid_is_empty() then
    return
  end
  local cfg_id = self._cfg.id
  CsGameStoreModuleUtil.PayGoods(self._cfg.goodsid, function(ret, msg)
    if ret ~= 0 then
      Logger.LogWarning("[CurioEmporiumMonthlyPass] Pay failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
      return
    end
    curio_emporium_module:show_purchase_reward(cfg_id)
    if is_null(self.game_obj) then
      return
    end
    self:refresh()
  end)
end

function M:_on_btn_info_click()
  if not self._cfg then
    return
  end
  common_ui_module:show_introduction_dialog(introduction_id)
end

return M
