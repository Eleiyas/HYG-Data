local M = G.Class("CodexPlantViewStrategy", "UI/Codex/Module/CodexTypeViewStrategyBase")

function M:supports_grouping(sub_type_info)
  if sub_type_info and codex_module:is_package_sub_type(sub_type_info.sub_type) then
    return false
  end
  if not sub_type_info then
    return true
  end
  local st = sub_type_info.sub_type
  if st == CodexDataSubType.PlantGreen or st == CodexDataSubType.PlantCollect then
    return false
  end
  return true
end

function M:supports_sorting(sub_type_info)
  return true
end

function M:get_sort_options()
  return {
    {
      mode = codex_module.CodexSortMode.Default,
      text_key = "Codex_Sort_Default"
    },
    {
      mode = codex_module.CodexSortMode.Quality,
      text_key = "Codex_Sort_Quality"
    },
    {
      mode = codex_module.CodexSortMode.CollectTime,
      text_key = "Codex_Sort_CollectTime"
    }
  }
end

function M:get_default_display_mode(sub_type_info)
  if self:supports_grouping(sub_type_info) then
    return codex_module.CodexDisplayMode.Grouped
  end
  return codex_module.CodexDisplayMode.Flat
end

function M:get_default_sort_mode()
  return codex_module.CodexSortMode.Default
end

function M:get_default_sort_order()
  return codex_module.CodexSortOrder.Ascending
end

function M:get_list_mode(display_mode)
  if display_mode == codex_module.CodexDisplayMode.Grouped then
    return "grouped"
  end
  return "flat_sortable"
end

function M:get_list_renderer_class(display_mode)
  if display_mode == codex_module.CodexDisplayMode.Grouped then
    return "UI/Codex/Module/ListRenderer/CodexGroupedListRenderer"
  end
  return "UI/Codex/Module/ListRenderer/CodexFlatSortableListRenderer"
end

function M:has_medals(_sub_type_controller)
  return false
end

function M:get_progress_style(_sub_type_controller)
  return "tag_num"
end

function M:get_tag_num_reward_type()
  return codex_module.TagNumRewardType.PerTab
end

function M:should_show_progress_item(sub_type_info)
  if not sub_type_info then
    return true
  end
  local sub_type = sub_type_info.sub_type
  return sub_type ~= CodexDataSubType.PlantGreen and sub_type ~= CodexDataSubType.PlantCollect
end

local PLANT_GROUP_SUB_TYPES = {
  [CodexDataSubType.PlantCrop] = true,
  [CodexDataSubType.PlantFlower] = true
}

local function get_plant_group_id(item_data)
  if is_null(item_data) or is_null(item_data.ItemCfg) then
    return 0
  end
  return item_data.ItemCfg.setid or 0
end

function M:_ensure_group(group_map, group_order, group_id)
  local group = group_map[group_id]
  if group then
    return group
  end
  group = {
    group_id = group_id,
    item_ids = {},
    item_id_map = {},
    package_data = codex_module:get_data_by_id(group_id)
  }
  group_map[group_id] = group
  table.insert(group_order, group)
  return group
end

function M:_append_group_item(group, item_id)
  if group.item_id_map[item_id] then
    return
  end
  group.item_id_map[item_id] = true
  table.insert(group.item_ids, item_id)
end

function M:_fill_group_from_package(group, package_data)
  if is_null(package_data) or is_null(package_data.PackageItemIds) then
    return
  end
  for i = 0, package_data.PackageItemIds.Count - 1 do
    self:_append_group_item(group, package_data.PackageItemIds[i])
  end
end

function M:_build_virtual_package_data(group)
  if not is_null(group.package_data) then
    return group.package_data
  end
  local unlocked_count = 0
  for _, item_id in ipairs(group.item_ids) do
    local item_data = codex_module:get_data_by_id(item_id)
    if not is_null(item_data) and item_data.IsUnlocked then
      unlocked_count = unlocked_count + 1
    end
  end
  return {
    IdCfg = ExcelDataUtil.get_value(typeof(BIdCfg), group.group_id),
    CodexCfg = ExcelDataUtil.get_value(typeof(BCodexCfg), group.group_id),
    Type = CodexDataType.Plant,
    IsVirtualPackage = true,
    unlockCount = unlocked_count,
    allCount = #group.item_ids
  }
end

function M:_get_group_display_priority(group)
  local codex_cfg = ExcelDataUtil.get_value(typeof(BCodexCfg), group.group_id)
  if is_null(codex_cfg) then
    return 0
  end
  return codex_cfg.displaypriority or 0
end

