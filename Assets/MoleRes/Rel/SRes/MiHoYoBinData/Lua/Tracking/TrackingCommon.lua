tracking_module = tracking_module or {}
tracking_module.track_type = {
  none = 0,
  memo = 1,
  feature = 2,
  tutorial = 99
}
tracking_module.data_source_type = {
  none = 0,
  task = 1,
  npc_daily_event = 2,
  recipe = 3,
  mitaicobuild = 4,
  companion_star = 5,
  miyouzhu = 6,
  lemi_achievement = 7,
  lemi_daily_task = 8
}
tracking_module.tracking_point_style = {
  main_task = 0,
  npc = 1,
  feature = 2,
  feature_and_icon = 3
}
tracking_module.tracking_target_num_type = {
  none = 0,
  single = 1,
  all = 2
}
return tracking_module
