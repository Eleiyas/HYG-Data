spring_festival_coin_shop_module = spring_festival_coin_shop_module or {}
local M = spring_festival_coin_shop_module
local COIN_SHOP_DEBUG = false

local function _log_coin_shop(msg)
  if not COIN_SHOP_DEBUG then
    return
  end
  Logger.Log("[SpringFestivalCoinShopData] " .. tostring(msg))
end

local function _get_coin_cfg_table()
  local coin_cfg_type = CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BCoinStoreCfg
  if coin_cfg_type == nil then
    Logger.LogWarning("[SpringFestivalCoinShopData] BCoinStoreCfg type is nil")
    return {}
  end
  return ExcelDataUtil.get_table(typeof(coin_cfg_type)) or {}
end

local function _get_coin_tab_icon(coin_cfg)
  if coin_cfg == nil then
    return ""
  end
  return coin_cfg.icon or ""
end

local function _get_coin_tab_name(coin_cfg)
  if coin_cfg == nil then
    return ""
  end
  return coin_cfg.pagename or ""
end

local function _get_coin_tab_display_title(coin_cfg)
  if coin_cfg == nil then
    return ""
  end
  return coin_cfg.tabname or ""
end

local _group_to_pagetype_cache

local function _build_group_to_pagetype()
  if _group_to_pagetype_cache ~= nil then
    return _group_to_pagetype_cache
  end
  local map = {}
  for _, cfg in ipairs(_get_coin_cfg_table()) do
    local group_id = cfg.storegroupid or 0
    local page_type = cfg.pagetype or 0
    if 0 < group_id and 0 < page_type then
      map[group_id] = page_type
    end
  end
  _group_to_pagetype_cache = map
  return map
end

local function _get_page_type_by_group_id(group_id)
  if (group_id or 0) <= 0 then
    return 0
  end
  return _build_group_to_pagetype()[group_id] or 0
end

function M:is_gacha_box(item_id)
  item_id = tonumber(item_id) or 0
  if item_id <= 0 then
    return false
  end
  local cfg = ExcelDataUtil.get_value(typeof(BItemUseCfg), item_id)
  return cfg ~= nil and cfg.effecttype == "ITEM_USE_EFFECT_OPEN_RANDOM_BOX"
end

local function _now_utc()
  local now = tonumber(TimeUtil.ServerUtcTimeSeconds) or 0
  if now <= 0 then
    now = os.time()
  end
  return now
end

local function _fmt_utc_ts(ts)
  ts = tonumber(ts) or 0
  if ts <= 0 then
    return "<0>"
  end
  return string.format("UTC=%s | CST=%s", os.date("!%Y-%m-%d %H:%M:%S", ts), os.date("!%Y-%m-%d %H:%M:%S", ts + 28800))
end

local function _calc_remain_seconds(unlock_timestamp)
  unlock_timestamp = tonumber(unlock_timestamp) or 0
  if unlock_timestamp <= 0 then
    return 0
  end
  local remain = unlock_timestamp - _now_utc()
  if remain <= 0 then
    return 0
  end
  return remain
end

function M:calc_remain_seconds_by_ts(unlock_ts)
  return _calc_remain_seconds(unlock_ts)
end

local function _calc_daily_unlock_mode(unlock_ts)
  unlock_ts = tonumber(unlock_ts) or 0
  if unlock_ts <= 0 then
    return "countdown", 0, 0
  end
  local now_local_date = TimeUtil.ServerLocalTime.Date
  local unlock_local = TimeUtil.ChangeServerUtcTimeToServerLocalTime(unlock_ts)
  local unlock_local_date = unlock_local.Date
  local diff = math.floor(tonumber(unlock_local_date:Subtract(now_local_date).TotalDays) or 0)
  local month = tonumber(unlock_local.Month) or 0
  local day = tonumber(unlock_local.Day) or 0
  if diff <= 0 then
    return "countdown", month, day
  elseif diff == 1 then
    return "tomorrow", month, day
  end
  return "date", month, day
end

function M:calc_daily_unlock_mode_by_ts(unlock_ts)
  return _calc_daily_unlock_mode(unlock_ts)
end

local function _calc_remain_buy_num(coin_goods)
  local daily_limit = coin_goods.daily_limit or 0
  if 0 < daily_limit then
    return math.max(0, coin_goods.daily_remain or 0)
  end
  local permanent_limit = coin_goods.permanent_limit or 0
  if 0 < permanent_limit then
    return math.max(0, permanent_limit - (coin_goods.total_buy_num or 0))
  end
  return -1
