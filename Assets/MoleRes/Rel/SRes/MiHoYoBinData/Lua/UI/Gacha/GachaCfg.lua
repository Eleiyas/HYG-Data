gacha_module = gacha_module or {}
local table_insert = table.insert
local EMPTY_TABLE = {}

function gacha_module:get_activity_cfg(gacha_id)
  return ExcelDataUtil.get_value(typeof(BGachaActivityCfg), gacha_id)
end

function gacha_module:get_price_list(price_strategy_id)
  self._price_cache = self._price_cache or {}
  local cached = self._price_cache[price_strategy_id]
  if cached ~= nil then
    return cached
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(BGachaPriceStrategyCfg)) or {}
  local need_cfgs = cfg_dic[price_strategy_id] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return a.index < b.index
  end)
  self._price_cache[price_strategy_id] = list
  return list
end

function gacha_module:get_price(price_strategy_id, index)
  local list = self:get_price_list(price_strategy_id)
  for i = 1, #list do
    if list[i].index == index then
      return list[i]
    end
  end
  return nil
end

function gacha_module:get_pool_cfg_list(gacha_pool_id)
  self._pool_cfg_cache = self._pool_cfg_cache or {}
  local cached = self._pool_cfg_cache[gacha_pool_id]
  if cached ~= nil then
    return cached
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(BGachaPoolCfg)) or {}
  local need_cfgs = cfg_dic[gacha_pool_id] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return a.index < b.index
  end)
  self._pool_cfg_cache[gacha_pool_id] = list
  self._pool_cfg_index_cache = self._pool_cfg_index_cache or {}
  local index_map = {}
  for i = 1, #list do
    index_map[list[i].index] = list[i]
  end
  self._pool_cfg_index_cache[gacha_pool_id] = index_map
  return list
end

function gacha_module:get_pool_cfg(gacha_pool_id, index)
  self:get_pool_cfg_list(gacha_pool_id)
  local map = self._pool_cfg_index_cache and self._pool_cfg_index_cache[gacha_pool_id]
  return map and map[index] or nil
end

function gacha_module:get_pool_cfg_by_item_id(gacha_pool_id, item_id)
  local list = self:get_pool_cfg_list(gacha_pool_id)
  for i = 1, #list do
    if list[i].itemid == item_id then
      return list[i]
    end
  end
  return nil
end

function gacha_module:get_exchange_shop_list(gacha_pool_id)
  self._exchange_cache = self._exchange_cache or {}
  local cached = self._exchange_cache[gacha_pool_id]
  if cached ~= nil then
    return cached
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(BGachaExchangeShopCfg)) or {}
  local need_cfgs = cfg_dic[gacha_pool_id] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    if a.shoptag ~= b.shoptag then
      return a.shoptag < b.shoptag
    end
    return a.index < b.index
  end)
  self._exchange_cache[gacha_pool_id] = list
  return list
end

function gacha_module:get_exchange_shop_cfg(gacha_pool_id, index)
  local list = self:get_exchange_shop_list(gacha_pool_id)
  for i = 1, #list do
    if list[i].index == index then
      return list[i]
    end
  end
  return nil
end

function gacha_module:get_exchange_shop_cfg_by_item_id(gacha_pool_id, item_id)
  local list = self:get_exchange_shop_list(gacha_pool_id)
  for i = 1, #list do
    if list[i].itemid == item_id then
      return list[i]
    end
  end
  return nil
end

function gacha_module:get_first_suit_exchange_id(gacha_pool_id)
  local list = self:get_exchange_shop_list(gacha_pool_id)
  for i = 1, #list do
    if list[i].shoptag == GachaConst.shop_category.suit then
      return list[i].suitid
    end
  end
  return nil
end

function gacha_module:is_new_item_show_tag(pool_id, item_id)
  local pool_cfg = self:get_exchange_shop_cfg_by_item_id(pool_id, item_id)
  if pool_cfg == nil then
    return false
  end
  return pool_cfg.newitemshowtag == GachaConst.new_item_show_tag
end

function gacha_module:get_pool_show_coins(price_strategy_id)
  self._coin_cache = self._coin_cache or {}
  local cached = self._coin_cache[price_strategy_id]
  if cached ~= nil then
    return cached
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(BCoinShowCfg)) or {}
  local need_cfgs = cfg_dic[price_strategy_id] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return a.index < b.index
  end)
  self._coin_cache[price_strategy_id] = list
  return list
end

function gacha_module:get_all_collect_reward_list(rewardpoolid)
  self._collect_reward_cache = self._collect_reward_cache or {}
  local cached = self._collect_reward_cache[rewardpoolid]
  if cached ~= nil then
    return cached
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(BAllCollectRewardCfg)) or {}
  local need_cfgs = cfg_dic[rewardpoolid] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    if a.rewardtype ~= b.rewardtype then
      return a.rewardtype < b.rewardtype
    end
    return a.rewardid < b.rewardid
  end)
  self._collect_reward_cache[rewardpoolid] = list
  return list
end

function gacha_module:get_accum_reward_list(gacha_pool_id)
  self._accum_reward_cache = self._accum_reward_cache or {}
  local cached = self._accum_reward_cache[gacha_pool_id]
  if cached ~= nil then
    return cached
  end
  local cfg_type = not BGachaAccumulatedRewardCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BGachaAccumulatedRewardCfg
  if cfg_type == nil then
    return EMPTY_TABLE
  end
  local list = {}
  local cfg_dic = ExcelDataUtil.get_table(typeof(cfg_type)) or {}
  local need_cfgs = cfg_dic[gacha_pool_id] or {}
  for _, cfg in pairs(need_cfgs) do
    table_insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return a.index < b.index
  end)
  self._accum_reward_cache[gacha_pool_id] = list
  return list
end

function gacha_module:get_random_pool_items(random_pool_id)
  if random_pool_id == nil or random_pool_id == 0 then
    return EMPTY_TABLE
  end
  self._random_pool_cache = self._random_pool_cache or {}
  local cached = self._random_pool_cache[random_pool_id]
  if cached ~= nil then
    return cached
  end
  local cfg_type = not BRandomPoolCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BRandomPoolCfg
  if cfg_type == nil then
    return EMPTY_TABLE
  end
  local rows = ExcelDataUtil.get_value(typeof(cfg_type), random_pool_id)
  if rows == nil then
    return EMPTY_TABLE
  end
  local items = {}
  for _, row in ipairs(rows) do
    table_insert(items, {
      id = row.configid,
      num = row.num
    })
  end
  self._random_pool_cache[random_pool_id] = items
  return items
end

function gacha_module:get_exchange_coin_id(coin_id)
  local cfg = ExcelDataUtil.get_value(typeof(BGachaCoinExchangeCfg), coin_id)
  if is_null(cfg) then
    return 0
  end
  return cfg.exchangecoinid or 0
end

function gacha_module:clear_cfg_cache()
  self._price_cache = nil
  self._pool_cfg_cache = nil
  self._pool_cfg_index_cache = nil
  self._exchange_cache = nil
  self._coin_cache = nil
  self._collect_reward_cache = nil
  self._accum_reward_cache = nil
  self._random_pool_cache = nil
end

return gacha_module
