local M = G.Class("CodexTypeViewStrategyBase")

function M:__ctor()
end

function M:supports_grouping(_sub_type_info)
  return false
end

function M:supports_sorting(_sub_type_info)
  return false
end

function M:get_sort_options()
  return {}
end

function M:get_default_display_mode(sub_type_info)
  return codex_module.CodexDisplayMode.Flat
end

function M:get_default_sort_mode()
  return codex_module.CodexSortMode.Default
end

function M:get_default_sort_order()
  return codex_module.CodexSortOrder.Ascending
end

function M:get_list_mode(display_mode)
  return "flat"
end

function M:get_list_renderer_class(display_mode)
  return "UI/Codex/Module/ListRenderer/CodexFlatListRenderer"
end

function M:has_medals(_sub_type_controller)
  return false
end

function M:get_progress_style(_sub_type_controller)
  return "standard"
end

function M:get_tag_num_reward_type()
  return nil
end

function M:should_show_progress_item(_sub_type_info)
  return true
end

function M:get_grouped_package_list(_sub_type_controller)
  return nil
end

function M:has_sub_type_badge()
  return true
end

function M:get_bg_state()
  return 0
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexPage"
end

function M:get_progress_title_key(_sub_type_info)
  return nil
end

function M:get_progress_item_class()
  return nil
end

function M:get_bg_item_class()
  return nil
end

function M:get_detail_page_class()
  return "UI/Codex/DetailPage/ItemDetailPageV2"
end

function M:get_detail_section_configs(item_data)
  return {}
end

return M
