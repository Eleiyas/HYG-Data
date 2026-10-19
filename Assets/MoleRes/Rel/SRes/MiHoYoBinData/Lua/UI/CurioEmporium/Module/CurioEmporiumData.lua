curio_emporium_module = curio_emporium_module or {}

function curio_emporium_module:is_store_blocked()
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseStoreEntry)
end

function curio_emporium_module:try_block_store_with_tip()
  if not self:is_store_blocked() then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

function curio_emporium_module:is_recharge_blocked()
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseRechargeEntry)
end

function curio_emporium_module:try_block_recharge_with_tip(tip_text)
  if not self:is_recharge_blocked() then
    return false
  end
  if tip_text and tip_text ~= "" then
    UIUtil.show_tips(tip_text)
  else
    CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  end
  return true
end

function curio_emporium_module:_get_tag_emergency_switch(tag_id)
  local switches = {
    [self.entrance_tag_type.first_recharge] = EmergencySwitchType.EmergencySwitchCloseStoreFirstRecharge,
    [self.entrance_tag_type.monthly_pass] = EmergencySwitchType.EmergencySwitchCloseStoreMonthlyPass,
    [self.entrance_tag_type.season_bp] = EmergencySwitchType.EmergencySwitchCloseBpShop,
    [self.entrance_tag_type.top_up_mall] = EmergencySwitchType.EmergencySwitchCloseRechargeEntry
  }
  return switches[tag_id]
end

function curio_emporium_module:is_tag_blocked_by_emergency_switch(tag_id)
  local switch_type = self:_get_tag_emergency_switch(tag_id)
  if not switch_type then
    return false
  end
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(switch_type)
end

function curio_emporium_module:try_block_tag_with_tip(tag_id)
  if not self:is_tag_blocked_by_emergency_switch(tag_id) then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

function curio_emporium_module:is_gift_blocked_by_tag_emergency_switch(cfg)
  if not cfg or not cfg.typeLength then
    return false
  end
  for i = 0, cfg.typeLength - 1 do
    if self:is_tag_blocked_by_emergency_switch(cfg:type(i)) then
      return true
    end
  end
  return false
end

function curio_emporium_module:try_block_gift_by_tag_switch_with_tip(cfg)
  if not self:is_gift_blocked_by_tag_emergency_switch(cfg) then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

function curio_emporium_module:init_tag_cfg()
  local tag_cfg_table = ExcelDataUtil.get_table(typeof(BCurioShopTagCfg))
  self._curio_shop_tag_cfgs = {}
  for _, cfg in pairs(tag_cfg_table or {}) do
    table.insert(self._curio_shop_tag_cfgs, cfg)
  end
  table.sort(self._curio_shop_tag_cfgs, function(left_cfg, right_cfg)
    if left_cfg.index == right_cfg.index then
      return left_cfg.tagid < right_cfg.tagid
    end
    return left_cfg.index < right_cfg.index
  end)
end

function curio_emporium_module:get_all_tag_cfg()
  if self._curio_shop_tag_cfgs == nil then
    self:init_tag_cfg()
  end
  return self._curio_shop_tag_cfgs
end

function curio_emporium_module:get_tag_name(tag_id)
  if self._curio_shop_tag_cfgs == nil then
    self:init_tag_cfg()
  end
  for _, cfg in pairs(self._curio_shop_tag_cfgs) do
    if cfg.tagid == tag_id then
      return cfg.name
    end
  end
  return nil
end

function curio_emporium_module:get_tag_cfg(tag_id)
  if self._curio_shop_tag_cfgs == nil then
    self:init_tag_cfg()
  end
  for _, cfg in pairs(self._curio_shop_tag_cfgs) do
    if cfg.tagid == tag_id then
      return cfg
    end
  end
  return nil
end

function curio_emporium_module:is_tag_visible(tag_id)
  if self:is_tag_blocked_by_emergency_switch(tag_id) then
    return false
  end
  local checkers = {
    [self.entrance_tag_type.first_recharge] = self._is_first_recharge_tag_visible,
    [self.entrance_tag_type.season_bp] = self._is_season_bp_tag_visible,
    [self.entrance_tag_type.hot_sale] = self._is_hot_sale_tag_visible,
    [self.entrance_tag_type.top_up_mall] = self._is_top_up_mall_tag_visible,
    [self.entrance_tag_type.monthly_pass] = self._is_monthly_pass_tag_visible
  }
  local checker = checkers[tag_id]
  if checker then
    return checker(self)
  end
  return true
