item_module = item_module or {}

function item_module:set_item_icon(img, item_id, item_cfg, server_data, proxy)
  local img_path = ""
  if item_cfg then
    img_path = item_cfg.icon
  else
    local cfg = item_module:get_cfg_by_id(item_id)
    if cfg.icon == nil or cfg.icon == "" then
      Logger.LogError("item id:" .. item_id .. ",icon is null!")
      return
    end
    img_path = cfg.icon
  end
  if item_module:is_npc_photo_by_server_data(server_data) then
    img_path = self:get_npc_photo_img_path(server_data)
  end
  UIUtil.set_image(img, img_path, proxy)
end

function item_module:get_item_icon(item_id)
  if not item_id or item_id == 0 then
    return nil
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg.icon == nil or cfg.icon == "" then
    Logger.LogError("item id:" .. item_id .. ",icon is null!")
    return
  end
  return cfg.icon
end

function item_module:get_item_big_icon(item_id)
  if not item_id and item_id == 0 then
    return nil
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg.tooltableicon == nil or cfg.tooltableicon == "" then
    Logger.LogError("item id:" .. item_id .. ",tooltableicon is null!")
    return
  end
  return cfg.tooltableicon
end

function item_module:get_npc_photo_img_path(server_data)
  if is_null(server_data) then
    return ""
  end
  if is_null(server_data.Photo) then
    return ""
  end
  local photo_cfg
  if not is_null(photo_cfg) then
    return photo_cfg.iconpath
  end
  return ""
end

function item_module:set_item_name(txt, item_id, server_data, color)
  if is_null(txt) then
    Logger.LogError("item id:" .. item_id .. ",txt is null!")
    return
  end
  local item_name = item_module:get_item_name_by_id(item_id, server_data)
  UIUtil.set_text(txt, item_name, color)
end

function item_module:set_item_big_icon(img, item_id, item_cfg, proxy)
  if item_cfg then
    UIUtil.set_image(img, item_cfg.tooltableicon, proxy)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg.tooltableicon == nil or cfg.tooltableicon == "" then
    Logger.LogError("item id:" .. item_id .. ",tooltableicon is null!")
    return
  end
  UIUtil.set_image(img, cfg.tooltableicon, proxy)
end

function item_module:set_cooking_recipe_card(img, cfg_id, load_proxy)
end

function item_module:set_recipe_card(img, cfg_id, load_proxy)
  local recipe_cfg = recipe_module:get_recipe_cfg_by_id(cfg_id)
  if is_null(recipe_cfg) then
    Logger.LogError("配方数据错误, 无效配方ID! id = " .. cfg_id)
    return
  else
    UIUtil.set_image(img, recipe_cfg.itemcardpath, load_proxy)
  end
end

function item_module:set_appearance_unlock_card(img, cfg_id, load_proxy)
  local unlock_cfg = LocalDataUtil.get_value(typeof(CS.BFaceUnlockCfg), cfg_id)
  if is_null(unlock_cfg) then
    Logger.LogError("换装解锁数据错误, 无效ID! id = " .. cfg_id)
    return
  elseif string.is_valid(unlock_cfg.unlockcardasset) then
    UIUtil.set_image(img, string.format("UISprite/Load/Appearance/%s", unlock_cfg.unlockcardasset), load_proxy)
  end
end

function item_module:open_photo_look_page(sprite)
  UIManagerInstance:open("UI/Photography/PhotoLookPage", sprite)
end

function item_module:open_leaflet_page()
  UIManagerInstance:open("UI/Item/LeafletPage")
end

function item_module:set_tool_icon_mat_by_durable(img, make_id, proxy)
  if is_null(img) then
    Logger.LogError("image组件为空!!!  make_id = " .. make_id)
    return
  end
  local durable = item_module:get_item_durable_by_make_id(make_id)
  local mat
  if durable == 0 and 0 < make_id then
    mat = UIUtil.get_material("Materials/UIMaterials/mat_ui_tool_damage", proxy)
  else
    mat = nil
  end
  UIUtil.set_image_material(img, mat)
end

function item_module:set_item_icon_by_cls(cls, item_id, load_proxy, item_data, is_big)
  if is_null(cls) then
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    return
  end
  local icon_style = 0
  if item_module:item_is_recipe(item_id) then
    icon_style = 1
    item_module:set_recipe_card(cls._img_bg, item_id, load_proxy)
  elseif item_module:item_is_cooking_recipe(item_id) then
    icon_style = 2
    item_module:set_cooking_recipe_card(cls._img_bg, item_id, load_proxy)
  elseif item_module:is_unlock_appearance_card(item_id) then
    icon_style = 3
    item_module:set_appearance_unlock_card(cls._img_bg, item_id, load_proxy)
  end
  cls._ui_change_group_icon:SetState(icon_style)
  if is_big then
    item_module:set_item_big_icon(cls._img_icon, 0, cfg, load_proxy)
  else
    item_module:set_item_icon(cls._img_icon, 0, cfg, item_data, load_proxy)
  end
