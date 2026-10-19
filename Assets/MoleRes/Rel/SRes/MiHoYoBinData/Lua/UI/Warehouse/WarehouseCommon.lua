warehouse_module = warehouse_module or {}
warehouse_module.warehouse_item_type = {
  other = -1,
  all = 0,
  biology = 1,
  furniture = 2,
  clothe = 3
}
warehouse_module.warehouse_show_order = {
  warehouse_module.warehouse_item_type.all,
  warehouse_module.warehouse_item_type.furniture,
  warehouse_module.warehouse_item_type.clothe,
  warehouse_module.warehouse_item_type.biology,
  warehouse_module.warehouse_item_type.other
}
warehouse_module.bag_type2warehous_item_type = {
  [item_module.bag_type_biology] = warehouse_module.warehouse_item_type.biology,
  [item_module.bag_type_furniture] = warehouse_module.warehouse_item_type.furniture,
  [item_module.bag_type_small_item] = warehouse_module.warehouse_item_type.furniture,
  [item_module.bag_type_wallpaper_and_flooring_tile] = warehouse_module.warehouse_item_type.furniture,
  [item_module.bag_type_clothe] = warehouse_module.warehouse_item_type.clothe
}
warehouse_module.warehous_item_type2display_name = {
  [warehouse_module.warehouse_item_type.all] = "Stock_Tag_All",
  [warehouse_module.warehouse_item_type.furniture] = "Stock_Tag_Furniture",
  [warehouse_module.warehouse_item_type.clothe] = "Stock_Tag_Clothing",
  [warehouse_module.warehouse_item_type.biology] = "Stock_Tag_Bio",
  [warehouse_module.warehouse_item_type.other] = "Stock_Tag_Other"
}
warehouse_module.warehouse_sort_type = {
  bag_type = 1,
  quality = 2,
  price = 3
}
warehouse_module.sort_type2rule_order = {
  [warehouse_module.warehouse_sort_type.bag_type] = {
    {key = "bagtype", asc = true},
    {key = "rank", asc = false},
    {key = "id", asc = true}
  },
  [warehouse_module.warehouse_sort_type.quality] = {
    {key = "rank", asc = false},
    {key = "bagtype", asc = true},
    {key = "id", asc = true}
  },
  [warehouse_module.warehouse_sort_type.price] = {
    {key = "price", asc = false},
    {key = "id", asc = true}
  }
}
warehouse_module.warehouse_sort_type_txt = {
  [warehouse_module.warehouse_sort_type.bag_type] = "Depot_SortType_BagType",
  [warehouse_module.warehouse_sort_type.quality] = "Depot_SortType_Quality",
  [warehouse_module.warehouse_sort_type.price] = "Depot_SortType_Price"
}
warehouse_module.warehouse_sort_type_list = {
  warehouse_module.warehouse_sort_type.bag_type,
  warehouse_module.warehouse_sort_type.quality,
  warehouse_module.warehouse_sort_type.price
}
warehouse_module.add_item_to_warehouse_type = {home = 1, interact = 2}
warehouse_module.warehouse_type_sort_order = {
  [item_module.bag_type_furniture] = 9,
  [item_module.bag_type_small_item] = 8,
  [item_module.bag_type_wallpaper_and_flooring_tile] = 7,
  [item_module.bag_type_biology] = 6,
  [item_module.bag_type_clothe] = 5,
  [item_module.bag_type_other] = 4,
  [item_module.bag_type_tool] = 3,
  [item_module.bag_type_weapon] = 2,
  [0] = 0
}
return warehouse_module