end

function curio_emporium_module:get_first_visible_tag_id()
  local all_tag_cfgs = self:get_all_tag_cfg()
  for _, cfg in ipairs(all_tag_cfgs) do
    if self:is_tag_visible(cfg.tagid) then
      return cfg.tagid
    end
  end
  return nil
end

function curio_emporium_module:_is_first_recharge_tag_visible()
  return true
end

function curio_emporium_module:_is_season_bp_tag_visible()
  return theme_season_module:is_season_active()
end

function curio_emporium_module:_is_hot_sale_tag_visible()
  return true
end

function curio_emporium_module:_is_top_up_mall_tag_visible()
  return true
end

function curio_emporium_module:_is_monthly_pass_tag_visible()
  return true
end

function curio_emporium_module:init_top_up_cfg()
  self._curio_shop_top_up_cfgs = ExcelDataUtil.get_table(typeof(BCurioShopTopUpCfg))
end

function curio_emporium_module:get_all_top_up_cfg()
  if self._curio_shop_top_up_cfgs == nil then
    self:init_top_up_cfg()
  end
  return self._curio_shop_top_up_cfgs
end

function curio_emporium_module:init_gift_cfg()
  self._curio_shop_gift_cfgs = ExcelDataUtil.get_table(typeof(BCurioShopGiftCfg))
  self._gift_unlock_condition_set_by_type = nil
  self._gift_cfg_by_type = {}
  if self._curio_shop_gift_cfgs then
    for _, cfg in pairs(self._curio_shop_gift_cfgs) do
      local type_count = cfg.typeLength
      for i = 0, type_count - 1 do
        local gift_type = cfg:type(i)
        if not self._gift_cfg_by_type[gift_type] then
          self._gift_cfg_by_type[gift_type] = {}
        end
        table.insert(self._gift_cfg_by_type[gift_type], cfg)
      end
    end
  end
end

function curio_emporium_module:get_all_gift_cfg()
  if self._curio_shop_gift_cfgs == nil then
    self:init_gift_cfg()
  end
  return self._curio_shop_gift_cfgs
end

function curio_emporium_module:is_gift_started(cfg)
  if not cfg then
    return false
  end
  local starttime = cfg.starttime
  if not starttime or starttime == "" then
    return true
  end
  local start_ts = self:parse_endtime(starttime)
  if start_ts <= 0 then
    return true
  end
  return start_ts <= TimeUtil.ServerUtcTimeSeconds
end

function curio_emporium_module:is_gift_ended(cfg)
  if not cfg then
    return false
  end
  local endtime = cfg.endtime
  if not endtime or endtime == "" then
    return false
  end
  local end_ts = self:parse_endtime(endtime)
  if end_ts <= 0 then
    return false
  end
  return end_ts <= TimeUtil.ServerUtcTimeSeconds
end

function curio_emporium_module:is_gift_unlocked(cfg)
  if not cfg then
    return false
  end
  local unlock_id = cfg.unlockopenstateconfigid or 0
  if unlock_id <= 0 then
    return true
  end
  return OpenStateUtil.GetConditionIsOpen(unlock_id)
end

function curio_emporium_module:get_gift_cfg_by_type(gift_type)
  if self._gift_cfg_by_type == nil then
    self:init_gift_cfg()
  end
  local all_cfgs = self._gift_cfg_by_type[gift_type]
  if not all_cfgs then
    return {}
  end
  local result = {}
  for _, cfg in ipairs(all_cfgs) do
    if self:is_gift_started(cfg) and not self:is_gift_ended(cfg) and self:is_gift_unlocked(cfg) then
      table.insert(result, cfg)
    end
  end
  return result
end

function curio_emporium_module:get_next_gift_time_change(gift_type)
  if self._gift_cfg_by_type == nil then
    self:init_gift_cfg()
  end
  local all_cfgs = self._gift_cfg_by_type[gift_type]
  if not all_cfgs then
    return nil
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local next_time
  for _, cfg in ipairs(all_cfgs) do
    local start_time = self:parse_endtime(cfg.starttime)
    if now < start_time and (not next_time or next_time > start_time) then
      next_time = start_time
    end
    local end_time = self:parse_endtime(cfg.endtime)
    if now < end_time and (not next_time or next_time > end_time) then
      next_time = end_time
    end
  end
  return next_time
