require("UI/Codex/SeasonCodex/SeasonCodexSeasonMgr")
local tag_sea_fish = EntityTagTags.Tags.organism_animal_fish_seafish
local tag_river_fish = EntityTagTags.Tags.organism_animal_fish_riverfish
codex_module = codex_module or {}
codex_module.red_point_type_season_data = red_point_module.red_point_type.season_codex
codex_module._season_cache = nil
codex_module._season_cache_source = nil
codex_module._season_reward_cache = nil
codex_module._season_reward_claim_pending = nil

function codex_module:get_season_codex_data_list()
  local all_data = self:get_all_data()
  if not all_data then
    return {}
  end
  if self._season_cache and self._season_cache_source == all_data then
    return self._season_cache
  end
  local season_list = {}
  for id, data in pairs(all_data) do
    if not_null(data) and data.Type == CodexDataType.Creature and data.IsSeasonal then
      table.insert(season_list, data)
    end
  end
  table.sort(season_list, function(a, b)
    local idx_a = not_null(a.CodexCfg) and a.CodexCfg.index or 0
    local idx_b = not_null(b.CodexCfg) and b.CodexCfg.index or 0
    return idx_a < idx_b
  end)
  self._season_cache = season_list
  self._season_cache_source = all_data
  return season_list
end

function codex_module:invalidate_season_cache()
  self._season_cache = nil
  self._season_cache_source = nil
  self._season_reward_cache = nil
  self._season_reward_claim_pending = nil
  self:invalidate_season_mgr_cache()
end

function codex_module:is_season_fish(data)
  if is_null(data) then
    return false
  end
  return data.SubType == CodexDataSubType.CreatureFish
end

function codex_module:is_sea_fish(data)
  if not self:is_season_fish(data) then
    return false
  end
  if is_null(data.IdCfg) then
    return false
  end
  return TagUtil.config_has_tag(data.IdCfg.id, tag_sea_fish)
end

function codex_module:is_river_fish(data)
  if not self:is_season_fish(data) then
    return false
  end
  if is_null(data.IdCfg) then
    return false
  end
  return TagUtil.config_has_tag(data.IdCfg.id, tag_river_fish)
end

function codex_module:is_season_insect(data)
  if is_null(data) then
    return false
  end
  return data.SubType == CodexDataSubType.CreatureInsect
end

function codex_module:is_season_shore(data)
  if is_null(data) then
    return false
  end
  return data.SubType == CodexDataSubType.CreatureSeaFood
end

local _title_id_by_item_id

local function _get_title_id_by_item_id(item_id)
  if _title_id_by_item_id == nil then
    _title_id_by_item_id = {}
    local title_cfgs = ExcelDataUtil.get_table(typeof(BPlayerTitleCfg)) or {}
    for _, title_cfg in pairs(title_cfgs) do
      if not is_null(title_cfg) and title_cfg.itemid and title_cfg.itemid > 0 then
        _title_id_by_item_id[title_cfg.itemid] = title_cfg.titleid
      end
    end
  end
  return _title_id_by_item_id[item_id]
end

local function _sort_title_ids_by_display_order(title_ids)
  local entries = {}
  for idx, title_id in ipairs(title_ids) do
    local title_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleCfg), title_id)
    table.insert(entries, {
      id = title_id,
      order = not_null(title_cfg) and title_cfg.displayorder or 0,
      idx = idx
    })
  end
  table.sort(entries, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.idx < b.idx
  end)
  for i, entry in ipairs(entries) do
    title_ids[i] = entry.id
  end
end

local function _reward_data_from_random_pool(pool_id)
  if not pool_id or pool_id <= 0 then
    return 0, 0, {}
  end
  local pool_entries = ExcelDataUtil.get_value(typeof(BRandomPoolCfg), pool_id)
  if is_null(pool_entries) then
    return 0, 0, {}
  end
  local item_id = 0
  local item_count = 0
  local title_ids = {}
  local entries = list_to_table(pool_entries)
  for _, entry in ipairs(entries) do
    if not is_null(entry) and entry.configid and 0 < entry.configid then
      local title_id = _get_title_id_by_item_id(entry.configid)
      if title_id and 0 < title_id then
        table.insert(title_ids, title_id)
      elseif item_id == 0 then
        item_id = entry.configid
        item_count = entry.num or 1
      end
    end
  end
  _sort_title_ids_by_display_order(title_ids)
  return item_id, item_count, title_ids
