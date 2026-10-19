codex_module = codex_module or {}
local CategoryType = {
  Fish = 1,
  Insect = 2,
  Shore = 3
}
local SubTypeToCategory = {
  [CodexDataSubType.CreatureFish] = CategoryType.Fish,
  [CodexDataSubType.CreatureInsect] = CategoryType.Insect,
  [CodexDataSubType.CreatureSeaFood] = CategoryType.Shore
}
codex_module._season_mgr_cache = nil
codex_module._season_mgr_cache_source = nil

function codex_module:invalidate_season_mgr_cache()
  self._season_mgr_cache = nil
  self._season_mgr_cache_source = nil
end

function codex_module:_ensure_season_mgr_cache()
  local data_source = self:get_all_data()
  if self._season_mgr_cache == nil or self._season_mgr_cache_source ~= data_source then
    self._season_mgr_cache = {}
    self._season_mgr_cache_source = data_source
  end
  return self._season_mgr_cache
end

function codex_module:get_season_info(season_id)
  if season_id == nil or season_id == 0 then
    Logger.LogError("[SeasonCodex] get_season_info: season_id 为空或 0，赛季图鉴必须显式传入有效 SeasonID")
    return nil
  end
  local cache = self:_ensure_season_mgr_cache()
  if cache[season_id] then
    return cache[season_id]
  end
  local info = self:_build_season_info(season_id)
  cache[season_id] = info
  return info
end

function codex_module:_build_season_info(season_id)
  local all_data = self:get_all_data()
  if not all_data then
    return nil
  end
  local packages = {}
  for _, data in pairs(all_data) do
    if not_null(data) and data.Type == CodexDataType.Creature and data.IsPackage and data.SeasonID == season_id then
      table.insert(packages, data)
    end
  end
  if #packages == 0 then
    Logger.LogWarning("[SeasonCodex] 赛季 " .. tostring(season_id) .. " 未找到任何生物组(CreaturePackage)，请检查 BCodexCfg.seasonid 配置")
  end
  table.sort(packages, function(a, b)
    return (a.SubType or 0) < (b.SubType or 0)
  end)
  local category_data = {
    [CategoryType.Fish] = {},
    [CategoryType.Insect] = {},
    [CategoryType.Shore] = {}
  }
  local seen = {}
  for _, pkg in ipairs(packages) do
    local member_ids = pkg.PackageItemIds
    if not_null(member_ids) then
      for i = 0, member_ids.Count - 1 do
        local member_id = member_ids[i]
        if not seen[member_id] then
          seen[member_id] = true
          local member = self:get_data_by_id(member_id)
          if not_null(member) then
            local cat = SubTypeToCategory[member.SubType]
            if cat ~= nil then
              table.insert(category_data[cat], member)
            end
          end
        end
      end
    end
  end
  for _, list in pairs(category_data) do
    table.sort(list, function(a, b)
      local idx_a = not_null(a.CodexCfg) and a.CodexCfg.index or 0
      local idx_b = not_null(b.CodexCfg) and b.CodexCfg.index or 0
      return idx_a < idx_b
    end)
  end
  return {
    season_id = season_id,
    packages = packages,
    category_data = category_data,
    layout_key = self:get_season_layout_key(season_id)
  }
end

local FishSubType = {SeaFish = 1, RiverFish = 2}
local CategoryPosName = {
  [CategoryType.Fish] = "fish",
  [CategoryType.Insect] = "insects",
  [CategoryType.Shore] = "shore"
}
local FishSubPosSuffix = {
  [FishSubType.SeaFish] = "sea",
  [FishSubType.RiverFish] = "river"
}

function codex_module:get_season_layout_key(season_id)
  return "pos_season_" .. tostring(season_id)
end

function codex_module:get_category_pos_name(category)
  return CategoryPosName[category]
end

function codex_module:get_pos_name(category, fish_sub)
  if category == CategoryType.Fish then
    local suffix = fish_sub ~= nil and FishSubPosSuffix[fish_sub] or nil
    if suffix == nil then
      return CategoryPosName[category]
    end
    return "fish_" .. suffix
  end
  return CategoryPosName[category]
end

function codex_module:get_season_category_data(season_id, category)
  local info = self:get_season_info(season_id)
  if not info then
    return {}
  end
  return info.category_data[category] or {}
end

function codex_module:get_season_packages(season_id)
  local info = self:get_season_info(season_id)
  if not info then
    return {}
  end
  return info.packages or {}
end

function codex_module:get_all_season_ids()
  local all_data = self:get_all_data()
  if not all_data then
    return {}
  end
  local seen = {}
  local ids = {}
  for _, data in pairs(all_data) do
    if not_null(data) and data.Type == CodexDataType.Creature and data.IsPackage and data.SeasonID ~= nil and data.SeasonID ~= 0 and not seen[data.SeasonID] then
      seen[data.SeasonID] = true
      table.insert(ids, data.SeasonID)
    end
  end
  table.sort(ids, function(a, b)
    return a < b
  end)
  return ids
end

function codex_module:get_season_all_creatures(season_id)
  local info = self:get_season_info(season_id)
  if not info then
    return {}
  end
  local all = {}
  for _, cat in ipairs({
    CategoryType.Fish,
    CategoryType.Insect,
    CategoryType.Shore
  }) do
    local list = info.category_data[cat]
    for _, d in ipairs(list) do
      table.insert(all, d)
    end
  end
  return all
end

function codex_module:get_season_unlocked_count(season_id)
  local all = self:get_season_all_creatures(season_id)
  local unlocked = 0
  for _, d in ipairs(all) do
    if d.IsUnlocked then
      unlocked = unlocked + 1
    end
  end
  return unlocked, #all
end

local CategoryToSubType = {
  [CategoryType.Fish] = CodexDataSubType.CreatureFish,
  [CategoryType.Insect] = CodexDataSubType.CreatureInsect,
  [CategoryType.Shore] = CodexDataSubType.CreatureSeaFood
}
local CategoryDisplayOrder = {
  [CategoryType.Fish] = 3,
  [CategoryType.Insect] = 2,
  [CategoryType.Shore] = 1
}
codex_module.SeasonCategoryType = CategoryType
codex_module.SeasonFishSubType = FishSubType

function codex_module:get_season_category_tab_cfgs()
  local cfgs = {}
  for category, sub_type in pairs(CategoryToSubType) do
    local sub_type_cfg = self:get_sub_type_cfg(sub_type)
    table.insert(cfgs, {
      category = category,
      sub_type = sub_type,
      icon_path = sub_type_cfg and sub_type_cfg.icon or "",
      name = sub_type_cfg and sub_type_cfg.subname or "",
      display_order = CategoryDisplayOrder[category] or 0
    })
  end
  table.sort(cfgs, function(a, b)
    return a.display_order > b.display_order
  end)
  return cfgs
end

return codex_module
