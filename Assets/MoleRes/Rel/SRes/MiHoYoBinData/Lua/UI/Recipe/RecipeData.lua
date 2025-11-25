recipe_module = recipe_module or {}

function recipe_module:_init_all_recipe_data()
  self._all_recipe_data = {}
  self._all_has_recipe_group = {}
  for _, v in pairs(dic_to_table(CsRecipeManagerUtil.GetAllRecipeData())) do
    recipe_module:_add_recipe_data(v, true)
  end
  for group_id, cfg in pairs(dic_to_table(LocalDataUtil.get_table(typeof(CS.BDIYGroupCfg)))) do
    if CsTrackerModuleUtil.GetRecipeGroupConditionByTrackerId(cfg.trackerid) and is_null(self._all_has_recipe_group[group_id]) then
      self._all_has_recipe_group[group_id] = {}
    end
  end
  for _, v in pairs(self._all_has_recipe_group) do
    table.sort(v, function(a, b)
      return a.groupindex < b.groupindex
    end)
  end
end

function recipe_module:_show_learn_recipe_tips(tracker_id)
  recipe_module:_init_recipe_tracker_data()
  if recipe_module._tracker_id_map_cfg_id[tracker_id] or recipe_module._tracker_id_map_cfg_group[tracker_id] then
    UIManagerInstance:open("UI/Recipe/LearnRecipeFinishTips", tracker_id)
  end
end

function recipe_module:_init_recipe_tracker_data()
  if is_null(self._tracker_id_map_cfg_id) or table.count(self._tracker_id_map_cfg_id) then
    self._tracker_id_map_cfg_id = {}
    self._recipe_cfg = dic_to_table(LocalDataUtil.get_table(typeof(CS.BRecipeCfg)))
    for _, cfg in pairs(self._recipe_cfg) do
      if not is_null(cfg.trackerid) and cfg.trackerid ~= 0 then
        if is_null(self._tracker_id_map_cfg_id[cfg.trackerid]) then
          self._tracker_id_map_cfg_id[cfg.trackerid] = {}
        end
        table.insert(self._tracker_id_map_cfg_id[cfg.trackerid], cfg)
      end
    end
  end
  if is_null(self._tracker_id_map_cfg_group) or table.count(self._tracker_id_map_cfg_group) then
    self._tracker_id_map_cfg_group = {}
    for _, cfg in pairs(dic_to_table(LocalDataUtil.get_table(typeof(CS.BDIYGroupCfg)))) do
      if not is_null(cfg.trackerid) and cfg.trackerid ~= 0 then
        if is_null(self._tracker_id_map_cfg_group[cfg.trackerid]) then
          self._tracker_id_map_cfg_group[cfg.trackerid] = {}
        end
        table.insert(self._tracker_id_map_cfg_group[cfg.trackerid], cfg)
      end
    end
  end
end

function recipe_module:_add_recipe_data(recipe_data, is_init)
  if is_null(recipe_data) then
    return
  end
  local is_new = self._all_recipe_data[recipe_data.RecipeId] == nil
  self._all_recipe_data[recipe_data.RecipeId] = recipe_data
  local cfg = recipe_module:get_recipe_cfg_by_id(recipe_data.RecipeId)
  if self._all_has_recipe_group[cfg.groupid] == nil then
    self._all_has_recipe_group[cfg.groupid] = {}
  end
  if is_new then
    table.insert(self._all_has_recipe_group[cfg.groupid], cfg)
  end
  if not is_init then
    table.sort(self._all_has_recipe_group[cfg.groupid], function(a, b)
      return a.groupindex < b.groupindex
    end)
    lua_event_module:send_event(lua_event_module.event_type.recipe_data_change, recipe_data.RecipeId)
  end
end

function recipe_module:get_all_recipe_data()
  if self._all_recipe_data == nil then
    recipe_module:_init_all_recipe_data()
  end
  return self._all_recipe_data
end

function recipe_module:get_recipe_data_by_id(recipe_id)
  if self._all_recipe_data == nil then
    recipe_module:_init_all_recipe_data()
  end
  if self._all_recipe_data[recipe_id] == nil then
    self._all_recipe_data[recipe_id] = CsRecipeManagerUtil.GetRecipeDataByCfgId(recipe_id)
  end
  return self._all_recipe_data[recipe_id]
end

function recipe_module:set_cur_recipe_id(recipe_id)
  self._cur_recipe_id = recipe_id
end

function recipe_module:get_cur_recipe_id()
  return self._cur_recipe_id
end

function recipe_module:set_cur_show_recipe_ids(show_recipe_ids)
  self._cur_show_recipe_ids = show_recipe_ids
end

function recipe_module:get_cur_show_recipe_ids()
  return self._cur_show_recipe_ids
end

function recipe_module:recipe_is_learn(recipe_id)
  if recipe_id == nil then
    return
  end
  return CsRecipeManagerUtil.RecipeIsLearn(recipe_id)
end

function recipe_module:get_task_recipe_cfg(recipe_id)
  return self._all_task_recipe_cfg[recipe_id]
end

return recipe_module
