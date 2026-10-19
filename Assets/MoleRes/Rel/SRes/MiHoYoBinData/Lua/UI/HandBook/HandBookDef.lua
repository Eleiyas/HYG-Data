hand_book_module = hand_book_module or {}
hand_book_module.all_furniture_type = {
  1,
  4,
  5
}
hand_book_module.hand_book_type_none = -1
hand_book_module.hand_book_type_furniture = 1
hand_book_module.hand_book_type_biota = 2
hand_book_module.hand_book_type_clothing = 3
hand_book_module.show_item_min_num = 35
hand_book_module.item_show_type_is_show = 1
hand_book_module.item_show_type_not_show = 0
hand_book_module.hand_book_title = {
  [hand_book_module.hand_book_type_furniture] = "HandBook_Furniture",
  [hand_book_module.hand_book_type_biota] = "HandBook_Biota",
  [hand_book_module.hand_book_type_clothing] = "HandBook_Clothing"
}
hand_book_module.hand_book_type_title = {
  [hand_book_module.hand_book_type_furniture] = "01",
  [hand_book_module.hand_book_type_biota] = "02",
  [hand_book_module.hand_book_type_clothing] = "03"
}
hand_book_module.hand_book_title_bg_name = {
  [hand_book_module.hand_book_type_furniture] = "Handbook_bg_6_b",
  [hand_book_module.hand_book_type_biota] = "Handbook_bg_5_b",
  [hand_book_module.hand_book_type_clothing] = "Handbook_bg_7_b"
}
hand_book_module.hand_book_type_icon_path = {
  [hand_book_module.hand_book_type_furniture] = "LayoutIcon_12",
  [hand_book_module.hand_book_type_biota] = "LayoutIcon_9",
  [hand_book_module.hand_book_type_clothing] = "LayoutIcon_16"
}
hand_book_module.get_new_tips_types = {
  PlayerMemoryDataType.HandBookGetNewTag0,
  PlayerMemoryDataType.HandBookGetNewTag1,
  PlayerMemoryDataType.HandBookGetNewTag2,
  PlayerMemoryDataType.HandBookGetNewTag3,
  PlayerMemoryDataType.HandBookGetNewTag4,
  PlayerMemoryDataType.HandBookGetNewTag14,
  PlayerMemoryDataType.HandBookGetNewTag15,
  PlayerMemoryDataType.HandBookGetNewTag16,
  PlayerMemoryDataType.HandBookGetNewTag17,
  PlayerMemoryDataType.HandBookGetNewTag18
}
hand_book_module.get_furniture_make_types = {
  PlayerMemoryDataType.FurnitureMakeTag0
}
hand_book_module.item_get_state_types = {
  PlayerMemoryDataType.ItemGetStateTag0,
  PlayerMemoryDataType.ItemGetStateTag1,
  PlayerMemoryDataType.ItemGetStateTag2,
  PlayerMemoryDataType.ItemGetStateTag3,
  PlayerMemoryDataType.ItemGetStateTag4,
  PlayerMemoryDataType.ItemGetStateTag14,
  PlayerMemoryDataType.ItemGetStateTag15,
  PlayerMemoryDataType.ItemGetStateTag16,
  PlayerMemoryDataType.ItemGetStateTag17,
  PlayerMemoryDataType.ItemGetStateTag18
}
hand_book_module.hand_book_type_order = {
  [hand_book_module.hand_book_type_furniture] = 1,
  [hand_book_module.hand_book_type_biota] = 2,
  [hand_book_module.hand_book_type_clothing] = 3
}
return hand_book_module or {}
