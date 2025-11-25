cooking_module = cooking_module or {}

function cooking_module:_init_data()
  self._cur_need_make_cook_recipe_id = 0
  self._cur_selected_cook_ware_guid = 0
  self._cur_selected_cook_ware_cfg_id = 0
  self._tbl_use_items = nil
  self._select_ingredient_data = nil
  self._selected_recipe_id = 0
  self._selected_recipe_index = 0
end

function cooking_module:set_cur_need_make_cook_recipe_id(id)
  self._cur_need_make_cook_recipe_id = id or 0
end

function cooking_module:get_cur_need_make_cook_recipe_id()
  return self._cur_need_make_cook_recipe_id or 0
end

function cooking_module:set_cur_selected_cook_ware_guid(guid)
  self._cur_selected_cook_ware_guid = guid or 0
end

function cooking_module:get_cur_selected_cook_ware_guid()
  return self._cur_selected_cook_ware_guid or 0
end

function cooking_module:set_cur_selected_cook_ware_cfg_id(cfg_id)
  self._cur_selected_cook_ware_cfg_id = cfg_id or 0
end

function cooking_module:get_cur_selected_cook_ware_cfg_id()
  return self._cur_selected_cook_ware_cfg_id or 0
end

function cooking_module:add_use_item(add_item)
  if is_null(add_item) then
    return
  end
  if self._tbl_use_items == nil then
    self._tbl_use_items = {}
  end
  table.insert(self._tbl_use_items, add_item)
  if self._select_ingredient_data then
    self._select_ingredient_data.use_item = add_item
  end
  lua_event_module:send_event(lua_event_module.event_type.change_ingredient_item, add_item)
end

function cooking_module:remove_use_item(del_item)
  if is_null(del_item) then
    return
  end
  if self._tbl_use_items == nil then
    self._tbl_use_items = {}
  end
  local del_index = 0
  for i, item in ipairs(self._tbl_use_items) do
    if del_item.GUID == item.GUID then
      del_index = i
      break
    end
  end
  if 0 < del_index then
    table.remove(self._tbl_use_items, del_index)
  end
  if self._select_ingredient_data then
    self._select_ingredient_data.use_item = nil
  end
  lua_event_module:send_event(lua_event_module.event_type.change_ingredient_item, nil)
end

function cooking_module:get_use_items()
  local ret_items = {}
  for _, item in ipairs(self._tbl_use_items or {}) do
    table.insert(ret_items, item)
  end
  return ret_items
end

function cooking_module:get_use_item_guids()
  local ret_items = {}
  for _, item in ipairs(self._tbl_use_items or {}) do
    table.insert(ret_items, item.GUID)
  end
  return ret_items
end

function cooking_module:close_use_items()
  self._tbl_use_items = nil
end

function cooking_module:set_select_ingredient_data(ingredient_data)
  self._select_ingredient_data = ingredient_data or nil
  if ingredient_data then
    CsCookModuleUtil.SetSelectedIngredientInfo(ingredient_data.info)
  else
    CsCookModuleUtil.SetSelectedIngredientInfo(nil)
  end
end

function cooking_module:get_select_ingredient_data()
  return self._select_ingredient_data
end

function cooking_module:set_selected_recipe_id(id)
  self._selected_recipe_id = id or 0
end

function cooking_module:set_selected_recipe_index(index)
  self._selected_recipe_index = index or 0
end

function cooking_module:get_selected_recipe_id()
  return self._selected_recipe_id or 0
end

function cooking_module:get_selected_recipe_index()
  return self._selected_recipe_index or 0
end

return cooking_module
