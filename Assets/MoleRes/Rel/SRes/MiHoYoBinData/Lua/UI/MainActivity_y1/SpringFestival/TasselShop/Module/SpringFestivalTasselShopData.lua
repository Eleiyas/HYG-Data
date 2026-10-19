spring_festival_tassel_shop_module = spring_festival_tassel_shop_module or {}
local M = spring_festival_tassel_shop_module
local TASSEL_SHOP_DEBUG = false
local SHOP_SALE_CONDITION_TRACKER_GOAL_DONE = "SHOP_SALE_CONDITION_TRACKER_GOAL_DONE"

local function _log_tassel_shop(msg)
  if not TASSEL_SHOP_DEBUG then
    return
  end
  Logger.Log("[SpringFestivalTasselShopData] " .. tostring(msg))
end

local function _get_tassel_cfg_table()
  local tassel_cfg_type = CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BTasselStoreCfg
  if tassel_cfg_type == nil then
    Logger.LogWarning("[SpringFestivalTasselShopData] BTasselStoreCfg type is nil")
    return {}
  end
  return ExcelDataUtil.get_table(typeof(tassel_cfg_type)) or {}
end

local function _get_tassel_tab_icon(tassel_cfg)
  if tassel_cfg == nil then
    return ""
  end
  return tassel_cfg.icon or tassel_cfg.iconpath or tassel_cfg.effectregionlist or ""
end

local function _get_tassel_tab_name(tassel_cfg)
  if tassel_cfg == nil then
    return ""
  end
  return tassel_cfg.pagename or tassel_cfg.page_name or tassel_cfg.name or ""
end

local function _parse_sale_condition_params(raw)
  if not string.is_valid(raw) then
    return nil, nil
  end
  local tracker_str, index_str = string.match(raw, "^%s*([^,]+)%s*,%s*([^,]+)%s*$")
  local tracker_id = tonumber(tracker_str)
  local progress_index = tonumber(index_str)
  if tracker_id == nil then
    return nil, nil
  end
  return tracker_id, progress_index or 0
end

function M:is_gacha_box(item_id)
  item_id = tonumber(item_id) or 0
  if item_id <= 0 then
    return false
  end
  local cfg = ExcelDataUtil.get_value(typeof(BItemUseCfg), item_id)
  return cfg ~= nil and cfg.effecttype == "ITEM_USE_EFFECT_OPEN_RANDOM_BOX"
end

function M:get_goods_lock_tracker_ids(goods_id)
  goods_id = tonumber(goods_id) or 0
  if goods_id <= 0 then
    return {}
  end
  local cfg = ExcelDataUtil.get_value(typeof(BStoreCfg), goods_id)
  if cfg == nil or cfg.saleconditiontype ~= SHOP_SALE_CONDITION_TRACKER_GOAL_DONE then
    return {}
  end
  local tracker_id = _parse_sale_condition_params(cfg.saleconditionparams)
  if tracker_id == nil or tracker_id <= 0 then
    return {}
  end
  local tracker_ids = list_to_table(CsTrackerModuleUtil.GetTrackerIdListByCfgId(tracker_id))
  if tracker_ids == nil or #tracker_ids <= 0 then
    return {tracker_id}
  end
  return tracker_ids
end