end

function item_module:init_item_cls(trans, quality_ui_type)
  local cls
  if is_null(trans) then
    Logger.LogError("初始化itemCls失败, prefab为空")
    return cls
  end
  cls = {
    trans = trans,
    go_crown_level = UIUtil.find_gameobject(trans, "img_crown_level"),
    obj_star = UIUtil.find_gameobject(trans, "obj_star"),
    trans_odd = UIUtil.find_rect_trans(trans, "obj_star/odd_star"),
    trans_even = UIUtil.find_rect_trans(trans, "obj_star/even_star"),
    img_quality = UIUtil.find_image(trans, "img_quality"),
    ui_state_group_quality = UIUtil.find_ui_state_group(trans, "ui_state_group_quality"),
    ui_state_group_num = UIUtil.find_ui_state_group(trans, "ui_state_group_num"),
    txt_num = UIUtil.find_text(trans, "Quality_Multiple/txt_num"),
    rect = UIUtil.find_rect_trans(trans),
    btn = UIUtil.find_button(trans),
    quality_ui_type = quality_ui_type or item_module.quality_ui_type.def
  }
  local trans_icon_mask = UIUtil.find_trans(trans, "img_icon_mask")
  if is_null(trans_icon_mask) then
    cls.img_icon = UIUtil.find_image(trans, "img_icon")
    cls.img_recipe_icon = UIUtil.find_image(trans, "img_recipe_icon")
    cls.img_recipe_bg = UIUtil.find_image(trans, "img_recipe_bg")
    cls.img_cooking_icon = UIUtil.find_image(trans, "img_cooking_icon")
    cls.img_cooking_bg = UIUtil.find_image(trans, "img_cooking_bg")
  else
    cls.img_icon = UIUtil.find_image(trans_icon_mask, "img_icon")
    cls.img_recipe_icon = UIUtil.find_image(trans_icon_mask, "img_recipe_icon")
    cls.img_recipe_bg = UIUtil.find_image(trans_icon_mask, "img_recipe_bg")
    cls.img_cooking_icon = UIUtil.find_image(trans_icon_mask, "img_cooking_icon")
    cls.img_cooking_bg = UIUtil.find_image(trans_icon_mask, "img_cooking_bg")
  end
  if not is_null(cls.trans_odd) then
    cls.odd_star = {}
    cls.even_star = {}
    local odd_star_num = cls.trans_odd.childCount
    local even_star_num = cls.trans_even.childCount
    local max_num = math.max(odd_star_num, even_star_num)
    for i = 1, max_num do
      if i <= odd_star_num then
        table.insert(cls.odd_star, cls.trans_odd:GetChild(i - 1))
      end
      if i <= even_star_num then
        table.insert(cls.even_star, cls.trans_even:GetChild(i - 1))
      end
    end
  end
  return cls
end

function item_module:set_item_cls(cls, cfg_id, num, load_proxy, item_data, is_big)
  UIUtil.set_active(cls.trans, cfg_id and 0 < cfg_id)
  if cfg_id == nil or cfg_id <= 0 then
    return
  end
  local cfg = item_module:get_cfg_by_id(cfg_id)
  if cfg == nil then
    return
  end
  local icon_ui
  local is_show_recipe_ui = not is_null(cls.img_recipe_icon) and item_module:item_is_recipe(cfg_id)
  local is_show_cooking_ui = not is_null(cls.img_cooking_icon) and item_module:item_is_cooking_recipe(cfg_id)
  if is_show_recipe_ui then
    icon_ui = cls.img_recipe_icon
    item_module:set_recipe_card(cls.img_recipe_bg, cfg_id, load_proxy)
  elseif is_show_cooking_ui then
    icon_ui = cls.img_cooking_icon
    item_module:set_cooking_recipe_card(cls.img_cooking_bg, cfg_id, load_proxy)
  else
    icon_ui = cls.img_icon
  end
  if not is_null(cls.img_recipe_icon) then
    UIUtil.set_active(cls.img_recipe_icon, is_show_recipe_ui)
    UIUtil.set_active(cls.img_recipe_bg, is_show_recipe_ui)
  end
  if not is_null(cls.img_cooking_icon) then
    UIUtil.set_active(cls.img_cooking_icon, is_show_cooking_ui)
    UIUtil.set_active(cls.img_cooking_bg, is_show_cooking_ui)
  end
  UIUtil.set_active(cls.img_icon, not is_show_recipe_ui and not is_show_cooking_ui)
  if is_big then
    item_module:set_item_big_icon(icon_ui, 0, cfg, load_proxy)
  else
    item_module:set_item_icon(icon_ui, 0, cfg, item_data, load_proxy)
  end
  if not is_null(cls.img_quality) then
    item_module:set_item_quality_by_id(cls.img_quality, cfg_id, load_proxy, cls.quality_ui_type)
  end
  if not is_null(cls.ui_state_group_quality) then
    cls.ui_state_group_quality:SetState(cfg.rank)
  end
  item_module:set_item_server_ui(cls, item_data)
  item_module:set_cls_num_ui(cls, num)