end

function codex_module:get_season_reward_cfgs(season_id)
  local rows = self:_get_season_reward_static_cfgs(season_id)
  self:_overlay_season_reward_server_state(season_id, rows)
  return rows
end

function codex_module:_get_season_reward_static_cfgs(season_id)
  if season_id == nil or season_id == 0 then
    return {}
  end
  self._season_reward_cache = self._season_reward_cache or {}
  if self._season_reward_cache[season_id] then
    return self._season_reward_cache[season_id]
  end
  local result = {}
  local all_rows = ExcelDataUtil.get_table(typeof(BCodexSeasonNumRewardCfg))
  if not all_rows then
    self._season_reward_cache[season_id] = result
    return result
  end
  for _, row in pairs(all_rows) do
    if not is_null(row) and row.seasonid == season_id then
      local item_id, item_count, title_ids = _reward_data_from_random_pool(row.randompoolid)
      local name = ""
      if 0 < item_id then
        name = item_module:get_item_name_by_id(item_id) or ""
      end
      table.insert(result, {
        id = row.id,
        count = row.num or 0,
        item_id = item_id,
        item_count = item_count,
        title_ids = title_ids,
        is_special = row.rewardshowtype == 2,
        is_reached = false,
        is_claimed = false,
        name = name,
        special_reward_pic = row.specialrewardpic or ""
      })
    end
  end
  table.sort(result, function(a, b)
    return (a.count or 0) < (b.count or 0)
  end)
  self._season_reward_cache[season_id] = result
  return result
end

function codex_module:_overlay_season_reward_server_state(season_id, rows)
  for _, row in ipairs(rows) do
    row.is_reached = false
    row.is_claimed = false
  end
  if season_id == nil or season_id == 0 or #rows == 0 then
    return
  end
  local cs_list = self:_get_season_num_reward_list(season_id)
  if cs_list == nil then
    return
  end
  local server_map = {}
  for i = 0, cs_list.Count - 1 do
    local data = cs_list[i]
    if not is_null(data) then
      server_map[data.ConfigId] = data
    end
  end
  for _, row in ipairs(rows) do
    local data = server_map[row.id]
    if data ~= nil then
      row.is_reached = data.IsUnlocked
      row.is_claimed = data.IsRewardTaken
    end
  end
end

function codex_module:get_season_next_reward_node(season_id, unlocked_count)
  local cfgs = self:get_season_reward_cfgs(season_id)
  for _, cfg in ipairs(cfgs) do
    if unlocked_count < (cfg.count or 0) then
      return cfg
    end
  end
  return nil
end

codex_module.season_reward_state = {
  locked = 0,
  claimable = 1,
  claimed = 2
}

function codex_module:get_season_reward_state(reward_cfg)
  if reward_cfg == nil then
    return self.season_reward_state.locked
  end
  if reward_cfg.is_claimed then
    return self.season_reward_state.claimed
  end
  if reward_cfg.is_reached then
    return self.season_reward_state.claimable
  end
  return self.season_reward_state.locked
end

function codex_module:_get_season_reward_claim_pending()
  self._season_reward_claim_pending = self._season_reward_claim_pending or {}
  return self._season_reward_claim_pending
end

function codex_module:_get_season_num_reward_list(season_id)
  if season_id == nil or season_id == 0 or CsCodexModuleUtil.IsNull() then
    return nil
  end
  local cs_list = CsCodexModuleUtil.GetSeasonNumRewardListBySeason(season_id)
  if is_null(cs_list) or 0 >= cs_list.Count then
    return nil
  end
  local pending = self:_get_season_reward_claim_pending()
  for i = 0, cs_list.Count - 1 do
    local data = cs_list[i]
    if not is_null(data) and data.IsRewardTaken then
      pending[data.ConfigId] = nil
    end
  end
  return cs_list
end

function codex_module:_is_season_reward_claim_pending(reward_id)
  return self:_get_season_reward_claim_pending()[reward_id] == true
end

function codex_module:_is_season_reward_data_claimable(data)
  if is_null(data) then
    return false
  end
  return data.IsUnlocked and not data.IsRewardTaken and not self:_is_season_reward_claim_pending(data.ConfigId)
