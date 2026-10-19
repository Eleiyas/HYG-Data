local M = G.Class("CodexFurnitureViewStrategy", "UI/Codex/Module/CodexTypeViewStrategyBase")

function M:supports_grouping(_sub_type_info)
  return false
end

function M:supports_sorting(_sub_type_info)
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
  if sub_type_info and codex_module:is_package_sub_type(sub_type_info.sub_type) then
    return codex_module.CodexDisplayMode.SetFlat
  end
  return codex_module.CodexDisplayMode.Flat
end

function M:get_list_renderer_class(display_mode)
  if display_mode == codex_module.CodexDisplayMode.SetFlat then
    return "UI/Codex/Module/ListRenderer/CodexSetFlatListRenderer"
  end
  return "UI/Codex/Module/ListRenderer/CodexFlatSortableListRenderer"
end

function M:get_list_mode(_display_mode)
  return "flat"
end

function M:has_medals(_sub_type_controller)
  return false
end

function M:get_progress_style(_sub_type_controller)
  return "tag_num"
end

function M:use_global_progress()
  return true
end

function M:get_tag_num_reward_type()
  return codex_module.TagNumRewardType.Global
end

function M:has_sub_type_badge()
  return false
end

function M:get_bg_state()
  return 1
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexFurnitureTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypeFurniturePage"
end

function M:get_progress_item_class()
  return "UI/Codex/TypePage/CodexSubtypeProgressItem1"
end

local S = "UI/Codex/DetailPage/V2/Sections/"

local function furn_tag_classify_display(item_data)
  local cfg = item_data.FurnTagClassifyCfg
  if is_null(cfg) or cfg.__empty then
    return nil
  end
  local parts = {}
  if cfg.fstname and cfg.fstname ~= "" then
    table.insert(parts, cfg.fstname)
  end
  if cfg.secname and cfg.secname ~= "" then
    table.insert(parts, cfg.secname)
  end
  if #parts == 0 then
    return nil
  end
  return table.concat(parts, "·")
end

local function furniture_entity_size_display(item_data)
  local ec = item_data.EntityCfg
  if is_null(ec) or ec.__empty then
    return nil
  end
  local sx = ec.sizex * 0.5
  local sz = ec.sizez * 0.5
  if sx <= 0 and sz <= 0 then
    return nil
  end
  return string.format("%s%s%s", TextMapFormatUtil.FormatDecimal(sx, 1), TextMapFormatUtil.GetMultiplySign(), TextMapFormatUtil.FormatDecimal(sz, 1))
end

function M:get_detail_section_configs(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return {
      {
        section_key = "title",
        class_path = S .. "TitleSection",
        root_field = "_trans_info_basic"
      },
      {
        section_key = "package_list",
        class_path = S .. "PackageListSection",
        root_field = "_trans_package_item_list"
      },
      {
        section_key = "package_reward",
        class_path = S .. "PackageRewardSection",
        root_field = "_trans_package_reward"
      },
      {
        section_key = "source_list",
        class_path = S .. "SourceListSection",
        root_field = "_trans_get_from_list"
      },
      {
        section_key = "story",
        class_path = S .. "StorySection",
        root_field = "_trans_story"
      }
    }
  else
    return {
      {
        section_key = "title",
        class_path = S .. "TitleSection",
        root_field = "_trans_info_basic"
      },
      {
        section_key = "tag_group_list",
        class_path = S .. "TagGroupListSection",
        root_field = "_trans_tag_group"
      },
      {
        section_key = "dyeing",
        class_path = S .. "DyeingSection",
        root_field = "_trans_dyeing"
      },
      {
        section_key = "package_info",
        class_path = S .. "PackageInfoSection",
        root_field = "_trans_package_info"
      },
      {
        section_key = "source_list",
        class_path = S .. "SourceListSection",
        root_field = "_trans_get_from_list"
      },
      {
        section_key = "describe",
        class_path = S .. "DescribeSection",
        root_field = "_trans_describe"
      }
    }
  end
end

local function get_furniture_floor_area(item_data)
  local ec = item_data.EntityCfg
  if is_null(ec) or ec.__empty then
    return nil
  end
  local sx = ec.sizex * 0.5
  local sz = ec.sizez * 0.5
  if sx <= 0 and sz <= 0 then
    return nil
  end
  return {x = sx, y = sz}
end

local TAG_DEFS = {
  {
    title_id = "Codex_Type",
    icon = "UISprite/Load/LayerIcon/Icon_Common_Tab_All_S",
    get_value = function(item_data)
      return furn_tag_classify_display(item_data)
    end
  },
  {
    title_id = "Codex_Size",
    get_value = function(item_data)
      return furniture_entity_size_display(item_data)
    end,
    get_floor_area = get_furniture_floor_area
  },
  {
    title_id = "Codex_Color",
    icon = "UISprite/Load/LayerIcon/Icon_Common_Dyeing_S",
    get_value = function(item_data)
      return codex_module:get_item_color_tag_name(nil, item_data.IdCfg)
    end
  },
  {
    title_id = "Codex_Material",
    icon = "UISprite/Load/LayerIcon/Icon_Common_Material_S",
    get_value = function(item_data)
      return codex_module:get_item_material_tag_name(nil, item_data.IdCfg)
    end
  }
}

function M:get_detail_tags(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return {}
  end
  local tags = {}
  for _, def in ipairs(TAG_DEFS) do
    local value = def.get_value(item_data)
    local tag = {
      title_id = def.title_id,
      icon = def.icon,
      value = value and value ~= "" and value or codex_module.default_lock_info
    }
    if def.get_floor_area then
      tag.floor_area = def.get_floor_area(item_data)
    end
    table.insert(tags, tag)
  end
  return tags
end

function M:get_progress_title_key(_sub_type_info)
  return "Codex_Progress_Furniture"
end

return M
