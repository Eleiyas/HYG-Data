le_mi_achievement_module = le_mi_achievement_module or {}
le_mi_achievement_module.achieve_item_bg_path = "UISprite/Load/LeMi/Bg_LeMi_Item_"
le_mi_achievement_module.achieve_item_head_bg_path = "UISprite/Load/LeMi/Bg_LeMi_Item_Header_"
le_mi_achievement_module.daily_task_state = {
  ongoing = 1,
  can_get = 2,
  finish = 3
}
le_mi_achievement_module.achieve_ui_type = {
  none = 0,
  achieve = 1,
  day_task = 2,
  battle_pass = 3
}
le_mi_achievement_module.achieve_item_cls_name = "UI/LeMiAchieve/AchieveItem"
le_mi_achievement_module.plan_type = {
  star = 5,
  moon = 3,
  sun = 1
}
return le_mi_achievement_module