end

local function _calc_red_point_type(goods)
  if (goods.price or 0) ~= 0 then
    return RedPointType.None
  end
  if 0 >= (goods.remain_buy_num or 0) then
    return RedPointType.None
  end
  if goods.is_initial_locked == true or goods.is_daily_sold_out == true then
    return RedPointType.None
  end
  return RedPointType.StrongRP
end

local function _pack_coin_goods(index)
  local goods_id = CsSpringFestivalModuleUtil.GetCoinShopGoodsIdByIndex(index) or 0
  if goods_id <= 0 then
    return nil
  end
  local goods = {
    goods_id = goods_id,
    price = CsSpringFestivalModuleUtil.GetCoinShopGoodsPriceByIndex(index) or 0,
    is_unlocked = CsSpringFestivalModuleUtil.GetCoinShopGoodsIsUnlockedByIndex(index) or false,
    unlock_timestamp = CsSpringFestivalModuleUtil.GetCoinShopGoodsUnlockTimestampByIndex(index) or 0,
    daily_limit = CsSpringFestivalModuleUtil.GetCoinShopGoodsDailyLimitByIndex(index) or 0,
    today_buy_num = CsSpringFestivalModuleUtil.GetCoinShopGoodsTodayBuyNumByIndex(index) or 0,
    daily_remain = CsSpringFestivalModuleUtil.GetCoinShopGoodsDailyRemainByIndex(index) or 0,
    permanent_limit = CsSpringFestivalModuleUtil.GetCoinShopGoodsPermanentLimitByIndex(index) or 0,
    total_buy_num = CsSpringFestivalModuleUtil.GetCoinShopGoodsTotalBuyNumByIndex(index) or 0,
    is_activity_last_day = CsSpringFestivalModuleUtil.GetCoinShopGoodsIsActivityLastDayByIndex(index) or false
  }
  return goods
end

