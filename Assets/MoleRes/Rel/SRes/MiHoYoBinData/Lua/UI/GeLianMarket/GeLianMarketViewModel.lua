local up_helper = require("UI/GeLianMarket/GeLianMarketUpHelper")
local market_time_util = require("UI/GeLianMarket/GeLianMarketTimeUtil")
local M = G.Class("GeLianMarketViewModel")
M.PredictState = {Locked = "locked", Collecting = "collecting"}
local _price_last = {
  [true] = {},
  [false] = {}
}
local _price_anim = {
  [true] = {},
  [false] = {}
}
local _prediction_last = {}
local _prediction_anim = {}

local function build_display_title(title_list, gender_pref)
  return social_module:get_display_title_by_title_list(list_to_table(title_list or {}), gender_pref)
end

function M.build_page_view_data(is_self_page)
  local market = M.build_market_view_data(CsGeLianMarketModuleUtil.GetMarketSnapshot(is_self_page))
  if market == nil then
    return nil
  end
  local compare
  if not is_self_page then
    compare = M.build_market_view_data(CsGeLianMarketModuleUtil.GetMarketSnapshot(true))
  end
  local prediction = M.build_prediction_view_data(market)
  M._record_price_anim(market)
  if compare ~= nil then
    M._record_price_anim(compare)
  end
  if market.is_self == true then
    M._record_prediction_anim(prediction)
  end
  return {
    is_self_page = is_self_page,
    market_owner_name = is_self_page and player_module:get_player_name() or M._get_scene_owner_name(),
    self_market_owner_name = player_module:get_player_name(),
    market = market,
    compare = compare,
    market_data_version = CsGeLianMarketModuleUtil.MarketDataVersion or 0,
    prediction = prediction,
    social = M.build_social_view_data(is_self_page, market),
    leave_message = M.build_leave_message_view_data(market, compare)
  }
end

function M._record_price_anim(market)
  if market == nil then
    return
  end
  local is_self = market.is_self == true
  local last_bucket = _price_last[is_self]
  local anim_bucket = _price_anim[is_self]
  local entries = market.entries or {}
  for i = 1, #entries do
    local entry = entries[i]
    local last_price = last_bucket[entry.tag]
    if last_price ~= entry.final_price then
      anim_bucket[entry.tag] = true
    end
    last_bucket[entry.tag] = entry.final_price
  end
end

function M._record_prediction_anim(prediction)
  if prediction == nil or prediction.state ~= M.PredictState.Collecting then
    return
  end
  local items = prediction.items or {}
  for i = 1, #items do
    local item = items[i]
    local last_percent = _prediction_last[item.tag]
    if last_percent ~= item.percent then
      _prediction_anim[item.tag] = {
        from = last_percent or 0,
        to = item.percent
      }
    end
    _prediction_last[item.tag] = item.percent
  end
end

function M.take_price_anim(is_self, tag)
  local bucket = _price_anim[is_self and true or false]
  local pending = bucket[tag] == true
  bucket[tag] = nil
  return pending
end

function M.take_prediction_anim(tag)
  local pending = _prediction_anim[tag]
  _prediction_anim[tag] = nil
  return pending
end

function M.build_social_view_data(is_self_page, market)
  local self_market = M.build_market_view_data(CsGeLianMarketModuleUtil.GetMarketSnapshot(true))
  local current_period_id = up_helper.get_current_period_id()
  local self_row, friend_rows = M.build_friend_price_rows(self_market)
  return {
    self_row = self_row,
    friend_rows = friend_rows,
    crop_entries = self_market and self_market.entries or {},
    return_rank = M.build_return_rank_view_data(friend_rows),
    return_rank_available = current_period_id ~= nil and 0 < current_period_id
  }
end

function M.build_random_player_price_view_data()
  local self_market = M.build_market_view_data(CsGeLianMarketModuleUtil.GetMarketSnapshot(true))
  local self_entries = self_market and self_market.entries or {}
  local self_row = M._build_own_friend_row(self_entries)
  local rows = {}
  local snapshots = list_to_table(CsGeLianMarketModuleUtil.GetRandomPlayerMarketSnapshots()) or {}
  for i = 1, #snapshots do
    local snapshot = snapshots[i]
    local entries = {}
    local cs_entries = list_to_table(snapshot.Entries) or {}
    for j = 1, #cs_entries do
      entries[j] = M._copy_entry(cs_entries[j])
    end
    rows[i] = {
      is_self = false,
      uid = snapshot.Uid or 0,
      nickname = snapshot.Nickname or "",
      title = build_display_title(snapshot.TitleIds),
      avatar_id = snapshot.AvatarId or 1,
      is_online = snapshot.IsOnline == true,
      has_price = 0 < #entries,
      entries = entries
    }
  end
  return {
    self_row = self_row,
    friend_rows = rows,
    crop_entries = self_entries
  }
