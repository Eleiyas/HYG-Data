crop_growth_module = crop_growth_module or {}

function crop_growth_module:get_cur_level()
  return CsCropGrowthModuleUtil.GetCurLevel()
end

function crop_growth_module:get_level_cfg(level)
  if level == nil or level <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BCropPlantLevelCfg), level)
end

function crop_growth_module:get_level_table()
  return ExcelDataUtil.get_table(typeof(BCropPlantLevelCfg))
end

function crop_growth_module:get_max_level()
  local level_table = self:get_level_table()
  local max_level = 0
  if level_table ~= nil then
    for level_id, _ in pairs(level_table) do
      if level_id > max_level then
        max_level = level_id
      end
    end
  end
  return max_level
end

function crop_growth_module:get_display_level()
  local cur_level = self:get_cur_level()
  local max_level = self:get_max_level()
  if cur_level < max_level then
    return cur_level
  end
  return max_level
end

function crop_growth_module:is_can_upgrade()
  local cur_level = self:get_cur_level()
  if cur_level > self:get_max_level() then
    return false
  end
  return self:is_level_issues_all_done(cur_level)
end

function crop_growth_module:get_issue_cfg(issue_id)
  if issue_id == nil or issue_id <= 0 then
    return nil
  end
  local cfg = ExcelDataUtil.get_value(typeof(BCropPlantIssueCfg), issue_id)
  if is_null(cfg) then
    return nil
  end
  return cfg
end

function crop_growth_module:get_rights_cfg(rights_id)
  if rights_id == nil or rights_id <= 0 then
    return nil
  end
  local cfg = ExcelDataUtil.get_value(typeof(BCropPlantRightsCfg), rights_id)
  if is_null(cfg) then
    return nil
  end
  return cfg
end

function crop_growth_module:get_rights_text_params(rights_cfg)
  local params = {}
  if rights_cfg == nil then
    return params
  end
  if string.is_valid(rights_cfg.contentidlist) then
    local item_id_list = lua_str_split(rights_cfg.contentidlist, ",", true)
    for _, item_id in ipairs(item_id_list) do
      if item_id ~= nil then
        if item_module:has_cfg_by_id(item_id) then
          local item_cfg = item_module:get_cfg_by_id(item_id)
          table.insert(params, item_cfg.name)
        else
          table.insert(params, tostring(item_id))
        end
      end
    end
    return params
  end
  if string.is_valid(rights_cfg.contenttaglist) then
    local tag_str_list = lua_str_split(rights_cfg.contenttaglist, ",", false)
    for _, tag in ipairs(tag_str_list) do
      table.insert(params, TagUtil.get_tag_name_in_game_by_string(tag))
    end
    return params
  end
  if string.is_valid(rights_cfg.contentparam) then
    local param_list = lua_str_split(rights_cfg.contentparam, ",", true)
    for _, param in ipairs(param_list) do
      if param ~= nil then
        table.insert(params, param)
      end
    end
    return params
  end
  return params
end

function crop_growth_module:get_issue_id_list(level)
  local result = {}
  local level_cfg = self:get_level_cfg(level)
  if level_cfg == nil then
    return result
  end
  for i = 0, level_cfg.issuelistLength - 1 do
    local issue_id = tonumber(level_cfg:issuelist(i))
    if issue_id ~= nil and 0 < issue_id then
      table.insert(result, issue_id)
    end
  end
  return result
end

function crop_growth_module:get_rights_id_list(level)
  local result = {}
  local level_cfg = self:get_level_cfg(level)
  if level_cfg == nil then
    return result
  end
  local galaxy_type = CsGameplayUtilitiesGalaxyUtil.GetSelectedGalaxyType()
  if galaxy_type == 2 then
    for i = 0, level_cfg.tafarightslistLength - 1 do
      local rights_id = tonumber(level_cfg:tafarightslist(i))
      if rights_id ~= nil and 0 < rights_id then
        table.insert(result, rights_id)
      end
    end
  else
    for i = 0, level_cfg.hexiarightslistLength - 1 do
      local rights_id = tonumber(level_cfg:hexiarightslist(i))
      if rights_id ~= nil and 0 < rights_id then
        table.insert(result, rights_id)
      end
    end
  end
  return result
end

function crop_growth_module:get_reward_item_list(level)
  local result = {}
  local level_cfg = self:get_level_cfg(level)
  if level_cfg == nil or not string.is_valid(level_cfg.itemrewardlist) then
    return result
  end
  local reward_str = level_cfg.itemrewardlist
  for pair_str in string.gmatch(reward_str, "([^,]+)") do
    local id_str, num_str = string.match(pair_str, "(%d+):(%d+)")
    local cfg_id = tonumber(id_str)
    local num = tonumber(num_str)
    if cfg_id ~= nil and 0 < cfg_id then
      table.insert(result, {
        id = cfg_id,
        num = num or 1
      })
    end
  end
  return result
end

return crop_growth_module