end

function curio_emporium_module:_get_gift_unlock_condition_set(gift_type)
  self._gift_unlock_condition_set_by_type = self._gift_unlock_condition_set_by_type or {}
  local condition_set = self._gift_unlock_condition_set_by_type[gift_type]
  if condition_set then
    return condition_set
  end
  condition_set = {}
  self._gift_unlock_condition_set_by_type[gift_type] = condition_set
  if self._gift_cfg_by_type == nil then
    self:init_gift_cfg()
  end
  local all_cfgs = self._gift_cfg_by_type[gift_type] or {}
  for _, cfg in ipairs(all_cfgs) do
    local condition_id = cfg.unlockopenstateconfigid or 0
    if 0 < condition_id then
      condition_set[condition_id] = true
    end
  end
  return condition_set
end

function curio_emporium_module:is_gift_unlock_condition(gift_type, condition_id)
  if not condition_id or condition_id <= 0 then
    return false
  end
  return self:_get_gift_unlock_condition_set(gift_type)[condition_id] == true
end

function curio_emporium_module:get_gift_cfg_grouped_by_tag(gift_type)
  local type_cfgs = self:get_gift_cfg_by_type(gift_type)
  if #type_cfgs == 0 then
    return {}
  end
  local tag_map = {}
  for _, cfg in ipairs(type_cfgs) do
    local tag = cfg.tag
    if not tag_map[tag] then
      tag_map[tag] = {}
    end
    table.insert(tag_map[tag], cfg)
  end
  for _, cfgs in pairs(tag_map) do
    table.sort(cfgs, function(a, b)
      return a.index < b.index
    end)
  end
  local groups = {}
  for tag, cfgs in pairs(tag_map) do
    table.insert(groups, {tag = tag, cfgs = cfgs})
  end
  table.sort(groups, function(a, b)
    return a.tag < b.tag
  end)
  return groups
end

function curio_emporium_module:get_gift_group_name(tag)
  local cfg = ExcelDataUtil.get_value(typeof(BCurioShopNameCfg), tag)
  if cfg == nil then
    return nil
  end
  return cfg.tagname
end

function curio_emporium_module:query_hot_sale_goods(callback)
  CsGameStoreModuleUtil.QueryHotSaleGoods(callback)
end

function curio_emporium_module:query_virtual_currency_goods(callback)
  CsGameStoreModuleUtil.QueryVirtualCurrencyGoods(callback)
end

function curio_emporium_module:query_vip_card_goods(callback)
  CsGameStoreModuleUtil.QueryVipCardGoods(callback)
end

function curio_emporium_module:query_bp_goods(callback)
  CsGameStoreModuleUtil.QueryBpGoods(callback)
end

function curio_emporium_module:query_permanent_item_goods(callback)
  CsGameStoreModuleUtil.QueryPermanentItemGoods(callback)
end

function curio_emporium_module:query_consumable_goods(callback)
  CsGameStoreModuleUtil.QueryConsumableGoods(callback)
end

function curio_emporium_module:get_sdk_goods_data(cfg, goods_dict)
  if not (cfg and goods_dict) or cfg:goodsid_is_empty() then
    return nil
  end
  local ok, data = goods_dict:TryGetValue(cfg.goodsid)
  if not ok then
    return nil
  end
  return data
end

function curio_emporium_module:is_goods_displayable(cfg, goods_dict)
  if not cfg then
    return false
  end
  if cfg:goodsid_is_empty() then
    return true
  end
  return self:get_sdk_goods_data(cfg, goods_dict) ~= nil
end

function curio_emporium_module:is_refreshed_goods_match(cfg, config_id)
  if not (cfg and config_id) or config_id == "" or cfg:goodsid_is_empty() then
    return false
  end
  return cfg.goodsid == config_id
end

function curio_emporium_module:is_sdk_goods_sold_out(goods_data)
  if not goods_data then
    return false
  end
  if goods_data.purchaseLimitReached then
    return true
  end
  local consumable = goods_data.consumable
  if consumable and consumable.cycleCount > 0 then
    return 0 >= consumable.cycleCount - consumable.purchasedCount
  end
  return false
