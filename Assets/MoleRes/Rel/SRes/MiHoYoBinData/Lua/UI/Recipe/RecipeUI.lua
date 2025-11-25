recipe_module = recipe_module or {}

function recipe_module:init_type_tog_item(trans)
  if is_null(trans) then
    Logger.LogError("trans is nil !!  path = recipe_module:init_type_tog_item")
    return
  end
  local cls = {
    trans = trans,
    tog = UIUtil.find_toggle_ex(trans),
    img_select_icon = UIUtil.find_image(trans, "Select/Pic"),
    img_unselect_icon = UIUtil.find_image(trans, "Unselect/Pic"),
    txt_select_title = UIUtil.find_text(trans, "Select/TabName/txt_select_title")
  }
  return cls
end

function recipe_module:set_type_tog_item(cls, cfg, load_proxy)
  if cls == nil or is_null(cfg) then
    return
  end
  UIUtil.set_text(cls.txt_select_title, cfg.name)
  UIUtil.set_image(cls.img_select_icon, cfg.iconpath, load_proxy)
  UIUtil.set_image(cls.img_unselect_icon, cfg.iconpath, load_proxy)
end

function recipe_module:init_recipe_item(trans)
  if is_null(trans) then
    Logger.LogError("trans is nil !!  path = recipe_module:init_recipe_item")
    return
  end
  local cls = item_module:init_item_cls(trans, item_module.quality_ui_type.diy_handbook)
  cls.txt_recipe_name = UIUtil.find_text(trans, "txt_recipe_name")
  cls.img_suit_frame = UIUtil.find_image(trans, "img_suit_frame")
  cls.img_topic = UIUtil.find_image(trans, "img_Topic")
  cls.img_like = UIUtil.find_image(trans, "img_like")
  cls.img_new = UIUtil.find_image(trans, "img_new")
  cls.recipe_id = 0
  return cls
end

function recipe_module:set_recipe_item(cls, recipe_id, load_proxy)
  local recipe = recipe_module:get_recipe_data_by_id(recipe_id)
  UIUtil.set_active(cls.trans, not is_null(recipe))
  if is_null(recipe) then
    return
  end
  local recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
  if is_null(recipe_cfg) then
    return
  end
  cls.recipe_id = recipe_id
  cls.is_new = recipe_module:get_recipe_is_new(recipe_id)
  item_module:set_item_cls(cls, recipe_cfg.itemid, 0, load_proxy, nil, true)
  UIUtil.set_image(cls.img_suit_frame, recipe_cfg.cardpath, load_proxy)
  UIUtil.set_image(cls.img_topic, recipe_cfg.DiyGroupCfg.iconpath, load_proxy)
  UIUtil.set_text(cls.txt_recipe_name, recipe_cfg.name)
  UIUtil.set_active(cls.img_like, recipe.IsLike or false)
  UIUtil.set_active(cls.img_new, cls.is_new or false)
end

function recipe_module:open_diy_handbook_page()
  UIManagerInstance:open("UI/Recipe/DIYHandbookPage")
end

function recipe_module:open_diy_recipe_info_page(recipe_id, cur_show_ids)
  recipe_module:set_cur_recipe_id(recipe_id)
  recipe_module:set_cur_show_recipe_ids(cur_show_ids)
  BGSceneManagerIns:show(function()
    UIManagerInstance:open("UI/Recipe/DIYRecipeInfoPage", true)
  end)
end

function recipe_module:beiwanglu_open_diy_recipe_info_page(recipe_id)
  recipe_module:set_cur_recipe_id(recipe_id)
  local ids = {recipe_id}
  recipe_module:set_cur_show_recipe_ids(ids)
  recipe_module:set_is_tool_table_state(false)
  BGSceneManagerIns:show(function()
    UIManagerInstance:open("UI/Recipe/DIYRecipeInfoPage", true)
  end)
end

function recipe_module:set_is_tool_table_state(is_tool_table)
  EventCenter.Broadcast(EventID.LuaSetHandBookOpenBy, is_tool_table and 1 or 2)
  self.is_tool_table = is_tool_table
end

function recipe_module:close_recipe_info_page()
  local page = UIManagerInstance:is_show("UI/Recipe/DIYRecipeInfoPage")
  if page then
    UIManagerInstance:close(page.guid)
  end
end

function recipe_module:set_recipe_icon(img_icon, recipe_id, load_proxy, is_item_icon)
  local recipe_cfg = recipe_module:get_recipe_cfg_by_id(recipe_id)
  if not is_item_icon or is_null(recipe_cfg) then
    item_module:set_item_icon(img_icon, recipe_id, nil, nil, load_proxy)
    return
  end
  item_module:set_item_icon(img_icon, recipe_cfg.itemid, nil, nil, load_proxy)
end

return recipe_module
