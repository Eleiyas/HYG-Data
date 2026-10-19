local M = G.Class("ThemeSeasonBPPayPage", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name
local SLOT = theme_season_module.BP_SLOT
local SLOT_STATE = theme_season_module.BP_SLOT_STATE
local SLOT_OVERLAY_TEXT_ID = {
  [SLOT_STATE.UNAVAILABLE] = "ThemeSeason_UI_029",
  [SLOT_STATE.PURCHASED] = "ThemeSeason_UI_030",
  [SLOT_STATE.GIFTED] = "ThemeSeason_UI_046"
}
local GIFT_BTN_TEXT_ID = "ThemeSeason_UI_045"
local GOODS_UNAVAILABLE_TEXT_ID = "TVShopping_ExpireTip"
local GIFT_UNAVAILABLE_TEXT_ID = "ThemeSeason_UI_087"

local function get_sdk_goods_key(cfg)
  return cfg and cfg.bptype or nil
end

local DOUBLE_LABEL_TEXT_ID = "ThemeSeason_UI_083"
local DOUBLE_LABEL_GIFT_TEXT_ID = "ThemeSeason_UI_084"
local DEBUG_UPGRADE_PRICE_SUFFIX = "(差价)"
local DEBUG_SLOTS = {
  {
    slot = SLOT.SINGLE_COMMON,
    name = "单人普通"
  },
  {
    slot = SLOT.SINGLE_LUXURY,
    name = "单人豪华"
  },
  {
    slot = SLOT.DOUBLE_COMMON,
    name = "双人普通"
  },
  {
    slot = SLOT.DOUBLE_LUXURY,
    name = "双人豪华"
  }
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonPayPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._last_remain_seconds = -1
  self._premium_got_items = {}
  self._exchange_items = {}
  self._exchange_daily_panels = {}
  self._exchange_descs = nil
  self._last_item_exchange_mode = nil
  self._bp_goods_dict = nil
  self._bp_goods_querying = false
  self._slot_descs = nil
  self._txt_time = nil
  self._img_video = nil
  self._txt_content = nil
  self._txt_title = nil
  self._txt_title_basic = nil
  self._txt_title_premium = nil
  self._btn_info_dark = nil
  self._btn_close_normal = nil
  self._img_npc = nil
  self._btn_spend_basic_1 = nil
  self._btn_spend_basic_2 = nil
  self._btn_spend_premium_1 = nil
  self._btn_spend_premium_2 = nil
  self._trans_not_buy_basic = nil
  self._trans_not_buy_premium = nil
  self._txt_not_buy_basic = nil
  self._txt_not_buy_premium = nil
  self._trans_gifted_basic = nil
  self._trans_gifted_premium = nil
  self._txt_gifted_basic = nil
  self._txt_gifted_premium = nil
  self._img_coin_icon_basic_1 = nil
  self._img_coin_icon_basic_2 = nil
  self._img_coin_icon_premium_1 = nil
  self._img_coin_icon_premium_2 = nil
  self._txt_coin_num_basic_1 = nil
  self._txt_coin_num_basic_2 = nil
  self._txt_coin_num_premium_1 = nil
  self._txt_coin_num_premium_2 = nil
  self._txt_two_person_basic = nil
  self._txt_two_person_premium = nil
  self._trans_add_item_basic = nil
  self._trans_add_item_premium = nil
  self._trans_scrolll_basic = nil
  self._trans_scrolll_premium_got = nil
  self._trans_scrolll_premium_extra = nil
  self._item_binder_baisc = nil
  self._item_binder_premium_got = nil
  self._item_binder_premium_extra = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_bp_purchased, pack(self, M._on_bp_purchased))
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M._on_purchase_rsp))
  self:add_evt_listener(EventID.OnEmergencySwitchStateChanged, pack(self, M._on_emergency_switch_changed))
  self:add_evt_listener(EventID.LuaChangePacket, pack(self, M._on_packet_changed))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.BP_PAY)
end

function M:on_enable()
  base.on_enable(self)
  self._last_remain_seconds = -1
  if not theme_season_module:is_bp_item_exchange_mode() then
    self:_query_bp_goods_then_refresh()
  end
  self:refresh()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:update()
  self:_refresh_remaining_time()
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_normal)
  if not_null(self._btn_info_dark) then
    self:bind_callback(self._btn_info_dark, pack(self, M._on_btn_info_click))
  end
  self:_bind_slot_btn(self._btn_spend_basic_1, SLOT.SINGLE_COMMON)
  self:_bind_slot_btn(self._btn_spend_premium_1, SLOT.SINGLE_LUXURY)
  self:_bind_slot_btn(self._btn_spend_basic_2, SLOT.DOUBLE_COMMON)
  self:_bind_slot_btn(self._btn_spend_premium_2, SLOT.DOUBLE_LUXURY)