end

function curio_emporium_module:can_buy_sdk_goods(goods_data)
  if not goods_data then
    return false
  end
  if not goods_data.purchaseEligible then
    return false
  end
  return not self:is_sdk_goods_sold_out(goods_data)
end

function curio_emporium_module:get_sdk_goods_limit(goods_data)
  if not goods_data then
    return nil, nil
  end
  local consumable = goods_data.consumable
  if consumable and consumable.cycleCount > 0 then
    local total = consumable.cycleCount
    local remain = total - consumable.purchasedCount
    if remain < 0 then
      remain = 0
    end
    return remain, total
  end
  if goods_data.isPermanentItem then
    return self:is_sdk_goods_sold_out(goods_data) and 0 or 1, 1
  end
  return nil, nil
end

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local _endtime_cache = {}

function curio_emporium_module:parse_endtime(str)
  if not str or str == "" then
    return 0
  end
  local cached = _endtime_cache[str]
  if cached then
    return cached
  end
  local y, m, d, h, mi, s = string.match(str, "(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")
  if not y then
    _endtime_cache[str] = 0
    return 0
  end
  local dt = {
    year = tonumber(y),
    month = tonumber(m),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s)
  }
  local ts_local = os.time(dt)
  local utc_t = os.date("!*t", ts_local)
  local ts_utc = os.time(utc_t)
  local tz_offset = ts_local - ts_utc
  local ts = ts_local + tz_offset
  _endtime_cache[str] = ts
  return ts
end

function curio_emporium_module:format_remain_time(remain_seconds)
  if remain_seconds <= 0 then
    return UIUtil.get_text_by_id("Curio_Emporium_Good_Time3", 0)
  end
  if remain_seconds >= SECONDS_PER_DAY then
    local days = math.floor(remain_seconds / SECONDS_PER_DAY)
    local hours = math.floor(remain_seconds % SECONDS_PER_DAY / SECONDS_PER_HOUR)
    return UIUtil.get_text_by_id("Curio_Emporium_Good_Time1", days, hours)
  elseif remain_seconds >= SECONDS_PER_HOUR then
    local hours = math.floor(remain_seconds / SECONDS_PER_HOUR)
    return UIUtil.get_text_by_id("Curio_Emporium_Good_Time2", hours)
  else
    local minutes = math.floor(remain_seconds / SECONDS_PER_MINUTE)
    if minutes < 1 then
      minutes = 1
    end
    return UIUtil.get_text_by_id("Curio_Emporium_Good_Time3", minutes)
  end
end

function curio_emporium_module:get_left_game_days(end_timestamp, now_timestamp)
  local end_time = tonumber(end_timestamp) or 0
  local now = tonumber(now_timestamp) or tonumber(TimeUtil.ServerUtcTimeSeconds) or 0
  if end_time <= now then
    return 0
  end
  local current_game_day = tonumber(TimeUtil.GetUtcGameDayStamp(now)) or 0
  local last_valid_game_day = tonumber(TimeUtil.GetUtcGameDayStamp(end_time - 1)) or 0
  return math.max(0, last_valid_game_day - current_game_day + 1)
end

function curio_emporium_module:get_left_month_card_reward_days(end_timestamp, now_timestamp)
  local left_game_days = self:get_left_game_days(end_timestamp, now_timestamp)
  return math.max(0, left_game_days - 1)
end

local VIP_CARD_CFG_ID = 1
local MONTH_CARD_WARNING_DAYS = 7
local MONTH_CARD_LIMIT_TIP_TEXT_ID = "Monthly_Card_Unlimited_Day_Tip"
local month_card_warning_text_format = "<style=TextWarning_Light>%s</style>"

function curio_emporium_module:is_month_card_gift(cfg)
  return not_null(cfg) and cfg.monthcardtag == 1
end

function curio_emporium_module:get_next_month_card_time_change()
  local now = TimeUtil.ServerUtcTimeSeconds
  local next_time
  for _, cfg in pairs(self:get_all_gift_cfg() or {}) do
    if self:is_month_card_gift(cfg) then
      local start_time = self:parse_endtime(cfg.starttime)
      if now < start_time and (not next_time or next_time > start_time) then
        next_time = start_time
      end
      local end_time = self:parse_endtime(cfg.endtime)
      if now < end_time and (not next_time or next_time > end_time) then
        next_time = end_time
      end
    end
  end
  return next_time
