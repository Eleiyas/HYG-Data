blueprint_habitat_module = blueprint_habitat_module or {}

function blueprint_habitat_module:should_show_tracking_item()
  return CsHabitatModuleUtil.ShouldShowHabitatTrackingItem()
end

function blueprint_habitat_module:should_show_tracking_condition_des()
  return CsHabitatModuleUtil.ShouldShowHabitatTrackingConditionDes()
end

function blueprint_habitat_module:is_tracking_any_habitat()
  if CsHabitatModuleUtil.GetTrackingHabitatId() > 0 then
    return true
  end
  return false
end

function blueprint_habitat_module:is_tracking_habitat_by_id(habitat_id, should_in_feature)
  if should_in_feature == nil then
    should_in_feature = true
  end
  if CsHabitatModuleUtil.GetTrackingHabitatId(should_in_feature) == habitat_id then
    return true
  end
  return false
end

function blueprint_habitat_module:has_habitat_site_data(habitat_id)
  return CsHabitatModuleUtil.HasHabitatSiteDataFromSceneData(habitat_id)
end

function blueprint_habitat_module:get_tracking_habitat_id()
  return CsHabitatModuleUtil.GetTrackingHabitatId()
end

function blueprint_habitat_module:set_tracking_habitat(habitat_id, is_tracking, by_op)
  if is_tracking then
    CsHabitatModuleUtil.StartHabitatTracking(habitat_id, by_op)
  else
    CsHabitatModuleUtil.StopHabitatTracking(habitat_id, by_op)
  end
end

function blueprint_habitat_module:is_habitat_restored(habitat_id)
  return CsHabitatModuleUtil.IsHabitatRestored(habitat_id)
end

function blueprint_habitat_module:is_habitat_reward_claimed(habitat_id)
  return CsHabitatModuleUtil.IsHabitatRewardClaimed(habitat_id)
end

function blueprint_habitat_module:is_habitat_creature_unlocked(habitat_id)
  return CsHabitatModuleUtil.IsHabitatCreatureUnlocked(habitat_id)
end

function blueprint_habitat_module:get_habitat_creature_id(habitat_id)
  local ok, cfg = CsHabitatModuleUtil.TryGetHabitatCfg(habitat_id)
  if not ok or cfg == nil or not string.is_valid(cfg.SpawnCreature) then
    return 0
  end
  local ids = lua_str_split(cfg.SpawnCreature, ",")
  if #ids <= 0 then
    return 0
  end
  local id = tonumber(ids[1]) or 0
  if 0 < id and item_module:has_cfg_by_id(id) then
    return id
  end
  return 0
end

function blueprint_habitat_module:get_habitat_reward(habitat_id)
  local ok, cfg = CsHabitatModuleUtil.TryGetHabitatCfg(habitat_id)
  if not ok or cfg == nil then
    return nil
  end
  return self:_first_reward_id_from_pool(cfg.RewardPoolID)
end

function blueprint_habitat_module:_first_reward_id_from_pool(pool_id)
  if pool_id == nil or pool_id <= 0 then
    return nil
  end
  local items = item_module:get_random_pool_items(pool_id)
  if items == nil or #items == 0 then
    return nil
  end
  return items[1]
end

function blueprint_habitat_module:claim_habitat_restore_reward(habitat_id)
  CsHabitatModuleUtil.ClaimHabitatRestoreReward(habitat_id)
end

function blueprint_habitat_module:get_habitat_ui_cfg(habitat_id)
  return ExcelDataUtil.get_value(typeof(BHabitatUICfg), habitat_id)
end

function blueprint_habitat_module:get_first_restored_time(habitat_id)
  return CsHabitatModuleUtil.GetHabitatFirstRestoreTime(habitat_id)
end

function blueprint_habitat_module:has_habitat_ever_been_restored(habitat_id)
  return CsHabitatModuleUtil.GetHabitatFirstRestoreTime(habitat_id) > 0
end

function blueprint_habitat_module:record_habitat_unlock(habitat_id)
  red_point_module:record_with_id(red_point_module.red_point_type.habitat_unlock, habitat_id)
end

function blueprint_habitat_module:is_habitat_unlock_recorded(habitat_id)
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.habitat_unlock, habitat_id)
end

function blueprint_habitat_module:has_any_habitat_unlock_not_recorded()
  local habitat_id_list = list_to_table(CsHabitatModuleUtil.GetAllDiscoveredHabitatId()) or {}
  for _, habitat_id in ipairs(habitat_id_list) do
    if not self:is_habitat_unlock_recorded(habitat_id) then
      return true
    end
  end
  return false
end

function blueprint_habitat_module:get_entrance_red_point_type()
  if CsHabitatModuleUtil.HasAnyHabitatRestoredRewardNotClaimed() or CsHabitatModuleUtil.HasAnyArchitectLevelRewardNotClaimed() then
    return RedPointType.GiftRP
  end
  if self:has_any_habitat_unlock_not_recorded() then
    return RedPointType.NewRp
  end
  if new_blueprint_module:is_unlocked() and new_blueprint_module:has_any_blueprint_unlock_not_recorded() then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function blueprint_habitat_module:get_architect_level_cfgs()
  if self._architect_level_cfgs ~= nil then
    return self._architect_level_cfgs
  end
  self._architect_level_cfgs = ExcelDataUtil.get_table(typeof(BHabitatLevelCfg)) or {}
  table.sort(self._architect_level_cfgs, function(a, b)
    return a.level < b.level
  end)
  return self._architect_level_cfgs
end

function blueprint_habitat_module:get_architect_total_stars()
  return CsHabitatModuleUtil.GetArchitectTotalStars() or 0
end

function blueprint_habitat_module:get_architect_level()
  local total_stars = blueprint_habitat_module:get_architect_total_stars()
  local cfgs = self:get_architect_level_cfgs()
  if #cfgs == 0 then
    return 1, 0, 0
  end
  local accumulated = 0
  local current_level = cfgs[1].level
  local current_cfg = cfgs[1]
  for i = 1, #cfgs do
    local next_cfg = cfgs[i]
    local need = next_cfg.experience or 0
    if total_stars < accumulated + need then
      return current_level, accumulated + need - total_stars, need
    end
    accumulated = accumulated + need
    current_level = next_cfg.level
    current_cfg = next_cfg
  end
  return current_level, 0, 0
end

function blueprint_habitat_module:get_architect_max_level()
  local cfgs = self:get_architect_level_cfgs()
  return #cfgs
end

function blueprint_habitat_module:get_architect_cur_level_cfg()
  local cur_level = self:get_architect_level()
  local cfgs = self:get_architect_level_cfgs()
  return cfgs[cur_level]
end

function blueprint_habitat_module:get_architect_level_reward_id(level)
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatLevelCfg), level)
  if cfg == nil or cfg.rewardpoolidLength == nil or cfg.rewardpoolidLength <= 0 then
    return nil
  end
  return self:_first_reward_id_from_pool(cfg:rewardpoolid(0))
end

function blueprint_habitat_module:has_architect_level_reward_claimed(level)
  return CsHabitatModuleUtil.HasArchitectLevelRewardClaimed(level)
end

function blueprint_habitat_module:has_architect_level_reward(level)
  local level_cfgs = self:get_architect_level_cfgs()
  if level_cfgs[level] and level_cfgs[level].rewardpoolidLength == 0 then
    return false
  end
  return true
end

function blueprint_habitat_module:claim_habitat_architect_level_reward(level, callback)
  CsHabitatModuleUtil.ClaimHabitatArchitectLevelReward(level, callback)
end

return blueprint_habitat_module