end

function item_module:set_cls_num_ui(cls, min_num, max_num, is_show_num)
  min_num = min_num or 0
  max_num = max_num or 0
  is_show_num = is_show_num or false
  if not is_null(cls.ui_state_group_num) then
    if 1 < min_num or min_num < max_num or is_show_num then
      cls.ui_state_group_num:SetState(0)
    else
      cls.ui_state_group_num:SetState(1)
    end
  end
  if not is_show_num and (min_num <= 1 and max_num <= 1 or is_null(cls.txt_num)) then
    return
  end
  min_num = math.modf(min_num)
  max_num = math.modf(max_num)
  if min_num >= max_num then
    UIUtil.set_text(cls.txt_num, item_module:get_item_num_str(min_num))
  else
    UIUtil.set_text(cls.txt_num, string.format("%s~%s", min_num, max_num))
  end
end

function item_module:get_item_num_str(num)
  if num < 1000 then
    return num
  end
  return "999+"
end

function item_module:set_item_quality_by_id(img, cfg_id, proxy, quality_ui_type)
  if cfg_id == nil or cfg_id <= 0 then
    return
  end
  local cfg = item_module:get_cfg_by_id(cfg_id)
  if cfg == nil then
    return
  end
  if quality_ui_type == item_module.quality_ui_type.shop then
    item_module:set_shop_item_quality(img, cfg.rank, proxy)
  elseif quality_ui_type == item_module.quality_ui_type.tv_shopping then
  elseif quality_ui_type == item_module.quality_ui_type.diy_handbook then
    item_module:set_diy_handbook_item_quality(img, cfg.rank, proxy)
  elseif quality_ui_type == item_module.quality_ui_type.cooking then
    item_module:set_cooking_quality(img, cfg.rank, proxy)
  else
    item_module:set_def_quality(img, cfg.rank, proxy)
  end
end

function item_module:set_def_quality(img, quality, proxy)
  if is_null(img) then
    Logger.LogError("品质背景不存在!!!")
    return
  end
  quality = quality or 0
  quality = quality + 1
  local path = item_module.def_item_quality_sprite[quality]
  if path == nil then
    path = item_module.def_item_quality_sprite[1]
  end
  UIUtil.set_image(img, path, proxy)
end

function item_module:set_diy_handbook_item_quality(img, quality, proxy)
  if is_null(img) then
    Logger.LogError("品质背景不存在!!!")
    return
  end
  quality = quality or 0
  quality = quality + 1
  local path = item_module.diy_handbook_item_quality_sprite[quality]
  if path == nil then
    path = item_module.diy_handbook_item_quality_sprite[1]
  end
  UIUtil.set_image(img, path, proxy)
end

function item_module:set_shop_item_quality(img, quality, proxy)
  if is_null(img) then
    Logger.LogError("品质背景不存在!!!")
    return
  end
  quality = quality or 0
  quality = quality + 1
  local path = item_module.shop_item_quality_sprite[quality]
  if path == nil then
    path = item_module.shop_item_quality_sprite[1]
  end
  UIUtil.set_image(img, path, proxy)
end

function item_module:set_cooking_quality(img, quality, proxy)
  if is_null(img) then
    Logger.LogError("品质背景不存在!!!")
    return
  end
  quality = quality or 0
  quality = quality + 1
  local path = item_module.cooking_bg_quality_sprite[quality]
  if path == nil then
    path = item_module.cooking_bg_quality_sprite[1]
  end
  UIUtil.set_image(img, path, proxy)
end

function item_module:set_item_server_ui(cls, item_data)
  if is_null(cls) or is_null(item_data) then
    return
  end
  local star_level = item_data.StarLevel
  if is_null(star_level) then
    return
  end
  local is_show_crown = item_module:is_show_crown(item_data.GUID, item_data)
  if not is_null(cls.go_crown_level) then
    UIUtil.set_active(cls.go_crown_level, is_show_crown)
  end
  if not is_null(cls.trans_odd) then
    local is_even = star_level % 2 == 0
    local is_show_star = item_module:is_show_star(item_data.GUID, item_data)
    UIUtil.set_active(cls.trans_odd, is_show_star and not is_even)
    UIUtil.set_active(cls.trans_even, is_show_star and is_even)
    UIUtil.set_active(cls.obj_star, is_show_star)
    if is_show_star then
      local star_ui
      if is_even then
        star_ui = cls.even_star
      else
        star_ui = cls.odd_star
      end
      for i, v in ipairs(star_ui) do
        UIUtil.set_active(v, i <= star_level)
      end
    end
  end