end

function curio_emporium_module:is_month_card_unlock_condition(condition_id)
  if not condition_id or condition_id <= 0 then
    return false
  end
  for _, cfg in pairs(self:get_all_gift_cfg() or {}) do
    if self:is_month_card_gift(cfg) and (cfg.unlockopenstateconfigid or 0) == condition_id then
      return true
    end
  end
  return false
end

function curio_emporium_module:get_vip_card_cfg()
  return ExcelDataUtil.get_value(typeof(BVipCardCfg), VIP_CARD_CFG_ID)
end

function curio_emporium_module:get_month_card_state()
  local valid_until = tonumber(CsGameStoreModuleUtil.GetVipCardValidUntil()) or 0
  local now = tonumber(TimeUtil.ServerUtcTimeSeconds) or 0
  return valid_until > now, self:get_left_month_card_reward_days(valid_until, now)
end

function curio_emporium_module:get_month_card_left_days_text(left_days)
  local days_text = tostring(left_days)
  if left_days <= MONTH_CARD_WARNING_DAYS then
    days_text = string.format(month_card_warning_text_format, days_text)
  end
  return days_text
end

function curio_emporium_module:_is_month_card_day_limit_exceeded()
  local vip_card_cfg = self:get_vip_card_cfg()
  if is_null(vip_card_cfg) then
    return true
  end
  local valid_until = tonumber(CsGameStoreModuleUtil.GetVipCardValidUntil()) or 0
  local left_days = self:get_left_game_days(valid_until)
  local card_grant_days = tonumber(vip_card_cfg.cardgrantdays) or 0
  local max_card_days = tonumber(vip_card_cfg.maxcarddays) or 0
  return left_days > max_card_days - card_grant_days
end

function curio_emporium_module:try_block_month_card_day_limit_with_tip()
  if not self:_is_month_card_day_limit_exceeded() then
    return false
  end
  UIUtil.show_tips_by_text_id(MONTH_CARD_LIMIT_TIP_TEXT_ID)
  return true
end

function curio_emporium_module:is_gift_item(item_id)
  if not item_id or item_id <= 0 then
    return false
  end
  return item_module:check_tag(item_id, nil, EntityTagTags.Tags.specialitem_autoclaimgiftpack)
end

function curio_emporium_module:get_gift_item_list(gift_cfg_id)
  if not gift_cfg_id or gift_cfg_id <= 0 then
    return {}
  end
  local sub_table = ExcelDataUtil.get_value(typeof(BCurioShopGiftItemCfg), gift_cfg_id)
  if not sub_table then
    return {}
  end
  local items = {}
  if type(sub_table) == "userdata" then
    local list = list_to_table(sub_table)
    for _, row in ipairs(list) do
      items[#items + 1] = {
        config_id = row.itemid,
        num = row.num or 1
      }
    end
  else
    for _, row in pairs(sub_table) do
      items[#items + 1] = {
        config_id = row.itemid,
        num = row.num or 1
      }
    end
  end
  return items
end

function curio_emporium_module:get_gift_cfg(gift_id)
  if not gift_id or gift_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BCurioShopGiftCfg), gift_id)
end

