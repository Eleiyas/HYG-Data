local M = {}
M._self_stall_state = nil
M._self_stall_query_seq = 0
M.TrendState = {
  Up = 0,
  Down = 1,
  Flat = 2,
  UpAlt = 3,
  DownAlt = 4
}

function M.query(uid, force, callback)
  if callback == nil then
    return
  end
  CsSocialModuleUtil.QuerySocialPlayerInfo(uid, function(info)
    if is_null(info) then
      callback(nil)
      return
    end
    callback(M._build_view_data(uid, info))
  end, force == true)
end

function M.query_self_stall_unlocked(callback)
  local uid = player_module:get_player_uid()
  if uid == 0 then
    if callback ~= nil then
      callback(false)
    end
    return
  end
  M._self_stall_query_seq = M._self_stall_query_seq + 1
  local seq = M._self_stall_query_seq
  
  local function is_stale()
    return player_module:get_player_uid() ~= uid or seq ~= M._self_stall_query_seq
  end
  
  CsSocialModuleUtil.QuerySocialPlayerInfo(uid, function(info)
    if is_stale() then
      if callback ~= nil then
        callback(false)
      end
      return
    end
    if is_null(info) then
      if not is_null(M._self_stall_state) and M._self_stall_state.uid == uid then
        M._self_stall_state = nil
      end
      if callback ~= nil then
        callback(false)
      end
      return
    end
    M._self_stall_state = {
      uid = uid,
      is_stall_unlocked = info.IsStallUnlocked == true
    }
    if callback ~= nil then
      callback(M._self_stall_state.is_stall_unlocked)
    end
  end, false)
end

function M.is_self_stall_unlocked()
  local state = M._self_stall_state
  if is_null(state) or state.uid ~= player_module:get_player_uid() then
    return false
  end
  return state.is_stall_unlocked == true
end

function M._build_view_data(uid, info)
  return {
    uid = uid,
    nickname = info.Nickname or "",
    is_online = info.IsOnline == true,
    avatar_id = info.AvatarId or 0,
    main_land_name = info.MainLandName or "",
    is_crop_market_open = info.IsCropMarketOpen == true,
    is_stall_unlocked = info.IsStallUnlocked == true,
    market = M._build_market_view(info),
    stall = M._build_stall_view(info)
  }
end

function M._build_market_view(info)
  local market = {
    sync_time = 0,
    items = {}
  }
  local market_info = info.CropMarketInfo
  if is_null(market_info) then
    return market
  end
  market.sync_time = market_info.SyncTime or 0
  local trading_cfg_map = M._build_trading_cfg_map()
  local shelf_list = list_to_table(market_info.CropOnShelfList)
  for i = 1, #shelf_list do
    local item = M._build_market_item(shelf_list[i], trading_cfg_map)
    if item ~= nil then
      market.items[#market.items + 1] = item
    end
  end
  return market
end

function M._build_market_item(shelf, trading_cfg_map)
  local trading_cfg = trading_cfg_map[shelf.CropTag]
  if is_null(trading_cfg) then
    return nil
  end
  local server_multiplier = shelf.PriceMultiplier or 100
  local final_price = CsGeLianMarketModuleUtil.CalculatePriceByMultiplier(trading_cfg.price, server_multiplier)
  local display_multiplier = M._calc_limited_display_multiplier(trading_cfg.price, server_multiplier, final_price)
  return {
    tag = shelf.CropTag,
    server_multiplier = server_multiplier,
    display_multiplier = display_multiplier,
    display_config_id = trading_cfg.price,
    fruit_ids = M._copy_fruit_ids(trading_cfg),
    sell_limit = trading_cfg.friendselllimit or 0,
    final_price = final_price,
    trend_state = M._calc_trend_state(display_multiplier)
  }
end

function M._calc_limited_display_multiplier(display_config_id, server_multiplier, final_price)
  if server_multiplier == 100 then
    return 100
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), display_config_id)
  if is_null(item_cfg) or item_cfg.price <= 0 or final_price <= 0 then
    return server_multiplier
  end
  local ratio = final_price / item_cfg.price * 100
  if 100 < server_multiplier then
    return math.max(101, math.ceil(ratio))
  end
  return math.min(99, math.floor(ratio))
end

function M._build_trading_cfg_map()
  local cfg_map = {}
  local cfg_table = ExcelDataUtil.get_table(typeof(BCropTradingCfg)) or {}
  for _, row in pairs(cfg_table) do
    if not_null(row) and string.is_valid(row.croptag) then
      cfg_map[row.croptag] = row
    end
  end
  return cfg_map
end

function M._copy_fruit_ids(trading_cfg)
  local fruit_ids = {}
  local count = trading_cfg.fruitidlistLength or 0
  for i = 0, count - 1 do
    local fruit_id = trading_cfg:fruitidlist(i)
    if 0 < fruit_id then
      fruit_ids[#fruit_ids + 1] = fruit_id
    end
  end
  return fruit_ids
end

function M._calc_trend_state(display_multiplier)
  local trend_style = CsGeLianMarketModuleUtil.GetTrendStyle() or 0
  if 100 < display_multiplier then
    return trend_style == 0 and M.TrendState.Up or M.TrendState.UpAlt
  elseif display_multiplier < 100 then
    return trend_style == 0 and M.TrendState.Down or M.TrendState.DownAlt
  end
  return M.TrendState.Flat
end

function M._build_stall_view(info)
  local stall = {
    snapshot_time = 0,
    slots = {},
    has_goods = false
  }
  local stall_info = info.StallInfo
  if is_null(stall_info) then
    return stall
  end
  stall.snapshot_time = stall_info.SnapshotTime or 0
  local slot_list = list_to_table(stall_info.SlotInfoList)
  for i = 1, #slot_list do
    local slot = slot_list[i]
    if not is_null(slot) and slot.ItemConfigId ~= 0 then
      stall.slots[#stall.slots + 1] = {
        config_id = slot.ItemConfigId,
        count = slot.ItemCount or 0,
        unit_price = slot.UnitPrice or 0
      }
      if 0 < (slot.ItemCount or 0) then
        stall.has_goods = true
      end
    end
  end
  return stall
end

return M