end

function item_module:init_sort_item(trans)
  local cls = {
    trans = trans,
    trans_select_bg = UIUtil.find_trans(trans, "trans_select_bg"),
    txt_name = UIUtil.find_text(trans, "txt_name"),
    btn = UIUtil.find_button_ex(trans)
  }
  return cls
end

function item_module:set_sort_item(cls, name_txt)
  UIUtil.set_text(cls.txt_name, name_txt)
end

function item_module:init_recipe_mat_item(trans)
  local cls = {
    trans = trans,
    item = item_module:init_item_cls(UIUtil.find_trans(trans, "trans_item/content"), item_module.quality_ui_type.def),
    txt_mat_name = UIUtil.find_text(trans, "txt_mat_name"),
    txt_need_num = UIUtil.find_text(trans, "txt_mat_neet_num")
  }
  return cls
end

function item_module:set_recipe_mat_item(cls, cfg, need_num, proxy)
  if cfg == nil then
    return
  end
  item_module:set_item_cls(cls.item, cfg.id, 0, proxy)
  UIUtil.set_text(cls.txt_mat_name, cfg.name)
  UIUtil.set_text(cls.txt_need_num, string.format("%s/%s", back_bag_module:get_item_num(cfg.id), need_num))
end

function item_module:init_star_cls(trans)
  local cls = {
    trans = trans,
    trans_star = UIUtil.find_rect_trans(trans, "trans_star_parent"),
    trans_crown = UIUtil.find_rect_trans(trans, "obj_crown_level"),
    lst_stars = {}
  }
  for i = 1, cls.trans_star.childCount do
    table.insert(cls.lst_stars, cls.trans_star:GetChild(i - 1))
  end
  return cls
end

function item_module:set_star_cls(cls, item_data)
  local star_level = item_data.StarLevel
  if is_null(star_level) then
    return
  end
  local is_show_star = item_module:is_show_star(item_data.GUID, item_data)
  local is_show_crown = item_module:is_show_crown(item_data.GUID, item_data)
  UIUtil.set_active(cls.trans, is_show_star or is_show_crown)
  UIUtil.set_active(cls.trans_crown, is_show_crown)
  UIUtil.set_active(cls.trans_star, is_show_star)
  if is_show_star then
    for i, v in ipairs(cls.lst_stars) do
      UIUtil.set_active(v, i <= star_level)
    end
  end
end

function item_module:_open_high_learn_info(item_id)
  UIManagerInstance:open("UI/Item/RecipeHighLearnInfo")
end

function item_module:_open_make_item_finish_info(item_id)
  recipe_module:close_recipe_info_page()
  item_module:set_cur_make_item_id(item_id)
  UIManagerInstance:open("UI/Item/MakeItemFinishInfo")
end

function item_module:open_item_num_dialog(data)
  item_module:set_item_num_data(data)
  UIManagerInstance:open("UI/Item/ItemNumDialog")
end

function item_module:open_item_info_dialog(cfg_id, num, server_data)
  if cfg_id == nil or cfg_id <= 0 then
    return
  end
  local data = {
    cfg_id = cfg_id,
    num = num,
    server_data = server_data
  }
  UIManagerInstance:open("UI/Item/ItemInfoDialog", data)
end

function item_module:open_bag_item_num_dialog(btn_yes_str, max_num, callback)
  local data = {
    max_num = max_num,
    callback = callback,
    btn_yes_str = btn_yes_str
  }
  UIManagerInstance:open("UI/Item/BagItemNumDialog", data)
end

function item_module:open_learn_recipe_finish_page()
  UIManagerInstance:open("UI/PacketView/LearnRecipeFinishDialog")
end

function item_module:open_item_info(trans, ui_type, id, tag, index, param, is_show_tracking_btn)
  if is_show_tracking_btn == nil then
    is_show_tracking_btn = true
  end
  UIManagerInstance:open("UI/Item/ItemInfo", {
    parent = trans,
    item_id = id,
    tag = tag,
    index = index,
    ui_type = ui_type,
    param = param,
    is_show_tracking_btn = is_show_tracking_btn
  })
end

function item_module:hide_item_info_by_trans(trans)
  lua_event_module:send_event(lua_event_module.event_type.hide_item_info, trans)
end

return item_module or {}