function curio_emporium_module:get_gift_item_cfgs(gift_id)
  if not gift_id or gift_id <= 0 then
    return {}
  end
  local sub_table = ExcelDataUtil.get_value(typeof(BCurioShopGiftItemCfg), gift_id)
  if not sub_table then
    return {}
  end
  local rows = {}
  if type(sub_table) == "userdata" then
    local list = list_to_table(sub_table)
    for _, row in ipairs(list) do
      rows[#rows + 1] = row
    end
  else
    for _, row in pairs(sub_table) do
      rows[#rows + 1] = row
    end
  end
  table.sort(rows, function(a, b)
    return a.itemid < b.itemid
  end)
  return rows
end

function curio_emporium_module:get_gift_item_grouped_by_tag(gift_id)
  if not gift_id or gift_id <= 0 then
    return {}
  end
  local sub_table = ExcelDataUtil.get_value(typeof(BCurioShopGiftItemCfg), gift_id)
  if not sub_table then
    return {}
  end
  local rows = {}
  if type(sub_table) == "userdata" then
    local list = list_to_table(sub_table)
    for _, row in ipairs(list) do
      rows[#rows + 1] = row
    end
  else
    for _, row in pairs(sub_table) do
      rows[#rows + 1] = row
    end
  end
  local tag_map = {}
  for _, row in ipairs(rows) do
    local tag = row.tag or 0
    if not tag_map[tag] then
      tag_map[tag] = {}
    end
    table.insert(tag_map[tag], row)
  end
  for _, list in pairs(tag_map) do
    table.sort(list, function(a, b)
      return a.itemid < b.itemid
    end)
  end
  local groups = {}
  for tag, list in pairs(tag_map) do
    table.insert(groups, {tag = tag, items = list})
  end
  table.sort(groups, function(a, b)
    return a.tag < b.tag
  end)
  return groups
end

function curio_emporium_module:show_purchase_reward(gift_id, buy_num)
  if not gift_id or gift_id <= 0 then
    return
  end
  local num_multiplier = buy_num and 1 < buy_num and buy_num or 1
  local reward_items = {}
  local items = self:get_gift_item_list(gift_id)
  if items and 0 < #items then
    for _, entry in ipairs(items) do
      reward_items[#reward_items + 1] = {
        id = entry.config_id,
        num = (entry.num or 1) * num_multiplier
      }
    end
  else
    reward_items[#reward_items + 1] = {id = gift_id, num = num_multiplier}
  end
  local title = item_module:get_item_name_by_id(gift_id) or ""
  common_ui_module:show_reward_dialog(title, nil, reward_items)
end

function curio_emporium_module:show_top_up_reward(goods_data, title)
  if not goods_data or is_null(goods_data.virtualCurrency) then
    return
  end
  local vc = goods_data.virtualCurrency
  local total = (vc.count or 0) + (vc.countBonus or 0)
  if total <= 0 then
    return
  end
  common_ui_module:show_reward_dialog(title, nil, {
    {
      id = self.top_up_currency_id,
      num = total
    }
  })
end

function curio_emporium_module:is_suit_auto_claim_gift(gift_id)
  if not gift_id or gift_id <= 0 then
    return false
  end
  return item_module:check_tag(gift_id, nil, EntityTagTags.Tags.specialitem_autoclaimgiftpack_suitautoclaimgiftpack)
end

function curio_emporium_module:split_suit_gift_items(gift_id)
  local result = {
    cloth_ids = {},
    style_color_list = {},
    other_items = {}
  }
  local items = self:get_gift_item_list(gift_id)
  if not items or #items <= 0 then
    return result
  end
  result = self:split_suit_gift_items_handle(result, items)
  return result
end

function curio_emporium_module:split_suit_gift_items_handle(result, items)
  local style_cards = {}
  local color_cards = {}
  local type_to_style = {}
  local STYLE_UNLOCK_TYPE_HAIR = 4
  local STYLE_UNLOCK_TYPE_EYES = 5
  local STYLE_UNLOCK_TYPE_EYEBROW = 7
  for _, entry in ipairs(items) do
    local item_id = entry.config_id
    local style_unlock_type
    if item_module:is_hair(item_id) then
      style_unlock_type = STYLE_UNLOCK_TYPE_HAIR
    elseif item_module:is_eyes(item_id) then
      style_unlock_type = STYLE_UNLOCK_TYPE_EYES
    elseif item_module:is_eyebrow(item_id) then
      style_unlock_type = STYLE_UNLOCK_TYPE_EYEBROW
    end
    if style_unlock_type or item_module:is_skin(item_id) then
      table.insert(result.style_color_list, {style_id = item_id})
      if style_unlock_type then
        type_to_style[style_unlock_type] = item_id
      end
    elseif item_module:is_clothing(item_id) then
      table.insert(result.cloth_ids, item_id)
    elseif item_module:is_unlock_appearance_card(item_id) then
      local unlock_cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), item_id)
      if not_null(unlock_cfg) then
        if unlock_cfg.styleid > 0 then
          table.insert(style_cards, {cfg = unlock_cfg, item_id = item_id})
          type_to_style[unlock_cfg.unlocktype] = unlock_cfg.styleid
        else
          table.insert(color_cards, {cfg = unlock_cfg, item_id = item_id})
        end
      else
        table.insert(result.other_items, entry)
      end
    else
      table.insert(result.other_items, entry)
    end
  end
  for _, s in ipairs(style_cards) do
    table.insert(result.style_color_list, {
      style_id = s.cfg.styleid
    })
  end
  local color_to_style_type = {
    [2] = STYLE_UNLOCK_TYPE_HAIR,
    [3] = STYLE_UNLOCK_TYPE_EYES,
    [6] = STYLE_UNLOCK_TYPE_EYEBROW
  }
  for _, c in ipairs(color_cards) do
    local style_type = color_to_style_type[c.cfg.unlocktype]
    local paired_style_id = style_type and type_to_style[style_type] or nil
    if not paired_style_id then
      for _, sid in pairs(type_to_style) do
        paired_style_id = sid
        break
      end
    end
    local color_block_id
    local group_str = c.cfg.colorgroupid
    if group_str then
      local group_id = tonumber(group_str)
      if group_id and 0 < group_id then
        local block_ids = CsDyeingModuleUtil.GetColorBlockIdsByGroupId(group_id)
        if not_null(block_ids) and 0 < block_ids.Count then
          color_block_id = block_ids[0]
        end
      end
    end
    if paired_style_id and color_block_id then
      table.insert(result.style_color_list, {
        style_id = paired_style_id,
        color_id = color_block_id,
        area_id = 1
      })
    else
      table.insert(result.other_items, {
        config_id = c.item_id,
        num = 1
      })
    end
  end
  return result
end

local HOT_SALE_GIFT_TYPE = 3

function curio_emporium_module:is_hot_sale_unlock_condition(condition_id)
  return self:is_gift_unlock_condition(HOT_SALE_GIFT_TYPE, condition_id)
end

function curio_emporium_module:_invalidate_hot_sale_red_point_cache()
  self._hot_sale_red_point_cache = nil
  self._hot_sale_red_point_cache_expire_time = nil
  if self._hot_sale_red_point_timer then
    CsTimerManagerUtil.StopTimer(self._hot_sale_red_point_timer)
    self._hot_sale_red_point_timer = nil
  end
end

function curio_emporium_module:schedule_hot_sale_red_point_cache_expire(expire_time)
  if not expire_time then
    return
  end
  if self._hot_sale_red_point_timer then
    CsTimerManagerUtil.StopTimer(self._hot_sale_red_point_timer)
    self._hot_sale_red_point_timer = nil
  end
  local delay = expire_time - TimeUtil.ServerUtcTimeSeconds
  if delay <= 0 then
    return
  end
  self._hot_sale_red_point_timer = CsTimerManagerUtil.StartTimer(delay, function()
    self._hot_sale_red_point_timer = nil
    self._hot_sale_red_point_cache = nil
    self._hot_sale_red_point_cache_expire_time = nil
    EventCenter.Broadcast(EventID.LuaRefreshCurioEmporiumRedPoint, nil)
  end)
end

function curio_emporium_module:invalidate_hot_sale_red_point_by_unlock_condition(condition_id)
  if not self:is_hot_sale_unlock_condition(condition_id) then
    return false
  end
  self:_invalidate_hot_sale_red_point_cache()
  EventCenter.Broadcast(EventID.LuaRefreshCurioEmporiumRedPoint, nil)
  return true
end

function curio_emporium_module:_ensure_shown_gift_set()
  if self._shown_gift_set then
    return
  end
  self._shown_gift_set = {}
  local raw = CsLocalSaveDataUtil.GetString(LocalSaveID.CurioShopHotSaleShownGiftIds, "")
  if raw and raw ~= "" then
    for id_str in string.gmatch(raw, "[^,]+") do
      local id = tonumber(id_str)
      if id then
        self._shown_gift_set[id] = true
      end
    end
  end
end

function curio_emporium_module:_save_shown_gift_set()
  local ids = {}
  for id in pairs(self._shown_gift_set) do
    ids[#ids + 1] = tostring(id)
  end
  CsLocalSaveDataUtil.SetString(LocalSaveID.CurioShopHotSaleShownGiftIds, table.concat(ids, ","))
end

function curio_emporium_module:mark_gift_shown(gift_id)
  if not gift_id or gift_id <= 0 then
    return
  end
  self:_ensure_shown_gift_set()
  if self._shown_gift_set[gift_id] then
    return
  end
  self._shown_gift_set[gift_id] = true
  self:_invalidate_hot_sale_red_point_cache()
  self:_save_shown_gift_set()
end

function curio_emporium_module:clear_shown_gift_set()
  self._shown_gift_set = {}
  self:_invalidate_hot_sale_red_point_cache()
  CsLocalSaveDataUtil.SetString(LocalSaveID.CurioShopHotSaleShownGiftIds, "")
end

function curio_emporium_module:is_gift_shown(gift_id)
  if not gift_id or gift_id <= 0 then
    return true
  end
  self:_ensure_shown_gift_set()
  return self._shown_gift_set[gift_id] == true
end

function curio_emporium_module:get_gift_red_point_type(gift_id)
  if self:is_gift_shown(gift_id) then
    return RedPointType.None
  end
  return RedPointType.NewRp
end

function curio_emporium_module:get_hot_sale_panel_red_point_type()
  local now = TimeUtil.ServerUtcTimeSeconds
  if self._hot_sale_red_point_cache ~= nil then
    local expire_time = self._hot_sale_red_point_cache_expire_time
    if not expire_time or now < expire_time then
      return self._hot_sale_red_point_cache
    end
    self:_invalidate_hot_sale_red_point_cache()
  end
  self:_ensure_shown_gift_set()
  local result = RedPointType.None
  local next_change_time
  if self._gift_cfg_by_type == nil then
    self:init_gift_cfg()
  end
  local cfg_by_type = self._gift_cfg_by_type or {}
  local cfgs = cfg_by_type[HOT_SALE_GIFT_TYPE] or {}
  local shown_gift_set = self._shown_gift_set or {}
  for _, cfg in ipairs(cfgs) do
    if not shown_gift_set[cfg.id] and self:is_gift_unlocked(cfg) and not self:is_gift_ended(cfg) and not self:is_gift_blocked_by_tag_emergency_switch(cfg) then
      local start_time = self:parse_endtime(cfg.starttime)
      if start_time <= 0 or now >= start_time then
        result = RedPointType.NewRp
        local end_time = self:parse_endtime(cfg.endtime)
        if now < end_time and (not next_change_time or next_change_time > end_time) then
          next_change_time = end_time
        end
      elseif not next_change_time or start_time < next_change_time then
        next_change_time = start_time
      end
    end
  end
  self._hot_sale_red_point_cache = result
  self._hot_sale_red_point_cache_expire_time = next_change_time
  self:schedule_hot_sale_red_point_cache_expire(next_change_time)
  return result
end

function curio_emporium_module:get_tag_red_point_type(tag_id)
  if tag_id == self.entrance_tag_type.hot_sale then
    return self:get_hot_sale_panel_red_point_type()
  end
  return RedPointType.None
end

function curio_emporium_module:get_curio_emporium_red_point_type()
  return self:get_hot_sale_panel_red_point_type()
end

function curio_emporium_module:open_curio_emporium_page(first_recharge_tag_id, close_callback)
  if self:try_block_store_with_tip() then
    return false
  end
  if first_recharge_tag_id == self.entrance_tag_type.top_up_mall and self:try_block_recharge_with_tip() then
    return false
  end
  UIManagerInstance:open("UI/CurioEmporium/EntrancePage/CurioEmporiumEntrancePage", {first_recharge_tag_id = first_recharge_tag_id, close_callback = close_callback})
  return true
end

function curio_emporium_module:open_item_details_page(gift_id)
  if self:try_block_store_with_tip() then
    return
  end
  UIManagerInstance:open("UI/CurioEmporium/DetailPage/CurioEmporiumItemDetailsPage", {gift_id = gift_id})
end

function curio_emporium_module:open_daily_reward_dialog()
  if self:try_block_store_with_tip() then
    CsGameStoreModuleUtil.ClearDailyRewardNotify()
    return
  end
  UIManagerInstance:open("UI/CurioEmporium/DailyReward/PassDailyRewardDialog", {})
end

return curio_emporium_module
