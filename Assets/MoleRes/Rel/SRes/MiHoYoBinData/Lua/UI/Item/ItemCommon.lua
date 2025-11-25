item_module = item_module or {}
item_module.item_info_type = {
  err = -1,
  none = 0,
  shop = 1,
  page = 2,
  sell = 3,
  gift = 4,
  tool_table = 5,
  depot = 7,
  move_to_warehouse = 8,
  entity_shop = 9
}
item_module.bag_type_tool = 6
item_module.item_info_pos_data = {
  {
    0,
    1.1,
    -5,
    0,
    0,
    0,
    5,
    -4.7,
    38.2
  },
  {
    0,
    1.1,
    -5,
    0,
    0,
    0,
    2.5,
    -4.7,
    38.2
  },
  {
    0,
    1.1,
    -5,
    0,
    0,
    0,
    1.5,
    -4.7,
    38.2
  }
}
item_module.item_prefab_path = {
  path_package = "",
  path_task_award = "UI/Item/obj_task_award_item",
  path_homeward = "UI/Item/obj_homeward_item",
  path_shop = "UI/Item/obj_shop_item",
  path_recipe = "UI/Item/obj_recipe_item_test",
  path_recipe_mat = "UI/Item/obj_recipe_mat_item",
  path_item = "UI/Item/obj_item",
  path_bag_item = "UI/Item/obj_bag_item",
  path_item_lite = "UI/Item/obj_item_lite"
}
item_module.quality_ui_type = {
  def = 1,
  shop = 2,
  diy_handbook = 3,
  tv_shopping = 4,
  cooking = 6
}
item_module.def_item_quality_sprite = {
  "UISprite/Load/Quality/Bg_Quality_White",
  "UISprite/Load/Quality/Bg_Quality_Green",
  "UISprite/Load/Quality/Bg_Quality_Blue",
  "UISprite/Load/Quality/Bg_Quality_Purple"
}
item_module.shop_item_quality_sprite = {
  "UISprite/Load/Quality/Bg_Quality_White_Shop_Normal",
  "UISprite/Load/Quality/Bg_Quality_Green_Shop_Normal",
  "UISprite/Load/Quality/Bg_Quality_Blue_Shop_Normal",
  "UISprite/Load/Quality/Bg_Quality_Purple_Shop_Normal"
}
item_module.diy_handbook_item_quality_sprite = {
  "UISprite/Load/Quality/Bg_Quality_White_diy_Normal",
  "UISprite/Load/Quality/Bg_Quality_Green_diy_Normal",
  "UISprite/Load/Quality/Bg_Quality_Blue_diy_Normal",
  "UISprite/Load/Quality/Bg_Quality_Purple_diy_Normal"
}
item_module.packet_selected_bg_quality_sprite = {
  "UISprite/Load/Quality/Bg_Quality_White_Packet_Selected_Bg",
  "UISprite/Load/Quality/Bg_Quality_Green_Packet_Selected_Bg",
  "UISprite/Load/Quality/Bg_Quality_Blue_Packet_Selected_Bg",
  "UISprite/Load/Quality/Bg_Quality_Purple_Packet_Selected_Bg"
}
item_module.cooking_bg_quality_sprite = {
  "UISprite/Load/Quality/Bg_Cooking_Menu_Rare_Purple",
  "UISprite/Load/Quality/Bg_Cooking_Menu_Rare_Green",
  "UISprite/Load/Quality/Bg_Cooking_Menu_Rare_Purple",
  "UISprite/Load/Quality/Bg_Cooking_Menu_Rare_Gold"
}
item_module.item_info_panel = "UI/Item/ItemInfoPanel"
item_module.entity_shop_item_info_panel = "UI/Item/EntityShopItemInfoPanel"
item_module.sort_panel = "UI/Item/SortPanel"
item_module.limit_slot_type = {
  def = 0,
  bind = 1,
  sel = 2,
  buy = 3,
  drop = 4,
  del = 5,
  give = 6,
  donate = 7,
  move = 8,
  not_destroy = 9,
  max = 32
}
item_module.bag_type_biology = 1
item_module.bag_type_furniture = 2
item_module.bag_type_small_item = 3
item_module.bag_type_wallpaper_and_flooring_tile = 4
item_module.bag_type_clothe = 5
item_module.bag_type_tool = 6
item_module.bag_type_weapon = 7
item_module.bag_type_other = 9
item_module.food_flavor_bit = {
  normal = 0,
  sweet = 1,
  salty = 2,
  spicy = 3,
  burnt = 4,
  tasteless = 5,
  wrong_taste = 6
}
item_module.item_num_panel_cls_name = "UI/Item/ItemNumPanel"
item_module.style_tag_item_cls_name = "UI/Item/TagStyleItem"
item_module.source_item_cls_name = "UI/Item/SourceItem"
item_module.tracking_mat_item_cls_name = "UI/Item/TrackingMatItem"
item_module.item_info_ui_type = {
  item_id = 1,
  tag = 2,
  miyouzhu = 3
}
return item_module or {}
