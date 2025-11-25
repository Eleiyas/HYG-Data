back_bag_module = back_bag_module or {}
back_bag_module.packet_item_cls_name = "UI/PacketView/PacketItem"
back_bag_module.new_packet_item_cls_name = "UI/Item/NewPacketItem"
back_bag_module.coin_type = {
  none = 0,
  kalin = 200001,
  gold = 200002,
  lishu = 200003,
  coupon = 200005,
  original_recharge = 200010,
  secondary_recharge = 200011,
  luca = 30201,
  beacon = 200012,
  star_sea_coin = 200000
}
back_bag_module.coin_item_path = "UI/Item/obj_coin_item"
back_bag_module.item_panel_path = "UI/Item/obj_item_panel"
back_bag_module.coin_panel_cls = "BackBag/CoinPanel"
back_bag_module.item_panel_cls = "BackBag/ItemPanel"
back_bag_module.submit_condition_panel_cls_name = "UI/PacketView/SubmitConditionPanel"
back_bag_module.item_detail_panel_cls_name = "UI/PacketView/ItemDetailPanel"
back_bag_module.cookware_panel_cls_name = "UI/PacketView/CookwarePanel"
back_bag_module.bag_show_type = {
  none = 0,
  bag = 1,
  sell = 2,
  gift = 3,
  delivery = 4,
  donate = 5,
  photo_convert = 6,
  npc_packet_exchange = 8,
  replace_bag = 10,
  cooking = 11,
  farming = 12,
  collection_submit = 13,
  depot_bag = 14,
  common_submit = 15,
  gelian_market = 16,
  creature_tank = 17,
  npc_cloth = 18
}
back_bag_module.bag_main_type = {
  empty = -1,
  none = 0,
  normal = 1,
  clothes = 2,
  special = 3,
  temporary = 4,
  virtual = 5,
  momentary = 7,
  ggc_grid = 8,
  furniture = 9,
  biota = 10
}
back_bag_module.bag_main_type_title = {
  [back_bag_module.bag_main_type.normal] = "Bag_Tag_Normal",
  [back_bag_module.bag_main_type.clothes] = "Bag_Tag_Clothing",
  [back_bag_module.bag_main_type.special] = "Bag_Tag_Special",
  [back_bag_module.bag_main_type.momentary] = "Visit_Harvest_BagName",
  [back_bag_module.bag_main_type.biota] = "Bag_Tag_Biota"
}
back_bag_module.bag_function_limit_slot_type = {
  move_to_warehouse = {
    item_module.limit_slot_type.move
  }
}
back_bag_module.bag_item_type = {
  other = -1,
  all = 0,
  biology = 1,
  furniture = 2,
  clothe = 3,
  small_item = 4,
  wallpaper_and_flooring_tile = 5
}
back_bag_module.bag_show_order = {
  back_bag_module.bag_item_type.all,
  back_bag_module.bag_item_type.furniture,
  back_bag_module.bag_item_type.biology,
  back_bag_module.bag_item_type.clothe,
  back_bag_module.bag_item_type.other
}
back_bag_module.replace_item_type = {
  none = 0,
  drop = 1,
  release = 2,
  move_to_warehouse = 3
}
back_bag_module.packet_item_select_type = {
  one_selected = 1,
  multi_selected = 2,
  num_multi_selected = 3,
  has_arrow_one_selected = 4
}
back_bag_module.common_bag_tog_sort_type = {
  back_bag_module.bag_main_type.momentary,
  back_bag_module.bag_main_type.normal,
  back_bag_module.bag_main_type.biota,
  back_bag_module.bag_main_type.clothes,
  back_bag_module.bag_main_type.furniture,
  back_bag_module.bag_main_type.special
}
return back_bag_module