function M:get_grouped_package_list(sub_type_controller)
  if not sub_type_controller or not PLANT_GROUP_SUB_TYPES[sub_type_controller.sub_type] then
    return nil
  end
  local all_data = sub_type_controller._item_id_to_data_tbl
  if not all_data then
    return nil
  end
  local group_map = {}
  local group_order = {}
  for item_id, item_data in pairs(all_data) do
    if not item_data.IsPackage then
      local group_id = get_plant_group_id(item_data)
      if group_id and 0 < group_id then
        local group = self:_ensure_group(group_map, group_order, group_id)
        self:_append_group_item(group, item_id)
      end
    end
  end
  for _, data in pairs(all_data) do
    if data.IsPackage then
      local group_id = data.IdCfg and data.IdCfg.id or 0
      if 0 < group_id then
        local group = self:_ensure_group(group_map, group_order, group_id)
        group.package_data = data
        self:_fill_group_from_package(group, data)
      end
    end
  end
  for _, group in ipairs(group_order) do
    group.package_data = self:_build_virtual_package_data(group)
  end
  table.sort(group_order, function(a, b)
    local package_a = a.package_data
    local package_b = b.package_data
    local seasonal_a = not is_null(package_a) and codex_module:is_seasonal(package_a) or false
    local seasonal_b = not is_null(package_b) and codex_module:is_seasonal(package_b) or false
    if seasonal_a ~= seasonal_b then
      return seasonal_a
    end
    local priority_a = self:_get_group_display_priority(a)
    local priority_b = self:_get_group_display_priority(b)
    if priority_a ~= priority_b then
      return priority_a > priority_b
    end
    return a.group_id < b.group_id
  end)
  return group_order
end

function M:has_sub_type_badge()
  return true
end

function M:get_bg_state()
  return 0
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexPlantTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypePlantsPage"
end

function M:get_progress_item_class()
  return "UI/Codex/TypePage/CodexSubtypeProgressItem2"
end

local S = "UI/Codex/DetailPage/V2/Sections/"

function M:get_detail_section_configs(item_data)
  local sections = {
    {
      section_key = "title",
      class_path = S .. "TitleSection",
      root_field = "_trans_info_basic"
    }
  }
  table.insert(sections, {
    section_key = "growth_stage",
    class_path = S .. "GrowthStageSection",
    root_field = "_trans_state_seed"
  })
  table.insert(sections, {
    section_key = "tag_group_list",
    class_path = S .. "TagGroupListSection",
    root_field = "_trans_tag_group"
  })
  if item_data.SubType == CodexDataSubType.PlantGreen then
    table.insert(sections, {
      section_key = "plant_product",
      class_path = S .. "PlantProductSection",
      root_field = "_trans_plants_product"
    })
  end
  table.insert(sections, {
    section_key = "info_list",
    class_path = S .. "InfoListSection",
    root_field = "_trans_info_list"
  })
  table.insert(sections, {
    section_key = "describe",
    class_path = S .. "DescribeSection",
    root_field = "_trans_describe"
  })
  return sections
end

local PLANT_TAG_DEFS = {
  {
    title_id = "Codex_Galaxies",
    get_value = function(item_data)
      local name = codex_module:get_item_area_tag_name(nil, item_data.IdCfg)
      if not name or name == "" then
        name = UIUtil.get_text_by_id("Codex_Galaxy_All")
      end
      return name
    end
  }
}

function M:_is_info_visible(item_data)
  if item_data.IsUnlocked then
    return true
  end
  local sd = item_data.ServerData
  if not_null(sd) and not_null(sd.CropPlant) and sd.CropPlant.FirstSeedObtainedTime > 0 then
    return true
  end
  if not_null(sd) and not_null(sd.FlowerItem) and 0 < sd.FlowerItem.FirstSeedObtainedTime then
    return true
  end
  if not_null(sd) and not_null(sd.MatureTree) then
    if 0 < sd.MatureTree.FirstSeedObtainedTime then
      return true
    end
    local fruit = sd.MatureTree.FruitDetail
    if not_null(fruit) and 0 < fruit.FruitItemId and 0 < fruit.HarvestedCount then
      return true
    end
  end
  return false
end

function M:_add_tag(tags, title_id, value, show_info, no_icon)
  if show_info then
    if value and value ~= "" then
      table.insert(tags, {
        title_id = title_id,
        value = value,
        no_icon = no_icon
      })
    end
  else
    table.insert(tags, {
      title_id = title_id,
      value = codex_module.default_lock_info,
      no_icon = no_icon
    })
  end
end