function M:get_store_lock_info(goods_id)
  goods_id = tonumber(goods_id) or 0
  if goods_id <= 0 then
    return false, false, 0, 0, 0
  end
  local cfg = ExcelDataUtil.get_value(typeof(BStoreCfg), goods_id)
  if not cfg or cfg.saleconditiontype ~= SHOP_SALE_CONDITION_TRACKER_GOAL_DONE then
    return false, false, 0, 0, 0
  end
  local tracker_id, progress_index = _parse_sale_condition_params(cfg.saleconditionparams)
  if tracker_id == nil then
    return true, false, 0, 0, 0
  end
  local tracker_ids = self:get_goods_lock_tracker_ids(goods_id)
  if tracker_ids == nil or #tracker_ids <= 0 then
    tracker_ids = {tracker_id}
  end
  local first_current = 0
  local first_target = 0
  local locked_current = 0
  local locked_target = 0
  local has_locked = false
  local has_unlocked = false
  local lock_remain_seconds = 0
  local has_progress_lock_data = false
  for i, real_id in ipairs(tracker_ids) do
    local linked_activity_id = CsTrackerModuleUtil.GetTrackerLinkedActivityIdByCfgId(real_id) or 0
    if 0 < linked_activity_id then
      local activity_data
      if activity_center_module ~= nil and activity_center_module.get_activity_by_id ~= nil then
        activity_data = activity_center_module:get_activity_by_id(linked_activity_id)
      end
      local has_time_range = activity_data ~= nil and activity_data.HasTimeRange == true
      local is_unlocked = false
      local remain_seconds = 0
      if has_time_range then
        local start_utc = tonumber(activity_data.StartTimeUtcSec) or 0
        local now_utc = tonumber(TimeUtil.ServerUtcTimeSeconds) or 0
        if now_utc <= 0 then
          now_utc = os.time()
        end
        remain_seconds = start_utc - now_utc
        if remain_seconds <= 0 then
          is_unlocked = true
          remain_seconds = 0
        end
      end
      if is_unlocked then
        has_unlocked = true
      else
        has_locked = true
        if 0 < remain_seconds and (lock_remain_seconds <= 0 or lock_remain_seconds > remain_seconds) then
          lock_remain_seconds = remain_seconds
        end
      end
    else
      local tracker_cfg = CsTrackerModuleUtil.GetTrackerCfgById(real_id)
      if tracker_cfg ~= nil then
        local progress_list = list_to_table(tracker_cfg.goalprogresslist) or {}
        local target_progress = progress_list[progress_index + 1] or 0
        local tracker_data = CsTrackerModuleUtil.GetTrackerDataByCfgId(real_id)
        local current_progress = 0
        if tracker_data and tracker_data.Condition then
          current_progress = tracker_data.Condition.TriggerCount or 0
        end
        local is_unlocked = 0 < target_progress and target_progress <= current_progress
        if first_target == 0 and 0 < target_progress then
          first_current = current_progress
          first_target = target_progress
        end
        if is_unlocked then
          has_unlocked = true
        else
          has_locked = true
          if not has_progress_lock_data then
            locked_current = current_progress
            locked_target = target_progress
            has_progress_lock_data = true
          end
        end
      end
    end
  end
  if has_unlocked then
    return true, false, first_current, first_target, 0
  end
  if has_locked then
    return true, true, locked_current, locked_target, lock_remain_seconds
  end
  return true, false, first_current, first_target, 0
end

function M:get_tassel_tab_configs(goods_list, cur_tab_id)
  goods_list = goods_list or {}
  local group_set = {}
  for _, goods in ipairs(goods_list) do
    local group_id = goods.group_id or 0
    if 0 < group_id then
      group_set[group_id] = true
    end
  end
  local tab_by_id = {}
  local tassel_cfgs = _get_tassel_cfg_table()
  for _, tassel_cfg in ipairs(tassel_cfgs) do
    local group_id = tassel_cfg.storegroupid or 0
    if 0 < group_id and group_set[group_id] then
      local cfg = tab_by_id[group_id]
      if cfg == nil then
        cfg = {
          id = group_id,
          name = _get_tassel_tab_name(tassel_cfg),
          icon = _get_tassel_tab_icon(tassel_cfg),
          sort_index = tassel_cfg.id or 0
        }
        tab_by_id[group_id] = cfg
      else
        cfg.sort_index = math.min(cfg.sort_index or 0, tassel_cfg.id or 0)
        if not string.is_valid(cfg.name) then
          cfg.name = _get_tassel_tab_name(tassel_cfg)
        end
        if not string.is_valid(cfg.icon) then
          cfg.icon = _get_tassel_tab_icon(tassel_cfg)
        end
      end
    end
  end
  local dynamic_tabs = {}
  for _, cfg in pairs(tab_by_id) do
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
  if next_tab_id <= 0 then
    local first_tab = dynamic_tabs[1]
    next_tab_id = first_tab and (first_tab.id or 0) or 0
  end
  return dynamic_tabs, next_tab_id
end

