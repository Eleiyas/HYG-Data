local M = G.Class("CodexFoodViewStrategy", "UI/Codex/Module/CodexTypeViewStrategyBase")
M.FoodUnlockState = {
  Unknown = 0,
  PartialUnlocked = 1,
  RecipeLearned = 2,
  Cooked = 3
}

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

function M:get_default_display_mode(_sub_type_info)
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
  return "flat"
end

function M:get_list_renderer_class(display_mode)
  if display_mode == codex_module.CodexDisplayMode.Grouped then
    return "UI/Codex/Module/ListRenderer/CodexGroupedListRenderer"
  end
  return "UI/Codex/Module/ListRenderer/CodexFlatListRenderer"
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

function M:has_sub_type_badge()
  return true
end

function M:get_bg_state()
  return 0
end

function M:get_type_page_class()
  return "UI/Codex/TypePage/CodexFoodTypePage"
end

function M:get_type_page_prefab()
  return "UI/Codex/CodexSubtypeCookPage"
end

function M:get_progress_item_class()
  return "UI/Codex/TypePage/CodexSubtypeProgressItem2"
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
      section_key = "info_list",
      class_path = S .. "InfoListSection",
      root_field = "_trans_info_list"
    },
    {
      section_key = "personal_record",
      class_path = S .. "PersonalRecordSection",
      root_field = "_trans_record"
    },
    {
      section_key = "effect",
      class_path = S .. "EffectSection",
      root_field = "_trans_effect"
    },
    {
      section_key = "describe",
      class_path = S .. "DescribeSection",
      root_field = "_trans_describe"
    }
  }
end

function M:get_detail_tags(_item_data)
  return {}
end

function M:get_food_category_name(item_data)
  local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
  if not recipe_cfg or recipe_cfg.category == 0 then
    return nil
  end
  local cat_cfg = ExcelDataUtil.get_value(typeof(BCookRecipeCategoryCfg), recipe_cfg.category)
  if is_null(cat_cfg) then
    return nil
  end
  local desc = cat_cfg.desc
  return string.is_valid(desc) and desc or nil
end

function M:get_secret_recipe_npc_id(item_data)
  local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
  if not recipe_cfg then
    return 0
  end
  local npc_id = recipe_cfg.secretnpcid
  if npc_id and 0 < npc_id then
    return npc_id
  end
  return 0
end

function M:get_food_unlock_state(item_data)
  if item_data.IsCooked then
    return M.FoodUnlockState.Cooked
  end
  local recipe_id = item_data.DefaultRecipeId
  if recipe_id and 0 < recipe_id and CsCookModuleUtil.CookRecipeIsLearned(recipe_id) then
    return M.FoodUnlockState.RecipeLearned
  end
  if item_data.HasNonCookingObtained then
    return M.FoodUnlockState.PartialUnlocked
  end
  if item_data.IsUnlocked then
    return M.FoodUnlockState.PartialUnlocked
  end
  local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
  if recipe_cfg and 0 < recipe_cfg.category and recipe_cfg.recipetypestr ~= "SECRET" and CsCookModuleUtil.CategoryIsUnlockById(recipe_cfg.category) then
    return M.FoodUnlockState.PartialUnlocked
  end
  return M.FoodUnlockState.Unknown
end

function M:_resolve_tag_display(tag_expression, fallback_icon)
  local icon = fallback_icon or ""
  local name = ""
  for tag in string.gmatch(tag_expression, "[^&]+") do
    local t_icon = TagUtil.get_tag_icon_by_string(tag)
    local t_name = TagUtil.get_tag_name_in_game_by_string(tag)
    if not string.is_valid(icon) and string.is_valid(t_icon) then
      icon = t_icon
    end
    if not string.is_valid(name) and string.is_valid(t_name) then
      name = t_name
    end
  end
  return icon, name
end

function M:is_npc_secret_recipe(item_data)
  local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
  return recipe_cfg ~= nil and recipe_cfg.recipetypestr == "SECRET"
end

function M:is_recipe_learned(item_data)
  local recipe_id = item_data.DefaultRecipeId
  return recipe_id ~= nil and 0 < recipe_id and CsCookModuleUtil.CookRecipeIsLearned(recipe_id)
end

function M:should_show_recipe_info(item_data)
  local state = self:get_food_unlock_state(item_data)
  if state >= M.FoodUnlockState.RecipeLearned then
    return true
  end
  if state == M.FoodUnlockState.PartialUnlocked then
    local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
    if recipe_cfg and recipe_cfg.category > 0 then
      return CsCookModuleUtil.CategoryIsUnlockById(recipe_cfg.category)
    end
  end
  return false
end

function M:_get_cook_recipe_cfg(item_data)
  local recipe_id = item_data.DefaultRecipeId
  if not recipe_id or recipe_id <= 0 then
    return nil
  end
  local cfg = ExcelDataUtil.get_value(typeof(BCookRecipeCfg), recipe_id)
  if is_null(cfg) then
    return nil
  end
  return cfg
end

