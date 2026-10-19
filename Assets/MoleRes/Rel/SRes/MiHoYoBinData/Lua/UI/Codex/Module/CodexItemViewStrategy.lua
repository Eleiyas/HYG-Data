local M = G.Class("CodexItemViewStrategy", "UI/Codex/Module/CodexTypeViewStrategyBase")

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

function M:get_default_display_mode(_sub_type_info)
  return codex_module.CodexDisplayMode.Flat
end

function M:get_default_sort_mode()
  return codex_module.CodexSortMode.Default
end

function M:get_default_sort_order()
  return codex_module.CodexSortOrder.Ascending
end

function M:get_list_renderer_class(_display_mode)
  return "UI/Codex/Module/ListRenderer/CodexFlatSortableListRenderer"
end

function M:has_sub_type_badge()
  return false
end

function M:has_medals(_sub_type_controller)
  return false
end

function M:get_progress_style(_sub_type_controller)
  return "none"
end

function M:get_bg_state()
  return 0
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexItemTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypeMaterialPage"
end

local S = "UI/Codex/DetailPage/V2/Sections/"

function M:get_detail_section_configs(item_data)
  return {
    {
      section_key = "title",
      class_path = S .. "TitleSection",
      root_field = "_trans_info_basic"
    },
    {
      section_key = "source_list",
      class_path = S .. "SourceListSection",
      root_field = "_trans_get_from_list"
    },
    {
      section_key = "tag_group_list_after",
      class_path = S .. "TagGroupListSection",
      root_field = "_trans_tag_group_after"
    },
    {
      section_key = "describe",
      class_path = S .. "DescribeSection",
      root_field = "_trans_describe"
    }
  }
end

local ITEM_TAG_DEFS = {}

function M:get_detail_tags(item_data)
  if codex_module:is_package_sub_type(item_data.SubType) then
    return {}
  end
  local tags = {}
  local show_info = item_data.IsUnlocked
  for _, def in ipairs(ITEM_TAG_DEFS) do
    local value = show_info and def.get_value(item_data) or nil
    if show_info then
      if value and value ~= "" then
        table.insert(tags, {
          title_id = def.title_id,
          value = value,
          no_icon = true
        })
      end
    else
      table.insert(tags, {
        title_id = def.title_id,
        value = codex_module.default_lock_info,
        no_icon = true
      })
    end
  end
  local obtain_val
  if show_info then
    local sd = item_data.ServerData
    if not_null(sd) then
      obtain_val = tostring(sd.TotalObtainedCount)
    end
  end
  if show_info then
    if obtain_val and obtain_val ~= "" then
      table.insert(tags, {
        title_id = "Codex_ObtainCount",
        value = obtain_val,
        no_icon = true
      })
    end
  else
    table.insert(tags, {
      title_id = "Codex_ObtainCount",
      value = codex_module.default_lock_info,
      no_icon = true
    })
  end
  return tags
end

return M
