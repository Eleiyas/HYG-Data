recipe_module = recipe_module or {}
recipe_module.diy_handbook_type = {
  all = 1,
  like = 2,
  furniture = 3,
  id_cfg_type = 4
}
recipe_module.diy_handbook_sort_type = {
  theme = 1,
  type = 2,
  get_time = 3,
  quality = 4
}
recipe_module.diy_handbook_sort_type_list = {
  recipe_module.diy_handbook_sort_type.theme,
  recipe_module.diy_handbook_sort_type.type,
  recipe_module.diy_handbook_sort_type.get_time,
  recipe_module.diy_handbook_sort_type.quality
}
recipe_module.diy_handbook_sort_type_txt = {
  [recipe_module.diy_handbook_sort_type.theme] = "DiyHandbookSortType_Theme",
  [recipe_module.diy_handbook_sort_type.type] = "DiyHandbookSortType_Type",
  [recipe_module.diy_handbook_sort_type.get_time] = "DiyHandbookSortType_GetTime",
  [recipe_module.diy_handbook_sort_type.quality] = "DiyHandbookSortType_Quality"
}
return recipe_module