function M:get_detail_info_list(item_data)
  local info_list = {}
  local unlock_state = self:get_food_unlock_state(item_data)
  local show_full_recipe = unlock_state >= M.FoodUnlockState.RecipeLearned
  local recipe_cfg = self:_get_cook_recipe_cfg(item_data)
  if unlock_state > M.FoodUnlockState.Unknown then
    local flavor = codex_module:get_item_area_tag_name(nil, item_data.IdCfg)
    if not string.is_valid(flavor) then
      flavor = CsGameplayTagUtilUtil.GetTagNameInGame(EntityTagTags.Tags.nativerange_cookingstyle_cooking_all)
    end
    table.insert(info_list, {
      type = "text",
      title = UIUtil.get_text_by_id("Codex_FoodFlavor") or "",
      value = flavor
    })
  end
  local cookware_name = codex_module.default_lock_info
  local cookware_id = 0
  if show_full_recipe then
    local recipe_id = item_data.DefaultRecipeId
    if recipe_id and 0 < recipe_id then
      cookware_id = CsGameplayUtilitiesCookUtil.GetCookWareCfgIdByRecipeId(recipe_id)
    end
    if 0 < cookware_id then
      local cookware_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), cookware_id)
      if not_null(cookware_cfg) then
        cookware_name = cookware_cfg.name
      end
    end
  end
  table.insert(info_list, {
    type = "cookware",
    title = UIUtil.get_text_by_id("Codex_Cookware") or "",
    value = cookware_name,
    cookware_id = cookware_id,
    locked = not show_full_recipe
  })
  local recipe_items = {}
  if show_full_recipe and recipe_cfg then
    local infos = list_to_table(recipe_cfg.IngredientInfos)
    for _, info in ipairs(infos) do
      if not info.IsNull then
        if 0 < info.id then
          local icon_path = ""
          local tag_name = ""
          local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), info.id)
          if not_null(item_cfg) then
            icon_path = item_cfg.tooltableicon
            tag_name = item_cfg.name
          end
          table.insert(recipe_items, {
            template_type = "item",
            icon = icon_path,
            tag_name = tag_name,
            id = info.id,
            locked = false
          })
        elseif string.is_valid(info.tag) then
          local or_parts = {}
          for part in string.gmatch(info.tag, "[^|]+") do
            table.insert(or_parts, part)
          end
          if 2 <= #or_parts then
            local tags = {}
            for _, or_part in ipairs(or_parts) do
              local t_icon, t_name = self:_resolve_tag_display(or_part, info.iconPath)
              table.insert(tags, {
                icon = t_icon,
                name = t_name,
                tag_str = or_part
              })
            end
            table.insert(recipe_items, {
              template_type = "twotab",
              tags = tags,
              locked = false
            })
          else
            local tag_expr = or_parts[1] or info.tag
            local and_parts = {}
            for part in string.gmatch(tag_expr, "[^&]+") do
              table.insert(and_parts, part)
            end
            if 2 <= #and_parts then
              local tags = {}
              for _, and_part in ipairs(and_parts) do
                local t_icon = TagUtil.get_tag_icon_by_string(and_part)
                local t_name = TagUtil.get_tag_name_in_game_by_string(and_part)
                if not string.is_valid(t_icon) then
                  t_icon = info.iconPath or ""
                end
                table.insert(tags, {
                  icon = t_icon,
                  name = t_name,
                  tag_str = and_part
                })
              end
              table.insert(recipe_items, {
                template_type = "twotab",
                tags = tags,
                locked = false
              })
            else
              local icon_path, tag_name = self:_resolve_tag_display(tag_expr, info.iconPath)
              table.insert(recipe_items, {
                template_type = "onetab",
                tags = {
                  {
                    icon = icon_path,
                    name = tag_name,
                    tag_str = tag_expr
                  }
                },
                locked = false
              })
            end
          end
        end
      end
    end
  else
    if recipe_cfg then
      local infos = list_to_table(recipe_cfg.IngredientInfos)
      for _, info in ipairs(infos) do
        if not info.IsNull then
          table.insert(recipe_items, {template_type = "item", locked = true})
        end
      end
    end
    if #recipe_items == 0 then
      table.insert(recipe_items, {template_type = "item", locked = true})
    end
  end
  if 0 < #recipe_items then
    table.insert(info_list, {
      type = "recipe",
      title = UIUtil.get_text_by_id("Codex_Ingredients") or "",
      items = recipe_items,
      locked = not show_full_recipe
    })
  end
  return info_list
end

function M:get_personal_record_list(item_data)
  local records = {}
  local unlock_state = self:get_food_unlock_state(item_data)
  if unlock_state < M.FoodUnlockState.Cooked then
    return records
  end
  local recipe_id = item_data.DefaultRecipeId
  if not recipe_id or recipe_id <= 0 then
    return records
  end
  local recipe_data = CsCookModuleUtil.GetCookRecipeDataById(recipe_id)
  if is_null(recipe_data) then
    return records
  end
  local cook_count = recipe_data.CookCount or 0
  table.insert(records, {
    title = UIUtil.get_text_by_id("Codex_CookCount") or "",
    value = tostring(cook_count)
  })
  local lv = recipe_data.Lv or 0
  if 0 < lv then
    table.insert(records, {
      title = UIUtil.get_text_by_id("Codex_ProficiencyLevel") or "",
      value = tostring(lv)
    })
  end
  return records
end

function M:get_progress_title_key(_sub_type_info)
  return "Codex_Progress_Food"
end

return M