end

function M.build_friend_price_rows(self_market)
  local rows = {}
  local current_period_id = up_helper.get_current_period_id()
  if current_period_id <= 0 then
    return nil, rows
  end
  local self_entries = self_market and self_market.entries or {}
  local config_by_tag = M._build_display_config_by_tag()
  local own_row = M._build_own_friend_row(self_entries)
  local friend_dict = dic_to_table(CsSocialModuleUtil.GetAllSocialFriendInfo()) or {}
  local friend_uids = {}
  for uid in pairs(friend_dict) do
    friend_uids[#friend_uids + 1] = uid
  end
  table.sort(friend_uids)
  for _, uid in ipairs(friend_uids) do
    local row = M._build_friend_price_row(uid, friend_dict[uid], current_period_id, config_by_tag)
    if row ~= nil then
      rows[#rows + 1] = row
    end
  end
  return own_row, rows
end

function M._build_display_config_by_tag()
  local config_by_tag = {}
  local cfg_table = ExcelDataUtil.get_table(typeof(BCropTradingCfg)) or {}
  for _, row in pairs(cfg_table) do
    if not_null(row) and string.is_valid(row.croptag) then
      config_by_tag[row.croptag] = row.price
    end
  end
  return config_by_tag
end

function M._build_own_friend_row(self_entries)
  if self_entries == nil or #self_entries == 0 then
    return nil
  end
  local player_data = player_module.get_player_data and player_module:get_player_data() or nil
  local server_data = player_data and player_data.playerServerData or nil
  return {
    is_self = true,
    uid = player_module:get_player_uid(),
    nickname = player_module:get_player_name(),
    title = social_module:get_self_display_title(),
    avatar_id = server_data and server_data.AvatarID or 1,
    is_online = true,
    has_price = 0 < #self_entries,
    intimacy = 0,
    entries = self_entries
  }
end

function M._build_friend_price_row(uid, friend_info, current_period_id, config_by_tag)
  if is_null(friend_info) then
    return nil
  end
  local market_info = friend_info.CropMarketInfo
  local player_info = friend_info.PlayerInfo
  if not is_null(player_info) and not is_null(player_info.CropMarketInfo) then
    market_info = player_info.CropMarketInfo
  end
  local has_current_market = not is_null(market_info) and (market_info.PeriodId or 0) == current_period_id
  local has_player = not is_null(player_info)
  local friend_data = social_module and social_module.get_friend_info_by_uid and social_module:get_friend_info_by_uid(uid) or nil
  local entries = {}
  local is_stale_sync = has_current_market and (market_info.SyncTime or 0) < market_time_util.get_last_price_refresh_time()
  local shelf_list = not (not has_current_market or is_stale_sync) and list_to_table(market_info.CropOnShelfList) or {}
  for i = 1, #shelf_list do
    local shelf = shelf_list[i]
    local config_id = config_by_tag[shelf.CropTag]
    if config_id ~= nil then
      local multiplier = shelf.PriceMultiplier or 100
      entries[#entries + 1] = {
        tag = shelf.CropTag,
        display_config_id = config_id,
        multiplier = multiplier,
        trend_state = M._calc_trend_state(multiplier),
        final_price = CsGeLianMarketModuleUtil.CalculatePriceByMultiplier(config_id, multiplier)
      }
    end
  end
  local nickname = friend_data and friend_data:get_nick_name_with_remark_name() or has_player and player_info.Nickname or ""
  local title = friend_data and build_display_title(friend_data.current_title_list, friend_data.gender_preference) or has_player and build_display_title(player_info.CurrentTitleList, social_module:proto_gp_to_gender_tag(player_info.GenderPreference)) or ""
  local avatar_id = friend_data and friend_data.avatar_id or has_player and player_info.AvatarId or 1
  local is_online = friend_data and friend_data.is_online == true or has_player and player_info.IsOnline == true
  local intimacy = friend_data and friend_data:get_intimacy() or 0
  return {
    is_self = false,
    uid = uid,
    nickname = nickname,
    title = title,
    avatar_id = avatar_id,
    is_online = is_online,
    has_price = 0 < #entries,
    intimacy = intimacy,
    entries = entries
  }
end

function M.build_return_rank_view_data(friend_rows)
  local current_period_id = up_helper.get_current_period_id()
  local rows = {}
  local self_row = M._build_own_return_rank_row(current_period_id)
  if self_row ~= nil then
    rows[#rows + 1] = self_row
  end
  local friend_dict = {}
  if CsSocialModuleUtil ~= nil then
    friend_dict = dic_to_table(CsSocialModuleUtil.GetAllSocialFriendInfo()) or {}
  end
  local friend_row_by_uid = {}
  for i = 1, #(friend_rows or {}) do
    friend_row_by_uid[friend_rows[i].uid] = friend_rows[i]
  end
  for uid, friend_info in pairs(friend_dict) do
    local profile = friend_row_by_uid[uid]
    local row = M._build_friend_return_rank_row(uid, friend_info, profile, current_period_id)
    if row ~= nil then
      rows[#rows + 1] = row
    end
  end
  table.sort(rows, M._compare_return_rank_rows)
  for i = 1, #rows do
    rows[i].rank = i
  end
  return {
    rows = rows,
    self_hidden = CsGeLianMarketModuleUtil.IsProfitHidden == true
  }
end

function M._build_own_return_rank_row(current_period_id)
  if current_period_id <= 0 then
    return nil
  end
  local player_data = player_module.get_player_data and player_module:get_player_data() or nil
  local server_data = player_data and player_data.playerServerData or nil
  return {
    is_self = true,
    uid = player_module:get_player_uid(),
    nickname = player_module:get_player_name(),
    title = social_module:get_self_display_title(),
    avatar_id = server_data and server_data.AvatarID or 1,
    is_online = true,
    profit_rate_basis_points = CsGeLianMarketModuleUtil.ProfitRateBasisPoints or 0,
    profit_achieved_time = CsGeLianMarketModuleUtil.ProfitAchievedTime or 0,
    is_profit_hidden = CsGeLianMarketModuleUtil.IsProfitHidden == true,
    is_rank_eligible = CsGeLianMarketModuleUtil.IsProfitRankEligible == true
  }
end

function M._build_friend_return_rank_row(uid, friend_info, profile, current_period_id)
  if is_null(friend_info) or current_period_id <= 0 then
    return nil
  end
  local market_info = friend_info.CropMarketInfo
  local player_info = friend_info.PlayerInfo
  if not is_null(player_info) and not is_null(player_info.CropMarketInfo) then
    market_info = player_info.CropMarketInfo
  end
  if is_null(market_info) or (market_info.PeriodId or 0) ~= current_period_id or market_info.IsRankEligible ~= true then
    return nil
  end
  local has_player = not is_null(player_info)
  return {
    is_self = false,
    uid = uid,
    nickname = profile and profile.nickname or has_player and player_info.Nickname or "",
    title = profile and profile.title or has_player and build_display_title(player_info.CurrentTitleList, social_module:proto_gp_to_gender_tag(player_info.GenderPreference)) or "",
    avatar_id = profile and profile.avatar_id or has_player and player_info.AvatarId or 1,
    is_online = profile and profile.is_online == true or has_player and player_info.IsOnline == true,
    profit_rate_basis_points = market_info.ProfitRateBasisPoints or 0,
    profit_achieved_time = market_info.ProfitAchievedTime or 0,
    is_profit_hidden = market_info.IsProfitHidden == true,
    is_rank_eligible = true,
    sync_time = market_info.SyncTime or 0
  }
end

function M._compare_return_rank_rows(a, b)
  if a.is_rank_eligible ~= b.is_rank_eligible then
    return a.is_rank_eligible
  end
  if a.profit_rate_basis_points ~= b.profit_rate_basis_points then
    return a.profit_rate_basis_points > b.profit_rate_basis_points
  end
  if a.profit_achieved_time ~= b.profit_achieved_time then
    return a.profit_achieved_time < b.profit_achieved_time
  end
  return a.uid < b.uid
end

function M.build_leave_message_view_data(market, compare)
  local liked_map = {}
  local liked_keys = list_to_table(CsGeLianMarketModuleUtil.GetAllLikeMessageKeys()) or {}
  for i = 1, #liked_keys do
    liked_map[liked_keys[i].MarketId .. "_" .. liked_keys[i].MessageId] = true
  end
  local crop_config_by_tag = {}
  M._collect_crop_config(crop_config_by_tag, market)
  M._collect_crop_config(crop_config_by_tag, compare)
  return {
    other = M._copy_messages(CsGeLianMarketModuleUtil.GetAllOtherMessageInfo(), liked_map),
    mine = M._copy_messages(CsGeLianMarketModuleUtil.GetAllMineMessageInfo(), liked_map),
    crop_config_by_tag = crop_config_by_tag
  }
end

function M._copy_messages(cs_messages, liked_map)
  local messages = {}
  local cs_list = list_to_table(cs_messages)
  for i = 1, #cs_list do
    local cs_message = cs_list[i]
    local market_id = cs_message.MarketId or 0
    messages[i] = {
      message_id = cs_message.MessageId,
      user_id = cs_message.UserId,
      username = cs_message.Username,
      zone = cs_message.Zone,
      content = cs_message.Content,
      likes = cs_message.Likes or 0,
      create_time = cs_message.CreateTime or 0,
      tag_name = cs_message.TagName,
      market_id = market_id,
      is_liked = liked_map[market_id .. "_" .. cs_message.MessageId] == true
    }
  end
  return messages
end

function M._collect_crop_config(crop_config_by_tag, market)
  local entries = market and market.entries or nil
  if entries == nil then
    return
  end
  for i = 1, #entries do
    local entry = entries[i]
    if entry.tag ~= nil and crop_config_by_tag[entry.tag] == nil then
      crop_config_by_tag[entry.tag] = entry.display_config_id
    end
  end
end

local PREDICT_UNLOCK_OPEN_STATE_ID = 161

function M.build_prediction_view_data(market)
  if market == nil then
    return nil
  end
  if not CsOpenStateModuleUtil.GetConditionIsUnlock(PREDICT_UNLOCK_OPEN_STATE_ID) then
    return {
      state = M.PredictState.Locked
    }
  end
  local local_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(TimeUtil.ServerUtcTimeSeconds)
  if local_time.Hour < 12 then
    return {
      state = M.PredictState.Collecting,
      market_end_time = CsGeLianMarketModuleUtil.MarketEndTime or 0,
      items = {}
    }
  end
  local entries = market.entries or {}
  local total = 0
  for i = 1, #entries do
    total = total + entries[i].progress_count
  end
  local items = {}
  local remaining = 100
  for i = 1, #entries do
    local entry = entries[i]
    local percent = 0
    if 0 < total then
      if i == #entries then
        percent = remaining
      else
        percent = math.floor(entry.progress_count * 100 / total + 0.5)
        remaining = remaining - percent
      end
    end
    items[i] = {
      tag = entry.tag,
      display_config_id = entry.display_config_id,
      progress_count = entry.progress_count,
      percent = percent
    }
  end
  table.sort(items, function(a, b)
    if a.percent ~= b.percent then
      return a.percent > b.percent
    end
    return a.display_config_id < b.display_config_id
  end)
  local rank = 1
  for i = 1, #items do
    if i == 1 then
      items[i].rank = rank
    else
      if items[i].percent < items[i - 1].percent then
        rank = rank + 1
      end
      items[i].rank = rank
    end
  end
  return {
    state = M.PredictState.Collecting,
    market_end_time = CsGeLianMarketModuleUtil.MarketEndTime or 0,
    items = items,
    prediction_target = items[#items]
  }
end

function M._get_scene_owner_name()
  local world_info = CsPlayerVisitModuleUtil ~= nil and CsPlayerVisitModuleUtil.GetWorldInfo() or nil
  if not is_null(world_info) and string.is_valid(world_info.OwnerName) then
    return world_info.OwnerName
  end
  local owner_info = CsWorldInfoLuaBridgeUtil ~= nil and CsWorldInfoLuaBridgeUtil.GetWorldOwnerInfo() or nil
  if not is_null(owner_info) and string.is_valid(owner_info.NickName) then
    return owner_info.NickName
  end
  return ""
end

function M.build_market_view_data(snapshot)
  if is_null(snapshot) then
    return nil
  end
  local entries = {}
  local cs_entries = list_to_table(snapshot.Entries)
  for i = 1, #cs_entries do
    entries[i] = M._copy_entry(cs_entries[i])
  end
  table.sort(entries, function(a, b)
    return a.tag < b.tag
  end)
  return {
    is_unlock = snapshot.IsUnlock == true,
    has_new_data = snapshot.HasNewData == true,
    trend_style = snapshot.TrendStyle or 0,
    is_self = snapshot.Scope == 0,
    entries = entries
  }
end

function M._copy_entry(cs_entry)
  local fruit_ids = {}
  local cs_fruit_ids = list_to_table(cs_entry.FruitIds)
  for i = 1, #cs_fruit_ids do
    fruit_ids[i] = cs_fruit_ids[i]
  end
  return {
    tag = cs_entry.Tag,
    display_config_id = cs_entry.DisplayConfigId,
    fruit_ids = fruit_ids,
    sell_limit = cs_entry.SellLimit or 0,
    sold_count = cs_entry.SoldCount or 0,
    display_multiplier = cs_entry.DisplayMultiplier or 100,
    server_multiplier = cs_entry.ServerMultiplier or 100,
    final_price = cs_entry.FinalPrice or 0,
    progress_count = cs_entry.ProgressCount or 0,
    trend_state = cs_entry.TrendState or 2
  }
end

M.TrendState = {
  Up = 0,
  Down = 1,
  Flat = 2,
  UpAlt = 3,
  DownAlt = 4
}

function M._calc_trend_state(multiplier)
  local trend_style = CsGeLianMarketModuleUtil.GetTrendStyle() or 0
  if 100 < multiplier then
    return trend_style == 0 and M.TrendState.Up or M.TrendState.UpAlt
  elseif multiplier < 100 then
    return trend_style == 0 and M.TrendState.Down or M.TrendState.DownAlt
  end
  return M.TrendState.Flat
end

return M
