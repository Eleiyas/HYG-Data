cooking_module = cooking_module or {}

function cooking_module:add_event()
  cooking_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowCookTipsInfo] = pack(self, cooking_module.show_cook_tips_info)
  self._events[EventID.OnCookRecipeDataChangeNotify] = pack(self, cooking_module._on_cook_recipe_data_change_notify)
  self._events[EventID.OnCookwareSwitchRsp] = pack(self, cooking_module._on_cookware_switch_rsp)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function cooking_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function cooking_module:get_have_added_ingredient_volume(cells, info, tbl_use_cfg_id)
  local volume = 0
  tbl_use_cfg_id = tbl_use_cfg_id or {}
  local cur_info_cfg_ids = {}
  for _, cell in pairs(cells) do
    if 0 < cell.num and tbl_use_cfg_id[cell.server_data.ConFigID] == nil then
      local is_set_volume = false
      if string.is_valid(info.tag) then
        if CsCookManagerUtil.CheckFoodHasTag(cell.server_data.ConFigID, info.tag) then
          is_set_volume = true
        end
      elseif cell.server_data.ConFigID == info.id then
        is_set_volume = true
      end
      if is_set_volume then
        volume = volume + 1 * cell.num
        cur_info_cfg_ids[cell.server_data.ConFigID] = 1
        if volume >= info.minSize then
          break
        end
      end
    end
  end
  for id, _ in pairs(cur_info_cfg_ids) do
    tbl_use_cfg_id[id] = 1
  end
  return volume
end

function cooking_module:get_cook_recipe_ingredients_lack_num(cells, cook_recipe_id)
  if cook_recipe_id <= 0 then
    return false
  end
  local cook_recipe_cfg = LocalDataUtil.get_value(typeof(CS.BCookRecipeCfg), cook_recipe_id)
  if is_null(cook_recipe_cfg) then
    return {}
  end
  local infos = list_to_table(cook_recipe_cfg.IngredientInfos)
  local ret_lst = {}
  for i, info in ipairs(infos) do
    if info ~= nil then
      local volume = cooking_module:get_have_added_ingredient_volume(cells, info)
      ret_lst[i] = {
        info = info,
        num = math.max(info.minSize - volume, 0)
      }
    end
  end
  for _, infos in ipairs(list_to_table(cook_recipe_cfg.Condiments)) do
    local is_add = true
    local add_lst = {}
    for i, info in ipairs(list_to_table(infos)) do
      if info ~= nil then
        if not string.is_valid(info.tag) then
          is_add = false
          break
        end
        if back_bag_module:get_packet_data():GetItemNumByTagExpression(info.tag) < info.minSize then
          is_add = false
          break
        end
        local volume = cooking_module:get_have_added_ingredient_volume(cells, info)
        table.insert(add_lst, {
          info = info,
          num = math.max(info.minSize - volume, 0)
        })
      end
    end
    if is_add and 0 < #add_lst then
      for _, ad_data in ipairs(add_lst) do
        table.insert(ret_lst, ad_data)
      end
      break
    end
  end
  return ret_lst
end

function cooking_module:get_one_ingredient_type_info(info)
  if info == nil then
    return {}
  end
  local item_ids = cooking_module:get_item_ids_by_ingredient_info(info)
  table.sort(item_ids, function(id1, id2)
    local cfg1 = item_module:get_cfg_by_id(id1)
    local cfg2 = item_module:get_cfg_by_id(id2)
    return cfg1.rank < cfg2.rank
  end)
  local add_info = {
    items = {},
    need_volume = info.minSize
  }
  for _, item_id in ipairs(item_ids) do
    local items = list_to_table(back_bag_module:get_packet_data():GetItemsByCfgId(item_id))
    if 0 < #items then
      table.sort(items, function(item1, item2)
        return item1.StarLevel < item2.StarLevel
      end)
      local food_size = CsCookManagerUtil.GetFoodSize(item_id)
      if 0 < food_size then
        local has_items = {}
        for i, item in ipairs(items) do
          table.insert(has_items, item)
        end
        table.insert(add_info.items, has_items)
      end
    end
  end
  return add_info
end

function cooking_module:bag_has_recipe_ingredients(recipe_id)
  if recipe_id <= 0 then
    return false
  end
  local cook_recipe_cfg = LocalDataUtil.get_value(typeof(CS.BCookRecipeCfg), recipe_id)
  if is_null(cook_recipe_cfg) then
    return false
  end
  local infos = list_to_table(cook_recipe_cfg.IngredientInfos)
  local tbl_use_cfg_id = {}
  for _, info in ipairs(infos) do
    if info ~= nil then
      local cur_info_cfg_ids = {}
      local ingredient_info = cooking_module:get_one_ingredient_type_info(info)
      if ingredient_info then
        for i, items in ipairs(ingredient_info.items) do
          for index, item in ipairs(items) do
            if tbl_use_cfg_id[item.ConFigID] == nil then
              cur_info_cfg_ids[item.ConFigID] = 1
              local food_size = CsCookManagerUtil.GetFoodSize(item.ConFigID)
              ingredient_info.need_volume = ingredient_info.need_volume - item.Count * food_size
              if 0 >= ingredient_info.need_volume then
                break
              end
            end
          end
          if 0 >= ingredient_info.need_volume then
            break
          end
        end
        if 0 < ingredient_info.need_volume then
          return false
        end
        for id, _ in pairs(cur_info_cfg_ids) do
          tbl_use_cfg_id[id] = 1
        end
      end
    end
  end
  return true
