cooking_module = cooking_module or {}

function cooking_module:open_cook_menu_dialog()
  UIManagerInstance:open("UI/Cooking/CookMenuDialog")
end

function cooking_module:show_cook_tips_info(info)
  UIManagerInstance:open("UI/Cooking/CookTipsDialog", info)
end

function cooking_module:set_cook_icon_by_id(img, recipe_id, cfg, proxy)
  if is_null(img) then
    return
  end
  if is_null(cfg) then
    cfg = LocalDataUtil.get_value(typeof(CS.BCookRecipeCfg), recipe_id)
  end
  item_module:set_item_icon(img, cfg.itemid, nil, nil, proxy)
end

function cooking_module:set_cook_name_by_id(txt, recipe_id, cfg)
  if is_null(txt) then
    return
  end
  if is_null(cfg) then
    cfg = LocalDataUtil.get_value(typeof(CS.BCookRecipeCfg), recipe_id)
  end
  UIUtil.set_text(txt, cfg.cookrecipename, nil)
end

return cooking_module