end

function M:_bind_slot_btn(btn, slot)
  if is_null(btn) then
    return
  end
  self:bind_callback(btn, function()
    self:_on_slot_click(slot)
  end)
end

function M:_get_slot_descs()
  if self._slot_descs == nil then
    self._slot_descs = {
      {
        slot = SLOT.SINGLE_COMMON,
        btn = self._btn_spend_basic_1,
        overlay = self._trans_not_buy_basic,
        overlay_txt = self._txt_not_buy_basic,
        coin_img = self._img_coin_icon_basic_1,
        coin_txt = self._txt_coin_num_basic_1
      },
      {
        slot = SLOT.SINGLE_LUXURY,
        btn = self._btn_spend_premium_1,
        overlay = self._trans_not_buy_premium,
        overlay_txt = self._txt_not_buy_premium,
        coin_img = self._img_coin_icon_premium_1,
        coin_txt = self._txt_coin_num_premium_1
      },
      {
        slot = SLOT.DOUBLE_COMMON,
        btn = self._btn_spend_basic_2,
        overlay = self._trans_gifted_basic,
        overlay_txt = self._txt_gifted_basic,
        coin_img = self._img_coin_icon_basic_2,
        coin_txt = self._txt_coin_num_basic_2,
        double_label = self._txt_two_person_basic
      },
      {
        slot = SLOT.DOUBLE_LUXURY,
        btn = self._btn_spend_premium_2,
        overlay = self._trans_gifted_premium,
        overlay_txt = self._txt_gifted_premium,
        coin_img = self._img_coin_icon_premium_2,
        coin_txt = self._txt_coin_num_premium_2,
        double_label = self._txt_two_person_premium
      }
    }
  end
  return self._slot_descs
end

function M:_on_purchase_rsp()
  self:refresh()
end

function M:_on_bp_purchased()
  if not theme_season_module:is_bp_item_exchange_mode() then
    self:_query_bp_goods_then_refresh()
  end
  self:refresh()
end

function M:_on_emergency_switch_changed()
  local item_mode = theme_season_module:is_bp_item_exchange_mode()
  if item_mode == self._last_item_exchange_mode then
    return
  end
  self._last_item_exchange_mode = item_mode
  self:refresh()
end

function M:_on_packet_changed()
  self:_refresh_purchase_state()
end

function M:_on_btn_info_click()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local intro_id = season_cfg and season_cfg.introductionid or 0
  if 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

function M:_on_slot_click(slot)
  local info = theme_season_module:get_bp_slot_state(slot)
  if info.state == SLOT_STATE.GIFTABLE then
    self:_on_gift_click(info)
    return
  end
  if info.state ~= SLOT_STATE.PURCHASABLE then
    return
  end
  local cfg = theme_season_module:get_bp_price_by_type(info.bp_type)
  if cfg then
    self:_try_purchase(cfg)
  end
end

function M:_on_gift_click(info)
  theme_season_module:open_bp_gift_dialog(info and info.gift_item_id or 0)
end

function M:_try_purchase(cfg)
  if cfg == nil then
    return
  end
  local product_id = cfg.id
  if theme_season_module:try_block_bp_shop_with_tip() then
    return
  end
  if not theme_season_module:is_season_active() then
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_007")
    return
  end
  if theme_season_module:is_season_closing(theme_season_module.CONST_TYPE.FORBID_BUY_BP_MINUTES) then
    local remain = theme_season_module:get_remaining_seconds()
    local time_str = UIUtil.format_left_time(remain)
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_039", time_str)
    return
  end
  if theme_season_module:is_product_purchased(product_id) then
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_006")
    return
  end
  if theme_season_module:is_bp_item_exchange_mode() then
    local cost_items = theme_season_module:get_bp_purchasing_items_by_cfg(cfg)
    local lack_item = self:_find_insufficient_item(cost_items)
    if lack_item then
      common_ui_module:show_coin_lack_dialog(lack_item.item_id)
      return
    end
  elseif self:_get_sdk_goods(cfg) == nil then
    UIUtil.show_tips_by_text_id(GOODS_UNAVAILABLE_TEXT_ID)
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(theme_season_module:get_bp_purchase_confirm_text(product_id), UIUtil.get_text_by_id("Common_Confirm"), UIUtil.get_text_by_id("Common_Cancel"), UIUtil.get_text_by_id("ThemeSeason_UI_065"))
  popup:set_callbacks(function()
    self:_do_purchase(cfg)
  end)
  popup:show()