function M:get_tassel_shop_goods_list()
  local result = {}
  local added = {}
  local default_money_id = 0
  if spring_festival_exchange_module ~= nil and spring_festival_exchange_module.get_token_item_id ~= nil then
    default_money_id = spring_festival_exchange_module:get_token_item_id() or 0
  end
  
  local function _append_goods(goods_id, price, source_tag, is_from_server)
    goods_id = tonumber(goods_id) or 0
    if goods_id <= 0 or added[goods_id] then
      return
    end
    local store_cfg = ExcelDataUtil.get_value(typeof(BStoreCfg), goods_id)
    if store_cfg == nil then
      return
    end
    local item_id = store_cfg.itemid or 0
    local group_id = store_cfg.groupid or 0
    local money_id = store_cfg.moneyid or 0
    if money_id <= 0 then
      money_id = default_money_id
    end
    local avail_count = store_cfg.availcount or 0
    local cfg_index = store_cfg.index or 0
    local limit_type = store_cfg.limittype or 0
    local limit_per_purchase = math.max(0, math.floor(tonumber(store_cfg.limitperpurchase) or 0))
    local refresh_policy_id = store_cfg.refreshpolicyid or 0
    local is_limit_show = (store_cfg.islimitshow or 0) == 1
    local is_daily_limit = (store_cfg.isignoredailylimit or 0) ~= 1
    local today_buy_num = CsSpringFestivalModuleUtil.GetTasselShopTodayBuyNum(goods_id) or 0
    local total_buy_num = CsSpringFestivalModuleUtil.GetTasselShopTotalBuyNum(goods_id) or 0
    local remain_buy_num = -1
    if refresh_policy_id == 999999 then
      _log_tassel_shop(string.format("[refresh999999] goods_id=%d limittype=%d avail_count=%d today_buy_num=%d total_buy_num=%d", goods_id, limit_type, avail_count, today_buy_num, total_buy_num))
    end
    if limit_type == 1 and 0 < avail_count then
      local used_buy_num = today_buy_num
      if refresh_policy_id == 999999 then
        used_buy_num = total_buy_num
      end
      used_buy_num = tonumber(used_buy_num) or 0
      remain_buy_num = math.floor(math.max(0, avail_count - used_buy_num))
    end
    local has_lock_condition, is_locked, lock_current, lock_target, lock_remain_seconds
    if is_from_server then
      has_lock_condition = false
      is_locked = false
      lock_current = 0
      lock_target = 0
      lock_remain_seconds = 0
    else
      has_lock_condition, is_locked, lock_current, lock_target, lock_remain_seconds = self:get_store_lock_info(goods_id)
    end
    added[goods_id] = true
    _log_tassel_shop(string.format("goods[%s]: goods_id=%d price=%d today_buy_num=%d total_buy_num=%d avail_count=%d remain_buy_num=%d item_id=%d group_id=%d money_id=%d sort_index=%d limittype=%d refreshpolicyid=%d limit_show=%s daily_limit=%s lock=%s/%s(%d/%d) remain_seconds=%d", tostring(source_tag), goods_id, price or 0, today_buy_num, total_buy_num, avail_count, remain_buy_num, item_id, group_id, money_id, cfg_index, limit_type, refresh_policy_id, tostring(is_limit_show), tostring(is_daily_limit), tostring(has_lock_condition), tostring(is_locked), lock_current, lock_target, lock_remain_seconds))
    table.insert(result, {
      goods_id = goods_id,
      price = price or 0,
      today_buy_num = today_buy_num,
      total_buy_num = total_buy_num,
      remain_buy_num = remain_buy_num,
      item_id = item_id,
      group_id = group_id,
      money_id = money_id,
      avail_count = avail_count,
      sort_index = cfg_index,
      limit_type = limit_type,
      limit_per_purchase = limit_per_purchase,
      refresh_policy_id = refresh_policy_id,
      is_limit_show = is_limit_show,
      is_daily_limit = is_daily_limit,
      has_lock_condition = has_lock_condition,
      is_locked = is_locked,
      lock_current = lock_current,
      lock_target = lock_target,
      lock_remain_seconds = lock_remain_seconds
    })
  end
  
  local count = CsSpringFestivalModuleUtil.GetTasselShopGoodsCount() or 0
  _log_tassel_shop(string.format("GetTasselShopGoodsCount=%d", count))
  for i = 1, count do
    local index = i - 1
    local goods_id = CsSpringFestivalModuleUtil.GetTasselShopGoodsIdByIndex(index) or 0
    local price = CsSpringFestivalModuleUtil.GetTasselShopGoodsPriceByIndex(index) or 0
    _append_goods(goods_id, price, string.format("server_%d", index), true)
  end
  local tassel_group_set = {}
  local tassel_cfg_table = _get_tassel_cfg_table()
  for _, tassel_cfg in pairs(tassel_cfg_table) do
    local group_id = tassel_cfg.storegroupid or 0
    if 0 < group_id then
      tassel_group_set[group_id] = true
    end
  end
  local all_store_cfg = ExcelDataUtil.get_table(typeof(BStoreCfg)) or {}
  for goods_id, store_cfg in pairs(all_store_cfg) do
    local group_id = store_cfg.groupid or 0
    if tassel_group_set[group_id] and not added[goods_id] then
      local _, is_locked = self:get_store_lock_info(goods_id)
      if is_locked then
        _append_goods(goods_id, store_cfg.price or 0, "config_locked")
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
  _log_tassel_shop(string.format("goods_list_built=%d", #result))
  return result
end

function M:get_tassel_shop_today_buy_num(goods_id)
  goods_id = tonumber(goods_id) or 0
  if goods_id <= 0 then
    return 0
  end
  return CsSpringFestivalModuleUtil.GetTasselShopTodayBuyNum(goods_id) or 0
end

return M
