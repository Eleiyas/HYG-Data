dine_together_module = dine_together_module or {}

function dine_together_module:_init_data()
  self._tbl_used_item_id_and_num = {}
  self._tbl_recipe_used_item_info = {}
  self._all_used_item_guid_and_num = {}
end

function dine_together_module:close_select_recipe()
  self:_init_data()
end

function dine_together_module:start_dine_together()
  CsDineTogetherManagerUtil.DineTogetherStart(function(rsp)
    if rsp.Retcode ~= 0 then
      return
    end
    dine_together_module:open_dine_together_start_page()
    local select_recipe_ids = list_to_table(CsDineTogetherManagerUtil.GetSelectCookRecipeIds())
    for _, recipe_id in ipairs(select_recipe_ids) do
      if 0 < recipe_id then
        local used_item_infos = self._tbl_recipe_used_item_info[recipe_id]
        CsDineTogetherManagerUtil.AddFood(recipe_id, used_item_infos.used_guids)
      end
    end
    CsDineTogetherManagerUtil.StartMealActivity()
  end)
end

function dine_together_module:select_cook_recipe(recipe_id)
  if self._tbl_recipe_used_item_info[recipe_id] then
    dine_together_module:unselect_cook_recipe(recipe_id)
  end
  local infos = cooking_module:get_ingredient_infos_by_id(recipe_id)
  self._tbl_recipe_used_item_info[recipe_id] = {
    used_guids = {},
    item_id_infos = {}
  }
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
        self._tbl_used_item_id_and_num[id] = self._tbl_used_item_id_and_num[id] or 0
        local bag_num = back_bag_module:get_item_num(id) - self._tbl_used_item_id_and_num[id]
        local surplus_num = bag_num - need_num
        self._tbl_recipe_used_item_info[recipe_id].item_id_infos[id] = {}
        if surplus_num < 0 then
          need_num = math.abs(surplus_num)
          self._tbl_recipe_used_item_info[recipe_id].item_id_infos[id].num = bag_num
        else
          self._tbl_recipe_used_item_info[recipe_id].item_id_infos[id].num = need_num
          need_num = 0
        end
        self._tbl_used_item_id_and_num[id] = self._tbl_used_item_id_and_num[id] + self._tbl_recipe_used_item_info[recipe_id].item_id_infos[id].num
        dine_together_module:_add_recipe_item_guids(recipe_id, id)
      end
    end
  end
  Logger.Log(string.format("recipe_id = %s, data = %s", recipe_id, table.serialize(self._tbl_recipe_used_item_info[recipe_id])))
end

function dine_together_module:_add_recipe_item_guids(recipe_id, item_id)
  local used_info = self._tbl_recipe_used_item_info[recipe_id]
  local used_num = used_info.item_id_infos[item_id].num
  local item_guid_nums = dic_to_table(back_bag_module:get_packet_data():GetItemGuidAndNumsByCfgId(item_id))
  local guid_and_num = {}
  for guid, num in pairs(item_guid_nums) do
    if used_num <= 0 then
      break
    end
    if self._all_used_item_guid_and_num[guid] == nil then
      self._all_used_item_guid_and_num[guid] = 0
    end
    local remaining_num = num - self._all_used_item_guid_and_num[guid] or 0
    if 0 < remaining_num then
      if used_num <= remaining_num then
        self._all_used_item_guid_and_num[guid] = self._all_used_item_guid_and_num[guid] + used_num
        guid_and_num[guid] = used_num
        used_num = 0
      else
        self._all_used_item_guid_and_num[guid] = self._all_used_item_guid_and_num[guid] + remaining_num
        used_num = used_num - remaining_num
        guid_and_num[guid] = remaining_num
      end
      for i = 1, guid_and_num[guid] do
        table.insert(used_info.used_guids, guid)
      end
    end
  end
  used_info.item_id_infos[item_id].guid_nums = guid_and_num
  self._tbl_recipe_used_item_info[recipe_id] = used_info
end

function dine_together_module:unselect_cook_recipe(recipe_id)
  local used_item_infos = self._tbl_recipe_used_item_info[recipe_id]
  if used_item_infos == nil then
    return
  end
  for id, used_item_info in pairs(used_item_infos.item_id_infos) do
    if self._tbl_used_item_id_and_num[id] == nil then
      self._tbl_used_item_id_and_num[id] = 0
    end
    self._tbl_used_item_id_and_num[id] = self._tbl_used_item_id_and_num[id] - used_item_info.num
    for guid, num in pairs(used_item_info.guid_nums) do
      if self._all_used_item_guid_and_num[guid] then
        self._all_used_item_guid_and_num[guid] = self._all_used_item_guid_and_num[guid] - num
        if 0 >= self._all_used_item_guid_and_num[guid] then
          self._all_used_item_guid_and_num[guid] = nil
        end
      end
    end
  end
  self._tbl_recipe_used_item_info[recipe_id] = nil
end

function dine_together_module:cook_recipe_is_can_make(recipe_id)
  if CsDineTogetherManagerUtil.GetCookRecipeSelectedState(recipe_id) then
    return true
  end
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
        if self._tbl_used_item_id_and_num[id] == nil then
          self._tbl_used_item_id_and_num[id] = 0
        end
        local surplus_num = back_bag_module:get_item_num(id) - self._tbl_used_item_id_and_num[id] or 0
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

function dine_together_module:get_ingredient_num(ingredient_info, tag_str)
  if ingredient_info == nil or ingredient_info.IsNull then
    return 0
  end
  local ids
  if 0 < ingredient_info.id then
    ids = {
      ingredient_info.id
    }
  else
    ids = list_to_table(back_bag_module:get_packet_data():GetItemIdsByTagExpression(tag_str))
  end
  local ret_num = 0
  for _, id in ipairs(ids) do
    if self._tbl_used_item_id_and_num[id] == nil then
      self._tbl_used_item_id_and_num[id] = 0
    end
    local bag_num = back_bag_module:get_item_num(id)
    ret_num = ret_num + bag_num - self._tbl_used_item_id_and_num[id]
  end
  return ret_num
end

function dine_together_module:get_use_items_by_recipe_id(recipe_id)
  local item_infos = self._tbl_recipe_used_item_info[recipe_id]
  local items = {}
  if item_infos then
    for _, guid in ipairs(item_infos.used_guids) do
      table.insert(items, back_bag_module:get_packet_data():GetItemByGUID(guid))
    end
  end
  return items
end

function dine_together_module:get_all_cook_recipe(is_can_make)
  local cur_id = CsDineTogetherManagerUtil.GetCurDineTogetherId()
  local cfg = dine_together_module:get_dine_together_cfg_by_id(cur_id)
  if is_null(cfg) then
    return {}
  end
  local ware_cfg_ids = list_to_table(CsDineTogetherManagerUtil.GetCookwareCfgIds())
  local lst_cook_menus = {}
  for i, id in ipairs(ware_cfg_ids) do
    local recipes = list_to_table(CsCookModuleUtil.GetCookRecipeByCookwareCfgId(id))
    for _, recipe in ipairs(recipes) do
      if not table.contains(lst_cook_menus, recipe) then
        if is_can_make then
          if dine_together_module:cook_recipe_is_can_make(recipe.Id) then
            table.insert(lst_cook_menus, recipe)
          end
        else
          table.insert(lst_cook_menus, recipe)
        end
      end
    end
  end
  return lst_cook_menus
end

function dine_together_module:get_cur_dine_together_cfg()
  local cur_id = CsDineTogetherManagerUtil.GetCurDineTogetherId()
  return dine_together_module:get_dine_together_cfg_by_id(cur_id)
end

return dine_together_module