end

function cooking_module:get_item_ids_by_ingredient_info(info)
  if info.IsNull then
    return {}
  end
  local item_ids
  if info.id > 0 then
    item_ids = {
      info.id
    }
  else
    item_ids = list_to_table(CsCookManagerUtil.GetFoodByTag(info.tag))
  end
  return item_ids
end

function cooking_module:get_all_cook_recipe_red_state_by_cur_cook_ware_guid(guid)
  local all_recipe = list_to_table(CsCookModuleUtil.GetCookRecipeByCookwareGuid(guid))
  for _, recipe in pairs(all_recipe) do
    if cooking_module:get_cook_recipe_red_state(recipe.Id) then
      return true
    end
  end
  return false
end

function cooking_module:get_cook_recipe_red_state(recipe_id)
  if is_null(recipe_id) or recipe_id <= 0 then
    return false
  end
  return not red_point_module:is_recorded_with_id(red_point_module.red_point_type.cook_recipe, recipe_id)
end

function cooking_module:set_cook_recipe_red_state_to_read(recipe_id)
  if is_null(recipe_id) or recipe_id <= 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.cook_recipe, recipe_id)
end

function cooking_module:check_strength_up_before_eat(make_guid, callback)
  if CsCookUtil.TryGetStamina() >= CsCookUtil.TryGetFoodPowerRecovery(make_guid) then
    local data = {
      info_txt = UIUtil.get_text_by_id("Confirm_Text_EatRepeat"),
      yes_txt = UIUtil.get_text_by_id("Confirm_Text_EatRepeat_Continue"),
      no_txt = UIUtil.get_text_by_id("Confirm_Text_EatRepeat_Cancel"),
      yes_callback = callback
    }
    CsUIUtil.ShowDialogPage("Player", data.info_txt, true, data.yes_txt, callback, data.no_txt)
  else
    callback()
  end
end

function cooking_module:cook_recipe_is_can_make(recipe_id)
  local infos = cooking_module:get_ingredient_infos_by_id(recipe_id)
  for _, info in ipairs(infos) do
    if not info.IsNull then
      local ids
      if info.id > 0 then
        ids = {
          info.id
        }
      else
        ids = list_to_table(back_bag_module:get_packet_data():GetItemIdsByTagExpression(info.tag))
      end
      local need_num = info.minSize
      for i, id in ipairs(ids) do
        if need_num <= 0 then
          break
        end
        local surplus_num = back_bag_module:get_item_num(id)
        if 0 < surplus_num then
          need_num = need_num - surplus_num
        end
      end
      if 0 < need_num and not info.isCondiment then
        return false
      end
    end
  end
  return true
end

function cooking_module:get_unlock_cookware_ids()
  return list_to_table(CsCookModuleUtil.GetUnlockCookwareIds())
end

function cooking_module:cookware_is_unlock(id)
  return CsCookModuleUtil.CookwareIsUnlock(id)
end

function cooking_module:_on_cook_recipe_data_change_notify(data)
  local last_data = data.lastData
  local new_data = CsCookModuleUtil.GetCookRecipeDataById(last_data.Id)
  local add_proficiency = 0
  if not data.isNewRecipe then
    add_proficiency = new_data.ProficiencyRatio - last_data.ProficiencyRatio
    if add_proficiency <= 0 then
      return
    end
  end
  local info = {
    recipeId = new_data.Id,
    curProficiency = new_data.ProficiencyRatio,
    addProficiency = add_proficiency,
    isLearn = data.isNewRecipe,
    lv = new_data.Lv,
    isLvUp = new_data.Lv > last_data.Lv and new_data.ProficiencyRatio < 100
  }
  if data.reason == cooking_module.recipe_change_reason.use_item or data.reason == cooking_module.recipe_change_reason.unlock_by_use then
    player_module:play_learn_anim(last_data.Id, function()
      cooking_module:show_cook_tips_info(info)
    end)
  else
    cooking_module:show_cook_tips_info(info)
  end
end

function cooking_module:_on_cookware_switch_rsp(new_id)
  cooking_module:set_cur_selected_cook_ware_cfg_id(new_id)
  lua_event_module:send_event(lua_event_module.event_type.cookware_switch)
end

function cooking_module:get_ingredient_infos_by_id(recipe_id)
  if recipe_id <= 0 then
    return {}
  end
  local cook_recipe_cfg = LocalDataUtil.get_value(typeof(CS.BCookRecipeCfg), recipe_id)
  if is_null(cook_recipe_cfg) then
    return {}
  end
  local infos = list_to_table(cook_recipe_cfg.IngredientInfos)
  table.insert(infos, cook_recipe_cfg.CondimentInfo)
  return infos
end

return cooking_module
