appearance_module = appearance_module or {}
appearance_module.type_tog_item_cls_name = "UI/Appearance/AppearanceTypeTogItem"
appearance_module.clothing_panel_cls_name = "UI/Appearance/ClothingPanel"
appearance_module.dressing_panel_cls_name = "UI/Appearance/DressingPanel"
appearance_module.color_panel_cls_name = "UI/Appearance/ColorPanel"
appearance_module.tab_type = {
  none = 0,
  cloth = 1,
  dress = 2
}
appearance_module.sort_type = {
  none = 0,
  default = 1,
  rank = 2,
  time = 3,
  group = 4,
  color_map_cfg = 5
}
appearance_module.sort_title_id = {
  [appearance_module.sort_type.default] = "Appearance_Sort_Default",
  [appearance_module.sort_type.rank] = "Appearance_Sort_Quality",
  [appearance_module.sort_type.time] = "Appearance_Sort_AcquireTime",
  [appearance_module.sort_type.group] = "Appearance_Sort_Suit"
}
appearance_module.clothing_sort = {
  appearance_module.sort_type.default,
  appearance_module.sort_type.rank,
  appearance_module.sort_type.time,
  appearance_module.sort_type.group
}
appearance_module.dressing_sort = {
  appearance_module.sort_type.default,
  appearance_module.sort_type.rank,
  appearance_module.sort_type.time
}
appearance_module.appearance_attrib_type = {
  none = 0,
  skin_color = 1,
  eyes_color = 2,
  hair_color = 3,
  hair_style = 4,
  eyes_style = 5
}
return appearance_module