function M:get_detail_tags(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return {}
  end
  local tags = {}
  local show_info = self:_is_info_visible(item_data)
  local st = item_data.SubType
  for _, def in ipairs(PLANT_TAG_DEFS) do
    local value = show_info and def.get_value(item_data) or nil
    self:_add_tag(tags, def.title_id, value, show_info, true)
  end
  if st == CodexDataSubType.PlantCollect then
    local obtain_val
    if show_info then
      local sd = item_data.ServerData
      if not_null(sd) then
        obtain_val = tostring(sd.TotalObtainedCount)
      end
    end
    self:_add_tag(tags, "Codex_ObtainCount", obtain_val, show_info, true)
    return tags
  end
  local plant_cfg = self:_get_crop_plant_cfg(item_data)
  if not_null(plant_cfg) then
    local cycle_val
    if show_info then
      local day_count = self:_get_crop_maturity_days(plant_cfg)
      local day_text = UIUtil.get_text_by_id("Codex_Day", day_count)
      cycle_val = day_text
    end
    self:_add_tag(tags, "Codex_MaturityCycle", cycle_val, show_info, true)
  else
    local stage_count = self:_get_flower_or_tree_stage_count(item_data)
    if stage_count and 0 < stage_count then
      local day_text = UIUtil.get_text_by_id("Codex_Day", stage_count)
      local cycle_val = show_info and day_text
      self:_add_tag(tags, "Codex_MaturityCycle", cycle_val, show_info, true)
    end
  end
  if st == CodexDataSubType.PlantCrop then
    local crop_data = item_data.CropPlantDetail
    if not_null(crop_data) and not_null(plant_cfg) then
      local round_val
      if show_info and 0 < plant_cfg.growthround then
        round_val = tostring(plant_cfg.growthround)
      end
      self:_add_tag(tags, "Codex_StemCount", round_val, show_info, true)
    end
  end
  if st ~= CodexDataSubType.PlantGreen then
    local harvest_val
    if show_info then
      harvest_val = self:_get_harvest_count_text(item_data)
    end
    self:_add_tag(tags, "Codex_HarvestCount", harvest_val, show_info, true)
  end
  return tags
end

function M:_get_crop_plant_cfg(item_data)
  local seed_id = item_data.SeedItemId
  if seed_id and 0 < seed_id then
    return ExcelDataUtil.get_value(typeof(BCropPlantCfg), seed_id)
  end
  return nil
end

function M:_get_crop_maturity_days(plant_cfg)
  if is_null(plant_cfg) then
    return 0
  end
  local day_count = plant_cfg.nonfirstroundseedlingidlistLength or 0
  if day_count <= 0 then
    day_count = plant_cfg.stageseedlingidlistLength or 0
  end
  return day_count
end

function M:_get_harvest_count_text(item_data)
  if is_null(item_data) then
    return nil
  end
  local sd = item_data.ServerData
  if item_data.IsFruitKing then
    if not_null(sd) then
      return tostring(sd.TotalObtainedCount or 0)
    end
    return nil
  end
  if item_data.SubType == CodexDataSubType.PlantCrop then
    local crop = item_data.CropPlantDetail
    if not_null(crop) then
      return tostring(crop.HarvestedFruitCount)
    end
    return nil
  end
  if not_null(sd) then
    return tostring(sd.TotalObtainedCount)
  end
  return nil
end

function M:_get_flower_or_tree_stage_count(item_data)
  local codex_id = item_data and item_data.ServerData and item_data.ServerData.Id or 0
  if codex_id == 0 then
    return 0
  end
  local bloom_id = codex_module:get_flower_bloom_id(codex_id)
  if bloom_id then
    local chain = codex_module:get_plant_stage_chain(bloom_id) or {}
    return math.max(#chain - 1, 0)
  end
  local sd = item_data.ServerData
  if not_null(sd) and not_null(sd.MatureTree) then
    local stage_times = sd.MatureTree.StageTimes
    if not_null(stage_times) then
      return stage_times.Count
    end
  end
  return 0
end

function M:_is_mushroom(item_data)
  local id = item_data.ServerData and item_data.ServerData.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.organism_plant_lowplant_mushroom)
end

function M:_is_weed(item_data)
  local id = item_data.ServerData and item_data.ServerData.Id or 0
  return 0 < id and CsGameplayTagUtilUtil.ConfigHasTag(id, EntityTagTags.Tags.organism_plant_lowplant_grass)
end

function M:_get_fruit_item_id(item_data)
  local sd = item_data and item_data.ServerData
  if is_null(sd) or is_null(sd.MatureTree) then
    return 0
  end
  local fruit = sd.MatureTree.FruitDetail
  if is_null(fruit) then
    return 0
  end
  return fruit.FruitItemId or 0
end

function M:get_detail_info_list(item_data)
  return {}
end

local _plant_progress_title = {
  [CodexDataSubType.PlantCrop] = "Codex_Progress_PlantCrop",
  [CodexDataSubType.PlantFlower] = "Codex_Progress_PlantFlower",
  [CodexDataSubType.PlantGreen] = "Codex_Progress_PlantGreen",
  [CodexDataSubType.PlantCollect] = "Codex_Progress_PlantCollect"
}

function M:get_progress_title_key(sub_type_info)
  if not sub_type_info then
    return nil
  end
  return _plant_progress_title[sub_type_info.sub_type]
end

return M
