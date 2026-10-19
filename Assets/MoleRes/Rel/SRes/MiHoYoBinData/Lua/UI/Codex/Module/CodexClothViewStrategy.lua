local M = G.Class("CodexClothViewStrategy", "UI/Codex/Module/CodexFurnitureViewStrategy")

function M:get_bg_state()
  return 0
end

function M:get_detail_page_class()
  return "UI/Codex/DetailPage/ClothCodexDetailPage"
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexClothTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypeClothingPage"
end

local S = "UI/Codex/DetailPage/V2/Sections/"

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
        section_key = "story",
        class_path = S .. "StorySection",
        root_field = "_trans_story"
      },
      {
        section_key = "source_list",
        class_path = S .. "SourceListSection",
        root_field = "_trans_get_from_list"
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

local CLOTH_TAG_DEFS = {
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
  },
  {
    title_id = "Codex_Style",
    icon = "UISprite/Load/LayerIcon/Icon_Common_Cloth_Style_S",
    get_value = function(item_data)
      return codex_module:get_item_style_tag_name(nil, item_data.IdCfg)
    end
  }
}

function M:get_detail_tags(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return {}
  end
  local tags = {}
  for _, def in ipairs(CLOTH_TAG_DEFS) do
    local value = def.get_value(item_data)
    if value and value ~= "" then
      table.insert(tags, {
        title_id = def.title_id,
        icon = def.icon,
        value = value
      })
    else
      table.insert(tags, {
        title_id = def.title_id,
        icon = def.icon,
        value = codex_module.default_lock_info
      })
    end
  end
  return tags
end

function M:get_progress_title_key(_sub_type_info)
  return "Codex_Progress_Cloth"
end

return M