function M:get_coin_shop_goods_list()
  local result = {}
  local count = CsSpringFestivalModuleUtil.GetCoinShopGoodsCount() or 0
  local now_utc = _now_utc()
  _log_coin_shop(string.format("GetCoinShopGoodsCount=%d now_utc=%d (%s) os.time=%d", count, now_utc, _fmt_utc_ts(now_utc), os.time()))
  for i = 1, count do
    local index = i - 1
    local coin_goods = _pack_coin_goods(index)
    if coin_goods ~= nil then
      local store_cfg = ExcelDataUtil.get_value(typeof(BStoreCfg), coin_goods.goods_id)
      if store_cfg == nil then
        _log_coin_shop(string.format("skip goods_id=%d: BStoreCfg missing", coin_goods.goods_id))
      else
        local item_id = store_cfg.itemid or 0
        local group_id = store_cfg.groupid or 0
        local money_type = store_cfg.moneytype or 0
        local money_id = 0 < money_type and (item_module.money_type[money_type] or 0) or 0
        local cfg_index = store_cfg.index or 0
        local limit_type = store_cfg.limittype or 0
        local limit_per_purchase = math.max(0, math.floor(tonumber(store_cfg.limitperpurchase) or 0))
        local is_limit_show = (store_cfg.islimitshow or 0) == 1
        local page_type = _get_page_type_by_group_id(group_id)
        local remain_buy_num = _calc_remain_buy_num(coin_goods)
        local is_daily_limit = 0 < (coin_goods.daily_limit or 0)
        local avail_count = 0
        if is_daily_limit then
          avail_count = coin_goods.daily_limit or 0
        elseif 0 < (coin_goods.permanent_limit or 0) then
          avail_count = coin_goods.permanent_limit or 0
        end
        local is_unlocked = coin_goods.is_unlocked == true
        local is_activity_last_day = coin_goods.is_activity_last_day == true
        local has_daily_limit = 0 < (coin_goods.daily_limit or 0)
        local has_perm_limit = 0 < (coin_goods.permanent_limit or 0)
        local has_unlock_ts = 0 < (tonumber(coin_goods.unlock_timestamp) or 0)
        local daily_exhausted = has_daily_limit and 0 >= (coin_goods.daily_remain or 0) and 0 < (coin_goods.today_buy_num or 0)
        local perm_exhausted = has_perm_limit and (coin_goods.total_buy_num or 0) >= (coin_goods.permanent_limit or 0)
        local no_buy_today = (coin_goods.today_buy_num or 0) == 0
        local is_perm_sold_out = perm_exhausted
        local is_daily_sold_out = not is_unlocked and not is_perm_sold_out and not is_activity_last_day and daily_exhausted
        local is_initial_locked = not is_unlocked and not is_perm_sold_out and not is_daily_sold_out and not is_activity_last_day and no_buy_today and has_unlock_ts
        local lock_remain_seconds = 0
        if is_daily_sold_out or is_initial_locked then
          lock_remain_seconds = _calc_remain_seconds(coin_goods.unlock_timestamp)
        end
        local daily_unlock_mode, unlock_month, unlock_day = "countdown", 0, 0
        if is_daily_sold_out then
          daily_unlock_mode, unlock_month, unlock_day = _calc_daily_unlock_mode(coin_goods.unlock_timestamp)
        end
        local activity_end_remain_seconds = is_activity_last_day and _calc_remain_seconds(coin_goods.unlock_timestamp) or 0
        _log_coin_shop(string.format("goods_id=%d price=%d item_id=%d group_id=%d page_type=%d money_id=%d idx=%d limit_type=%d " .. "is_unlocked=%s unlock_ts=%d (%s) " .. "daily_limit=%d daily_remain=%d perm_limit=%d today_buy=%d total_buy=%d " .. "remain=%d unlocked=%s(remain_seconds=%d,daily_sold_out=%s,initial=%s) last_day=%s(end_s=%d)", coin_goods.goods_id, coin_goods.price, item_id, group_id, page_type, money_id, cfg_index, limit_type, tostring(coin_goods.is_unlocked), tonumber(coin_goods.unlock_timestamp) or 0, _fmt_utc_ts(coin_goods.unlock_timestamp), coin_goods.daily_limit or 0, coin_goods.daily_remain or 0, coin_goods.permanent_limit or 0, coin_goods.today_buy_num or 0, coin_goods.total_buy_num or 0, remain_buy_num, tostring(is_unlocked), lock_remain_seconds, tostring(is_daily_sold_out), tostring(is_initial_locked), tostring(is_activity_last_day), activity_end_remain_seconds))
        local goods_data = {
          goods_id = coin_goods.goods_id,
          price = coin_goods.price or 0,
          item_id = item_id,
          group_id = group_id,
          page_type = page_type,
          money_id = money_id,
          sort_index = cfg_index,
          avail_count = avail_count,
          limit_type = limit_type,
          limit_per_purchase = limit_per_purchase,
          is_limit_show = is_limit_show,
          is_daily_limit = is_daily_limit,
          today_buy_num = coin_goods.today_buy_num or 0,
          total_buy_num = coin_goods.total_buy_num or 0,
          remain_buy_num = remain_buy_num,
          is_unlocked = is_unlocked,
          is_daily_sold_out = is_daily_sold_out,
          is_initial_locked = is_initial_locked,
          lock_current = 0,
          lock_target = 0,
          unlock_timestamp = tonumber(coin_goods.unlock_timestamp) or 0,
          lock_remain_seconds = lock_remain_seconds,
          is_activity_last_day = is_activity_last_day,
          activity_end_remain_seconds = activity_end_remain_seconds,
          daily_unlock_mode = daily_unlock_mode,
          unlock_month = unlock_month,
          unlock_day = unlock_day
        }
        goods_data.red_point_type = _calc_red_point_type(goods_data)
        table.insert(result, goods_data)
      end
    end
  end
  table.sort(result, function(a, b)
    local ai = a.sort_index or 0
    local bi = b.sort_index or 0
    if ai ~= bi then
      return ai < bi
    end
    return (a.goods_id or 0) < (b.goods_id or 0)
  end)
  _log_coin_shop(string.format("goods_list_built=%d", #result))
  return result
end

function M:get_coin_tab_configs(goods_list, cur_tab_id)
  goods_list = goods_list or {}
  local page_type_set = {}
  local page_type_has_red_point = {}
  for _, goods in ipairs(goods_list) do
    local page_type = goods.page_type or 0
    if 0 < page_type then
      page_type_set[page_type] = true
      if (goods.red_point_type or RedPointType.None) ~= RedPointType.None then
        page_type_has_red_point[page_type] = true
      end
    end
  end
  local tab_by_page_type = {}
  local coin_cfgs = _get_coin_cfg_table()
  for _, coin_cfg in ipairs(coin_cfgs) do
    local page_type = coin_cfg.pagetype or 0
    if 0 < page_type and page_type_set[page_type] then
      local cfg = tab_by_page_type[page_type]
      if cfg == nil then
        cfg = {
          id = page_type,
          name = _get_coin_tab_name(coin_cfg),
          tab_name = _get_coin_tab_display_title(coin_cfg),
          icon = _get_coin_tab_icon(coin_cfg),
          sort_index = coin_cfg.id or 0,
          red_point_type = page_type_has_red_point[page_type] and RedPointType.StrongRP or RedPointType.None
        }
        tab_by_page_type[page_type] = cfg
      else
        cfg.sort_index = math.min(cfg.sort_index or 0, coin_cfg.id or 0)
        if not string.is_valid(cfg.name) then
          cfg.name = _get_coin_tab_name(coin_cfg)
        end
        if not string.is_valid(cfg.tab_name) then
          cfg.tab_name = _get_coin_tab_display_title(coin_cfg)
        end
        if not string.is_valid(cfg.icon) then
          cfg.icon = _get_coin_tab_icon(coin_cfg)
        end
      end
    end
  end
  local dynamic_tabs = {}
  for _, cfg in pairs(tab_by_page_type) do
    table.insert(dynamic_tabs, cfg)
  end
  table.sort(dynamic_tabs, function(a, b)
    local ai = a.sort_index or 0
    local bi = b.sort_index or 0
    if ai ~= bi then
      return ai < bi
    end
    return (a.id or 0) < (b.id or 0)
  end)
  local next_tab_id = tonumber(cur_tab_id) or 0
  if next_tab_id <= 0 or not page_type_set[next_tab_id] then
    local first_tab = dynamic_tabs[1]
    next_tab_id = first_tab and (first_tab.id or 0) or 0
  end
  return dynamic_tabs, next_tab_id
end

function M:get_coin_groups_by_page_type(page_type)
  page_type = tonumber(page_type) or 0
  if page_type <= 0 then
    return {}
  end
  local result = {}
  local seen = {}
  for _, coin_cfg in ipairs(_get_coin_cfg_table()) do
    if (coin_cfg.pagetype or 0) == page_type then
      local gid = coin_cfg.storegroupid or 0
      if 0 < gid and not seen[gid] then
        seen[gid] = true
        table.insert(result, {
          group_id = gid,
          tab_name = _get_coin_tab_display_title(coin_cfg),
          sort_index = coin_cfg.id or 0
        })
      end
    end
  end
  table.sort(result, function(a, b)
    return (a.sort_index or 0) < (b.sort_index or 0)
  end)
  return result
end

function M:get_coin_balance()
  return CsSpringFestivalModuleUtil.GetCoinShopBalance() or 0
end

function M:get_coin_item_id()
  if self._coin_item_id_cache ~= nil and self._coin_item_id_cache > 0 then
    return self._coin_item_id_cache
  end
  local fallback_id = VirtualItemType.VirtualItemGold
  local count = CsSpringFestivalModuleUtil.GetCoinShopGoodsCount() or 0
  for i = 0, count - 1 do
    local goods_id = CsSpringFestivalModuleUtil.GetCoinShopGoodsIdByIndex(i) or 0
    if 0 < goods_id then
      local store_cfg = ExcelDataUtil.get_value(typeof(BStoreCfg), goods_id)
      local money_type = store_cfg and store_cfg.moneytype or 0
      local mapped_id = 0 < money_type and item_module.money_type[money_type] or nil
      if mapped_id ~= nil and 0 < mapped_id then
        self._coin_item_id_cache = mapped_id
        return mapped_id
      end
    end
  end
  self._coin_item_id_cache = fallback_id
  return fallback_id
end

function M:get_coin_icon_path()
  local coin_id = self:get_coin_item_id() or 0
  if coin_id <= 0 then
    return ""
  end
  local item_cfg = item_module ~= nil and item_module.get_cfg_by_id ~= nil and item_module:get_cfg_by_id(coin_id) or nil
  if item_cfg == nil then
    return ""
  end
  return item_cfg.tooltableicon or item_cfg.icon or ""
end

return M
