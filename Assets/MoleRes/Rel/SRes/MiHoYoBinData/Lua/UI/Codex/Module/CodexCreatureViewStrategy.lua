local M = G.Class("CodexCreatureViewStrategy", "UI/Codex/Module/CodexTypeViewStrategyBase")

function M:supports_grouping(_sub_type_info)
  return true
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

function M:get_default_display_mode()
  return codex_module.CodexDisplayMode.Grouped
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

function M:has_medals(sub_type_controller)
  return sub_type_controller and sub_type_controller:is_topic_unlocked()
end

function M:get_progress_style(sub_type_controller)
  if not sub_type_controller then
    return "standard"
  end
  local sub_type_cfg = sub_type_controller:get_sub_type_cfg()
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if tag then
    local cs_list = CsCodexModuleUtil.GetCreatureTagNumRewardListByTag(tag)
    if not_null(cs_list) and cs_list.Count > 0 then
      return "creature_tag"
    end
  end
  return "standard"
end

function M:has_sub_type_badge()
  return true
end

function M:get_bg_state()
  return 0
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexCreatureTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypeBiologyPage"
end

function M:get_progress_item_class()
  return "UI/Codex/TypePage/CodexSubtypeProgressItem2"
end

function M:get_detail_page_class()
  return "UI/Codex/ComplexDetailPage/ComplexCodexInfoPage"
end

local _creature_progress_title = {
  [CodexDataSubType.CreatureFish] = "Codex_Progress_CreatureFish",
  [CodexDataSubType.CreatureInsect] = "Codex_Progress_CreatureInsect",
  [CodexDataSubType.CreatureSeaFood] = "Codex_Progress_CreatureSeaFood"
}

function M:get_progress_title_key(sub_type_info)
  if not sub_type_info then
    return nil
  end
  return _creature_progress_title[sub_type_info.sub_type]
end

return M
