recipe_module = recipe_module or {}

function recipe_module:add_event()
  recipe_module:remove_event()
  self._events = {}
  self._events[EventID.LikeRecipeRsp] = pack(self, recipe_module._add_recipe_data)
  self._events[EventID.OnRecipeAllRsp] = pack(self, recipe_module._add_recipe_data)
  self._events[EventID.OnRecipeAddRsp] = pack(self, recipe_module._init_all_recipe_data)
  self._events[EventID.TrackerUpdateNotify] = pack(self, recipe_module._show_learn_recipe_tips)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function recipe_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function recipe_module:get_recipe_id_by_diy_ui_id(diy_ui_id)
  if diy_ui_id == nil or diy_ui_id <= 0 then
    return {}
  end
  local diy_ui_cfg = recipe_module:get_diy_ui_cfg_by_id(diy_ui_id)
  if diy_ui_cfg == nil then
    return {}
  end
  local ret_tbl = {}
  local has_recipes = recipe_module:get_all_recipe_data()
  if diy_ui_cfg.uitype == recipe_module.diy_handbook_type.all then
    for recipe_id, _ in pairs(has_recipes) do
      table.insert(ret_tbl, recipe_id)
    end
  elseif diy_ui_cfg.uitype == recipe_module.diy_handbook_type.like then
    for recipe_id, recipe in pairs(has_recipes) do
      if not is_null(recipe) and recipe.IsLike then
        table.insert(ret_tbl, recipe_id)
      end
    end
  elseif diy_ui_cfg.uitype == recipe_module.diy_handbook_type.furniture then
    local recipe_cfg, classify_cfg
    local types = list_to_table(diy_ui_cfg.cfgtype)
    for recipe_id, _ in pairs(has_recipes) do
      recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
      classify_cfg = item_module:get_fur_classify_cfg_by_item_id(recipe_cfg.itemid)
      if not is_null(classify_cfg) and types ~= nil and types[1] ~= nil and classify_cfg.fstclassify == types[1] then
        table.insert(ret_tbl, recipe_id)
      end
    end
  elseif diy_ui_cfg.uitype == recipe_module.diy_handbook_type.id_cfg_type then
    local recipe_cfg, id_cfg
    local types = list_to_table(diy_ui_cfg.cfgtype)
    for recipe_id, _ in pairs(has_recipes) do
      recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
      id_cfg = item_module:get_id_cfg_by_id(recipe_cfg.itemid)
      if not is_null(id_cfg) and item_module:is_tool(0, id_cfg) then
        table.insert(ret_tbl, recipe_id)
      end
    end
  end
  return ret_tbl
end

function recipe_module:sort_recipe_id(ids, sort_type, sequence_type)
  sort_type = sort_type or recipe_module.diy_handbook_sort_type.type
  local sort_tbl = {}
  local sort_id = 0
  local recipe_cfg, recipe
  for _, recipe_id in pairs(ids) do
    if sort_type == recipe_module.diy_handbook_sort_type.theme then
      recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
      sort_id = recipe_cfg.groupid * 1000000000 + recipe_cfg.groupindex
    elseif sort_type == recipe_module.diy_handbook_sort_type.type then
      recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
      local is_tool = item_module:is_tool(recipe_cfg.itemid)
      if is_tool then
        sort_id = -recipe_cfg.targetCfg.id
      else
        local furniture_cfg = item_module:get_fur_cfg_by_id(recipe_cfg.itemid)
        if furniture_cfg ~= nil then
          sort_id = furniture_cfg.classification * 100 + recipe_cfg.targetCfg.id
        else
          sort_id = recipe_cfg.targetCfg.id
        end
      end
    elseif sort_type == recipe_module.diy_handbook_sort_type.quality then
      recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
      sort_id = recipe_cfg.targetCfg.rank * 1000000000 + recipe_cfg.targetCfg.id
    elseif sort_type == recipe_module.diy_handbook_sort_type.get_time then
      recipe = recipe_module:get_recipe_data_by_id(recipe_id)
      if not is_null(recipe) then
        sort_id = recipe.Timestamp
      end
    end
    table.insert(sort_tbl, {sort_id = sort_id, id = recipe_id})
  end
  table.sort(sort_tbl, function(a, b)
    local a_need_top = self._all_task_recipe_cfg and self._all_task_recipe_cfg[a.id] ~= nil and self._all_task_recipe_cfg[a.id].bistop
    local b_need_top = self._all_task_recipe_cfg and self._all_task_recipe_cfg[b.id] ~= nil and self._all_task_recipe_cfg[b.id].bistop
    if a_need_top and not b_need_top then
      return true
    end
    if b_need_top and not a_need_top then
      return false
    end
    if sequence_type then
      return a.sort_id < b.sort_id
    else
      return a.sort_id > b.sort_id
    end
  end)
  return sort_tbl
end

function recipe_module:get_all_has_recipe_group()
  if self._all_has_recipe_group == nil then
    recipe_module:_init_all_recipe_data()
  end
  return self._all_has_recipe_group
end

function recipe_module:get_has_recipe_ids_by_group_id(id)
  if self._all_has_recipe_group == nil then
    recipe_module:_init_all_recipe_data()
  end
  return self._all_has_recipe_group[id] or {}
end

function recipe_module:diy_ui_id_is_like(diy_ui_id)
  if diy_ui_id and 0 < diy_ui_id then
    local diy_ui_cfg = recipe_module:get_diy_ui_cfg_by_id(diy_ui_id)
    return diy_ui_cfg.uitype == recipe_module.diy_handbook_type.like
  end
  return false
end

function recipe_module:get_recipe_is_new(recipe_id)
  if recipe_id == nil or recipe_id <= 0 then
    return false
  end
  return CsRecipeManagerUtil.GetRecipeIsNew(recipe_id)
end

function recipe_module:recipe_group_is_new(group_id)
  if group_id == nil or group_id <= 0 then
    return RedPointType.None
  end
  local datas = recipe_module:get_has_recipe_ids_by_group_id(group_id) or {}
  for _, data in pairs(datas) do
    if recipe_module:get_recipe_is_new(data.id) then
      return RedPointType.NewRp
    end
  end
  return RedPointType.None
end

function recipe_module:recipe_group_is_show_red_point(group_id)
  if group_id == nil or group_id <= 0 then
    return RedPointType.None
  end
  if CsRecipeManagerUtil.GetRecipeGroupRedState(group_id) then
    return RedPointType.StrongRP
  end
  return recipe_module:recipe_group_is_new(group_id)
end

function recipe_module:get_recipe_name(recipe_id, is_item_name)
  local recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
  if is_null(recipe_cfg) then
    return ""
  end
  if is_item_name then
    return item_module:get_item_name_by_id(recipe_cfg.itemid)
  end
  return recipe_cfg.name
end

return recipe_module
