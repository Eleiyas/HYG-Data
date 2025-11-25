recipe_module = recipe_module or {}

function recipe_module:get_recipe_cfg_by_id(recipe_id)
  if recipe_id == nil or recipe_id <= 0 then
    Logger.LogError("无效的recipe_id!!  path: recipe_module:get_recipe_cfg_by_id()")
    return
  end
  if self._all_recipe_cfg == nil then
    recipe_module:_load_all_recipe_cfg()
  end
  if self._all_recipe_cfg[recipe_id] == nil then
    Logger.LogError("没有对应的配方数据, 请检查配置!! path: recipe_module:get_recipe_cfg_by_id()  recipe_id = " .. recipe_id)
    return
  end
  return self._all_recipe_cfg[recipe_id]
end

function recipe_module:get_group_state_by_id(recipe_id)
  local group_id = recipe_module:get_recipe_cfg_by_id(recipe_id).DiyGroupCfg.groupid
  local cur_num = #(recipe_module:get_all_has_recipe_group()[group_id] or {})
  local max_num = #(recipe_module:get_recipe_cfg_ids_by_group_id(group_id) or {})
  if cur_num == 1 and not red_point_module:is_recorded_with_id(red_point_module.red_point_type.diy_group_recipe, group_id * 10) then
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, group_id)
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, group_id * 10)
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, 0)
    lua_event_module:send_event(lua_event_module.event_type.diy_group_recipe)
  end
  if cur_num == max_num and not red_point_module:is_recorded_with_id(red_point_module.red_point_type.diy_group_recipe, group_id * 20) then
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, group_id)
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, group_id * 20)
    red_point_module:record_with_id(red_point_module.red_point_type.diy_group_recipe, 0)
    lua_event_module:send_event(lua_event_module.event_type.diy_group_recipe)
  end
end

function recipe_module:get_recipe_cfg_by_item_id(item_id)
  if item_id == nil or item_id <= 0 then
    Logger.LogWarning("无效的item_id!!  path: recipe_module:get_recipe_cfg_by_item_id()")
    return
  end
  if self._item_recipe_id == nil then
    recipe_module:_load_all_recipe_cfg()
  end
  if self._item_recipe_id[item_id] == nil then
    Logger.LogWarning("item没有对应的配方数据, 请检查配置!! path: recipe_module:get_recipe_cfg_by_item_id()  item_id = " .. item_id)
    return
  end
  return recipe_module:get_recipe_cfg_by_id(self._item_recipe_id[item_id])
end

function recipe_module:get_all_recipe_cfg()
  if self._all_recipe_cfg == nil then
    recipe_module:_load_all_recipe_cfg()
  end
  return self._all_recipe_cfg
end

function recipe_module:_load_all_recipe_cfg()
  self._all_recipe_cfg = LocalDataUtil.get_table(typeof(CS.BRecipeCfg)) or {}
  self._item_recipe_id = {}
  self._all_recipe_group_id = {}
  local all_group = {}
  for k, cfg in pairs(self._all_recipe_cfg) do
    self._item_recipe_id[cfg.itemid] = tonumber(k)
    if all_group[cfg.groupid] == nil then
      all_group[cfg.groupid] = {}
    end
    table.insert(all_group[cfg.groupid], cfg)
  end
  for i, v in pairs(all_group) do
    self._all_recipe_group_id[i] = {}
    table.sort(v, function(a, b)
      return a.groupindex < b.groupindex
    end)
    for _, vv in ipairs(v) do
      table.insert(self._all_recipe_group_id[i], vv.id)
    end
  end
  local task_recipe_cfgs = LocalDataUtil.get_table(typeof(CS.BTaskRecipeCfg)) or {}
  self._all_task_recipe_cfg = dic_to_table(task_recipe_cfgs)
end

function recipe_module:get_all_diy_ui_cfg()
  if self._all_diy_ui_cfg == nil then
    recipe_module:_load_all_diy_ui_cfg()
  end
  local ret_tbl = {}
  for _, v in pairs(self._all_diy_ui_cfg) do
    table.insert(ret_tbl, v)
  end
  table.sort(ret_tbl, function(a, b)
    return a.id < b.id
  end)
  return ret_tbl
end

function recipe_module:get_diy_ui_cfg_by_id(cfg_id)
  if cfg_id == nil or cfg_id <= 0 then
    Logger.LogError("无效的cfg_id!!  path: recipe_module:get_diy_ui_cfg_by_id()")
    return
  end
  if self._all_diy_ui_cfg == nil then
    recipe_module:_load_all_diy_ui_cfg()
  end
  if self._all_diy_ui_cfg[cfg_id] == nil then
    Logger.LogError("diy_ui_cfg is nil!! path: recipe_module:get_diy_ui_cfg_by_id()  cfg_id = " .. cfg_id)
    return
  end
  return self._all_diy_ui_cfg[cfg_id]
end

function recipe_module:_load_all_diy_ui_cfg()
  self._all_diy_ui_cfg = LocalDataUtil.get_table(typeof(CS.BDIYUICfg)) or {}
end

function recipe_module:get_recipe_cfg_ids_by_group_id(id)
  if self._all_recipe_group_id == nil then
    recipe_module:_load_all_recipe_cfg()
  end
  return self._all_recipe_group_id[id] or {}
end

function recipe_module:get_group_cfg_by_id(id)
  if self._all_group_cfg == nil then
    recipe_module:_load_group_cfg()
  end
  return self._all_group_cfg[id]
end

function recipe_module:get_all_group_ids()
  if self._all_group_cfg == nil then
    recipe_module:_load_group_cfg()
  end
  if self._sort_group_id == nil then
    self._sort_group_id = {}
    for k, _ in pairs(self._all_group_cfg) do
      table.insert(self._sort_group_id, k)
    end
    table.sort(self._sort_group_id, function(a, b)
      return a < b
    end)
  end
  return self._sort_group_id
end

function recipe_module:_load_group_cfg()
  self._all_group_cfg = LocalDataUtil.get_table(typeof(CS.BDIYGroupCfg)) or {}
end

function recipe_module:get_item_id_by_recipe_id(recipe_id)
  return dic_to_table(self._all_recipe_cfg)[recipe_id].itemid
end

return recipe_module