end

function M:_find_insufficient_item(cost_items)
  for i = 1, #cost_items do
    local entry = cost_items[i]
    if entry.item_id > 0 and 0 < entry.count and back_bag_module:get_coin_or_item_num(entry.item_id) < entry.count then
      return entry
    end
  end
  return nil
end

function M:_do_purchase(cfg)
  if theme_season_module:is_bp_item_exchange_mode() then
    CsThemeSeasonModuleUtil.SendBpItemPurchaseReq(cfg.id)
  else
    CsGameStoreModuleUtil.PayGoods(get_sdk_goods_key(cfg), function(ret, msg)
      if ret ~= 0 then
        Logger.LogWarning("[ThemeSeasonBPPayPage] PayGoods failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
      end
    end)
  end
end

function M:refresh()
  self:_refresh_header()
  self:_refresh_purchase_state()
  self:_refresh_item_lists()
  self._last_remain_seconds = -1
  self:_refresh_remaining_time()
  self._last_item_exchange_mode = theme_season_module:is_bp_item_exchange_mode()
end

function M:_refresh_header()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  if season_cfg then
    UIUtil.set_text(self._txt_title, season_cfg.title or "")
    UIUtil.set_text(self._txt_title_basic, season_cfg.commonbpname or "")
    UIUtil.set_text(self._txt_title_premium, season_cfg.luxurybpname or "")
    if not_null(self._img_npc) and string.is_valid(season_cfg.npcsicon) then
      UIUtil.set_image(self._img_npc, season_cfg.npcsicon, self:get_load_proxy())
    end
  end
  self:_refresh_bp_desc()
end

function M:_refresh_bp_desc()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  if season_cfg == nil then
    return
  end
  local content = season_cfg.bpdesc or ""
  if theme_season_module:is_debug_mode() then
    content = content .. self:_build_debug_bp_info()
  end
  UIUtil.set_text(self._txt_content, content)
end

function M:_build_debug_bp_info()
  local tier = theme_season_module:get_bp_current_tier()
  local purchased_ids = theme_season_module:get_purchased_bp_product_ids()
  local lines = {
    string.format("\n[Debug] BP档位 %s 已购=%s", theme_season_module:get_bp_tier_name(tier), 0 < #purchased_ids and table.concat(purchased_ids, ",") or "无")
  }
  for i = 1, #DEBUG_SLOTS do
    local entry = DEBUG_SLOTS[i]
    local info = theme_season_module:get_bp_slot_state(entry.slot)
    local cfg = info.bp_type ~= nil and theme_season_module:get_bp_price_by_type(info.bp_type) or nil
    local goods_key = get_sdk_goods_key(cfg)
    lines[#lines + 1] = string.format("\n[Debug] %s id=%s configid=%s SDK卡位=%s", entry.name, cfg and tostring(cfg.id) or "-", string.is_valid(goods_key) and goods_key or "-", self:_get_debug_card_slot_text(goods_key))
  end
  return table.concat(lines)
end

function M:_get_sdk_goods(cfg)
  local goods_key = get_sdk_goods_key(cfg)
  if not string.is_valid(goods_key) or self._bp_goods_dict == nil then
    return nil
  end
  local ok, data = self._bp_goods_dict:TryGetValue(goods_key)
  if not ok or is_null(data) then
    return nil
  end
  return data
end

function M:_get_debug_card_slot_text(goods_key)
  if theme_season_module:is_bp_item_exchange_mode() then
    return "未查询(道具兑换模式)"
  end
  if not string.is_valid(goods_key) then
    return "-"
  end
  if self._bp_goods_dict == nil then
    return "商品未就绪"
  end
  local ok, goods = self._bp_goods_dict:TryGetValue(goods_key)
  if not ok or is_null(goods) then
    return "商品未下发"
  end
  if is_null(goods.bpCardSlot) then
    return "无卡位字段(未SDK登录?)"
  end
  return string.format("%s/%s", goods.bpCardSlot.slotType or "-", goods.bpCardSlot.displayHint or "-")
end

function M:_refresh_purchase_state()
  local item_mode = theme_season_module:is_bp_item_exchange_mode()
  if not item_mode and self._bp_goods_dict == nil then
    self:_query_bp_goods_then_refresh()
  end
  local descs = self:_get_slot_descs()
  for i = 1, #descs do
    local desc = descs[i]
    self:_apply_slot(desc, theme_season_module:get_bp_slot_state(desc.slot), item_mode)
  end
end

function M:_resolve_render_state(info, item_mode)
  local overlay_text_id = SLOT_OVERLAY_TEXT_ID[info.state]
  if item_mode then
    return info.state, overlay_text_id
  end
  if info.state == SLOT_STATE.PURCHASABLE then
    local cfg = theme_season_module:get_bp_price_by_type(info.bp_type)
    if self:_get_sdk_goods(cfg) == nil then
      return SLOT_STATE.UNAVAILABLE, SLOT_OVERLAY_TEXT_ID[SLOT_STATE.UNAVAILABLE]
    end
  elseif info.state == SLOT_STATE.GIFTABLE and self._bp_goods_dict == nil then
    return SLOT_STATE.UNAVAILABLE, GIFT_UNAVAILABLE_TEXT_ID
  end
  return info.state, overlay_text_id
end

function M:_apply_slot(desc, info, item_mode)
  local state, overlay_text_id = self:_resolve_render_state(info, item_mode)
  local is_giftable = state == SLOT_STATE.GIFTABLE
  local show_btn = state == SLOT_STATE.PURCHASABLE or is_giftable
  self:_apply_double_label(desc.double_label, state)
  if not_null(desc.btn) then
    UIUtil.set_active(desc.btn.transform, show_btn)
  end
  if not_null(desc.overlay) then
    UIUtil.set_active(desc.overlay, overlay_text_id ~= nil)
  end
  if overlay_text_id ~= nil and not_null(desc.overlay_txt) then
    UIUtil.set_text(desc.overlay_txt, UIUtil.get_text_by_id(overlay_text_id))
  end
  if not_null(desc.coin_img) then
    UIUtil.set_active(desc.coin_img.transform, show_btn and item_mode and not is_giftable)
  end
  if not_null(desc.coin_txt) then
    UIUtil.set_active(desc.coin_txt.transform, show_btn)
  end
  if not show_btn then
    return
  end
  if is_giftable then
    if not_null(desc.coin_txt) then
      UIUtil.set_text(desc.coin_txt, UIUtil.get_text_by_id(GIFT_BTN_TEXT_ID))
    end
    return
  end
  self:_apply_price_slot(desc.coin_img, desc.coin_txt, info.bp_type, item_mode)
end

function M:_apply_double_label(label, state)
  if is_null(label) then
    return
  end
  local is_gift_column = state == SLOT_STATE.GIFTABLE or state == SLOT_STATE.GIFTED
  UIUtil.set_text_by_id(label, is_gift_column and DOUBLE_LABEL_GIFT_TEXT_ID or DOUBLE_LABEL_TEXT_ID)
end

function M:_apply_price_slot(img, txt, bp_type, item_mode)
  if bp_type == nil then
    return
  end
  local price_suffix = ""
  if theme_season_module:is_debug_mode() then
    local cfg = theme_season_module:get_bp_price_by_type(bp_type)
    price_suffix = string.format(" [id=%s]%s", cfg and tostring(cfg.id) or "-", theme_season_module:is_bp_upgrade_type(bp_type) and DEBUG_UPGRADE_PRICE_SUFFIX or "")
  end
  if item_mode then
    local cost_items = theme_season_module:get_bp_purchasing_items(bp_type)
    local first = cost_items[1]
    if first and first.item_id > 0 then
      if not_null(img) then
        item_module:set_item_icon(img, first.item_id, nil, nil, self:get_load_proxy())
      end
      if not_null(txt) then
        UIUtil.set_text(txt, tostring(first.count) .. price_suffix)
      end
    end
  elseif not_null(txt) then
    local cfg = theme_season_module:get_bp_price_by_type(bp_type)
    local goods = self:_get_sdk_goods(cfg)
    if goods and not is_null(goods.price) then
      UIUtil.set_text(txt, (goods.price.amountDisplay or "") .. price_suffix)
    else
      UIUtil.set_text(txt, price_suffix)
    end
  end
end

function M:_query_bp_goods_then_refresh()
  if self._bp_goods_querying then
    return
  end
  self._bp_goods_querying = true
  curio_emporium_module:query_bp_goods(function(success, goods_dict)
    self._bp_goods_querying = false
    if is_null(self.game_obj) then
      return
    end
    if not success or goods_dict == nil then
      return
    end
    self._bp_goods_dict = goods_dict
    self:_refresh_purchase_state()
    self:_refresh_bp_desc()
  end)
end

function M:_refresh_remaining_time()
  local remain = theme_season_module:get_remaining_seconds()
  if remain == self._last_remain_seconds then
    return
  end
  self._last_remain_seconds = remain
  local time_text = theme_season_module:format_season_remaining_time(remain)
  UIUtil.set_text(self._txt_time, time_text)
end

function M:_get_exchange_descs()
  if self._exchange_descs == nil then
    self._exchange_descs = {
      {
        key = "basic",
        binder = self._item_binder_baisc,
        add_item = self._trans_add_item_basic
      },
      {
        key = "premium",
        binder = self._item_binder_premium_extra,
        add_item = self._trans_add_item_premium
      }
    }
  end
  return self._exchange_descs
end

function M:_refresh_item_lists()
  local bp_bonus_items = theme_season_module:get_bp_bonus_items()
  local instant_items = theme_season_module:get_season_instant_reward_items()
  local daily_item = theme_season_module:get_season_daily_reward_items()[1]
  self:_refresh_premium_got_item_list(instant_items)
  local descs = self:_get_exchange_descs()
  for i = 1, #descs do
    self:_refresh_exchange_area(descs[i], daily_item, bp_bonus_items)
  end
end

function M:_create_item_panel(binder)
  local obj = binder:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local cls = self:add_panel(item_v2_cls, obj)
  UIUtil.set_active(obj, true)
  local btn = cls:get_btn()
  if btn then
    self:bind_callback(btn, function()
      local cfg_id = cls:get_cfg_id()
      if cfg_id and 0 < cfg_id then
        item_module:open_item_info_dialog(cfg_id, back_bag_module:get_coin_or_item_num(cfg_id))
      end
    end)
  end
  return cls
end

function M:_build_item_list(binder, item_list, cache)
  if is_null(binder) then
    return cache
  end
  for i = 1, #item_list do
    local entry = item_list[i]
    local cls = cache[i]
    if cls == nil then
      cls = self:_create_item_panel(binder)
      cache[i] = cls
    end
    if cls ~= nil then
      cls:set_item_data(entry.item_id, entry.count)
      cls:set_active(true)
    end
  end
  for i = #item_list + 1, #cache do
    local cls = cache[i]
    if cls ~= nil then
      cls:set_active(false)
    end
  end
  return cache
end

function M:_refresh_exchange_area(desc, daily_item, bonus_items)
  if is_null(desc.binder) then
    return
  end
  local has_daily = daily_item ~= nil
  local daily_panel = self._exchange_daily_panels[desc.key]
  if daily_panel == nil and has_daily then
    daily_panel = self:_create_item_panel(desc.binder)
    self._exchange_daily_panels[desc.key] = daily_panel
  end
  if daily_panel ~= nil then
    daily_panel:set_active(has_daily)
    if has_daily then
      daily_panel:set_item_data(daily_item.item_id, daily_item.count)
    end
    self:_set_img_daily_active(daily_panel, has_daily)
  end
  local items = self:_build_item_list(desc.binder, bonus_items, self._exchange_items[desc.key] or {})
  self._exchange_items[desc.key] = items
  for i = 1, #items do
    local cls = items[i]
    if cls ~= nil then
      self:_set_img_daily_active(cls, false)
    end
  end
  local sibling = 0
  if daily_panel ~= nil and has_daily then
    daily_panel.trans:SetSiblingIndex(sibling)
    sibling = sibling + 1
  end
  if not_null(desc.add_item) then
    UIUtil.set_active(desc.add_item, has_daily)
    if has_daily then
      desc.add_item:SetSiblingIndex(sibling)
      sibling = sibling + 1
    end
  end
  for i = 1, #bonus_items do
    local cls = items[i]
    if cls ~= nil then
      cls.trans:SetSiblingIndex(sibling)
      sibling = sibling + 1
    end
  end
end

function M:_refresh_premium_got_item_list(instant_items)
  self._premium_got_items = self:_build_item_list(self._item_binder_premium_got, instant_items, self._premium_got_items)
  for i = 1, #self._premium_got_items do
    local cls = self._premium_got_items[i]
    if cls ~= nil then
      self:_set_img_daily_active(cls, false)
    end
  end
end

function M:_set_img_daily_active(item_panel, active)
  if item_panel == nil then
    return
  end
  local img_daily = UIUtil.find_trans(item_panel.trans, "scale/node/img_daily")
  if not_null(img_daily) then
    UIUtil.set_active(img_daily, active)
  end
end

return M