end

function codex_module:has_season_claimable_reward(season_id)
  local cs_list = self:_get_season_num_reward_list(season_id)
  if cs_list == nil then
    return false
  end
  for i = 0, cs_list.Count - 1 do
    if self:_is_season_reward_data_claimable(cs_list[i]) then
      return true
    end
  end
  return false
end

function codex_module:get_season_reward_summary_state(season_id)
  local cfgs = self:get_season_reward_cfgs(season_id)
  if #cfgs == 0 then
    return false, false, false
  end
  local has_unclaimed = false
  local all_unlocked = true
  local all_claimed = true
  for _, cfg in ipairs(cfgs) do
    if not cfg.is_reached then
      all_unlocked = false
    end
    if not cfg.is_claimed then
      all_claimed = false
      if cfg.is_reached then
        has_unclaimed = true
      end
    end
  end
  return has_unclaimed, all_unlocked, all_claimed
end

function codex_module:has_season_unclaimed_reward(season_id)
  local has_unclaimed = self:get_season_reward_summary_state(season_id)
  return has_unclaimed
end

function codex_module:is_all_season_rewards_unlocked(season_id)
  local _, all_unlocked = self:get_season_reward_summary_state(season_id)
  return all_unlocked
end

function codex_module:get_season_reward_red_point_type(season_id)
  if self:has_season_claimable_reward(season_id) then
    return RedPointType.GiftRP
  end
  return RedPointType.None
end

function codex_module:is_all_season_rewards_claimed(season_id)
  local _, _, all_claimed = self:get_season_reward_summary_state(season_id)
  return all_claimed
end

function codex_module:claim_season_reward(reward_id, callback)
  if reward_id == nil or reward_id == 0 or CsCodexModuleUtil.IsNull() then
    if callback then
      callback(false)
    end
    return
  end
  if self:_is_season_reward_claim_pending(reward_id) then
    return
  end
  self:_get_season_reward_claim_pending()[reward_id] = true
  CsCodexModuleUtil.TakeSeasonNumReward(reward_id, function(ret_code, rewards)
    if ret_code ~= 0 then
      self:_get_season_reward_claim_pending()[reward_id] = nil
      Logger.LogWarning("[SeasonCodex] claim_season_reward failed, reward_id=" .. tostring(reward_id) .. " retcode=" .. tostring(ret_code))
      self:notify_season_reward_changed()
      if callback then
        callback(false)
      end
      return
    end
    local reward_list = {}
    if not_null(rewards) and not_null(rewards.RewardItemList) then
      for i = 0, rewards.RewardItemList.Count - 1 do
        local item = rewards.RewardItemList[i]
        table.insert(reward_list, {
          id = item.ItemConfigId,
          num = item.Count
        })
      end
    end
    self:notify_season_reward_changed()
    if callback then
      callback(true, reward_list)
    end
  end)
end

function codex_module:notify_season_reward_changed()
  EventCenter.Broadcast(EventID.OnCodexSeasonNumRewardUpdate, nil)
end

function codex_module:is_season_new_item(id)
  if id == nil or id == 0 then
    return false
  end
  local data = self:get_data_by_id(id)
  if is_null(data) or not data.IsUnlocked then
    return false
  end
  return not red_point_module:is_recorded_with_id(codex_module.red_point_type_season_data, id)
end

function codex_module:has_season_new_items(season_id)
  if season_id == nil or season_id == 0 then
    return false
  end
  local list = self:get_season_all_creatures(season_id) or {}
  for _, data in ipairs(list) do
    local id = data.IdCfg and data.IdCfg.id or 0
    if self:is_season_new_item(id) then
      return true
    end
  end
  return false
end

function codex_module:get_season_sign_cfg(data)
  if is_null(data) or not data.IsSeasonal then
    return nil
  end
  local season_id = data.SeasonID
  if season_id == 0 then
    return nil
  end
  local cfg_table = ExcelDataUtil.get_table(typeof(BCodexSeasonSignCfg))
  if is_null(cfg_table) then
    return nil
  end
  return cfg_table:RowsByKey(season_id)
end

function codex_module:is_seasonal_hot(data)
  if is_null(data) then
    return false
  end
  return data.IsSeasonal and data.SeasonID == 0
end

return codex_module
