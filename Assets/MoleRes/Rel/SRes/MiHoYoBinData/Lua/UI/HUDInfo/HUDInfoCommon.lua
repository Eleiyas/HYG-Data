hud_info_module = hud_info_module or {}
hud_info_module.hud_area_type = {
  phone_area = 1,
  tracking_area = 2,
  gain_area = 3,
  important_tip_area = 4,
  common_tip_area = 5,
  request_area = 6,
  achieve_area = 7
}
hud_info_module.hud_ui_type = {
  social_confirm_popup = 1,
  npc_confirm_popup = 2,
  lemi_achieve_tip = 3,
  common_tip = 4,
  material_star_tip = 5,
  npc_phone_call = 6,
  player_arrived_tip = 7,
  player_leave_tip = 8,
  get_item_tip = 9,
  online_get_item_tip = 10,
  codex_update_tip = 11,
  blueprint = 12,
  scene_activity = 13,
  star_sea_level_tip = 14,
  star_sea_unlock_tip = 15,
  fortune_wheel_tip = 16,
  star_sea_get_star_coin_tip = 17,
  galactic_bazaar_daily_mission_tip = 18,
  kick_out_tip = 19
}
hud_info_module.ui_type_to_ui_class = {
  [hud_info_module.hud_ui_type.social_confirm_popup] = "UI/HUDInfo/HUDInfoUI/HUDSocialConfirmUI",
  [hud_info_module.hud_ui_type.npc_confirm_popup] = "UI/HUDInfo/HUDInfoUI/HUDSocialConfirmUI",
  [hud_info_module.hud_ui_type.lemi_achieve_tip] = "UI/HUDInfo/HUDInfoUI/HUDLemiAchieveUI",
  [hud_info_module.hud_ui_type.common_tip] = "UI/HUDInfo/HUDInfoUI/HUDCommonTipUI",
  [hud_info_module.hud_ui_type.material_star_tip] = "UI/HUDInfo/HUDInfoUI/HUDMaterialStarTipUI",
  [hud_info_module.hud_ui_type.npc_phone_call] = "UI/HUDInfo/HUDInfoUI/HUDPhoneCallUI",
  [hud_info_module.hud_ui_type.player_arrived_tip] = "UI/HUDInfo/HUDInfoUI/HUDPlayerArrivedTipUI",
  [hud_info_module.hud_ui_type.player_leave_tip] = "UI/HUDInfo/HUDInfoUI/HUDPlayerLeaveTipUI",
  [hud_info_module.hud_ui_type.get_item_tip] = "UI/HUDInfo/HUDInfoUI/HUDGetItemTipUI",
  [hud_info_module.hud_ui_type.online_get_item_tip] = "UI/HUDInfo/HUDInfoUI/HUDOnlineGetItemTipUI",
  [hud_info_module.hud_ui_type.codex_update_tip] = "UI/HUDInfo/HUDInfoUI/HUDCodexAchieveTip",
  [hud_info_module.hud_ui_type.blueprint] = "UI/HUDInfo/HUDInfoUI/HUDBlueprintUI",
  [hud_info_module.hud_ui_type.scene_activity] = "UI/HUDInfo/HUDInfoUI/HUDSceneActivityUI",
  [hud_info_module.hud_ui_type.star_sea_level_tip] = "UI/MaterialStarExplore/StarSeaFloorTipPanel",
  [hud_info_module.hud_ui_type.star_sea_unlock_tip] = "UI/MaterialStarExplore/StarSeaUnlockTipPanel",
  [hud_info_module.hud_ui_type.fortune_wheel_tip] = "UI/FortuneWheel/FortuneWheelTips",
  [hud_info_module.hud_ui_type.star_sea_get_star_coin_tip] = "UI/MaterialStarExplore/GetStarCoinTipPanel",
  [hud_info_module.hud_ui_type.galactic_bazaar_daily_mission_tip] = "UI/GalacticBazaar/GalacticBazaarDailyMissionTip",
  [hud_info_module.hud_ui_type.kick_out_tip] = "UI/HUDInfo/HUDInfoUI/HUDKickOutTipUI"
}
hud_info_module.phone_area_ui_priority = {}
hud_info_module.tracking_area_ui_priority = {
  [hud_info_module.hud_ui_type.blueprint] = 30
}
hud_info_module.gain_area_ui_priority = {
  [hud_info_module.hud_ui_type.get_item_tip] = 10,
  [hud_info_module.hud_ui_type.online_get_item_tip] = 10
}
hud_info_module.important_tip_area_ui_priority = {
  [hud_info_module.hud_ui_type.material_star_tip] = 50,
  [hud_info_module.hud_ui_type.star_sea_level_tip] = 50,
  [hud_info_module.hud_ui_type.star_sea_unlock_tip] = 50,
  [hud_info_module.hud_ui_type.fortune_wheel_tip] = 50,
  [hud_info_module.hud_ui_type.star_sea_get_star_coin_tip] = 50,
  [hud_info_module.hud_ui_type.kick_out_tip] = 60
}
hud_info_module.common_tip_area_ui_priority = {
  [hud_info_module.hud_ui_type.common_tip] = 10
}
hud_info_module.request_area_ui_priority = {
  [hud_info_module.hud_ui_type.social_confirm_popup] = 50,
  [hud_info_module.hud_ui_type.scene_activity] = 50,
  [hud_info_module.hud_ui_type.npc_confirm_popup] = 10,
  [hud_info_module.hud_ui_type.npc_phone_call] = 10
}
hud_info_module.achieve_area_ui_priority = {
  [hud_info_module.hud_ui_type.lemi_achieve_tip] = 10,
  [hud_info_module.hud_ui_type.player_arrived_tip] = 10,
  [hud_info_module.hud_ui_type.player_leave_tip] = 10,
  [hud_info_module.hud_ui_type.codex_update_tip] = 10,
  [hud_info_module.hud_ui_type.galactic_bazaar_daily_mission_tip] = 10
}
hud_info_module.area_type_to_ui_priority = {
  [hud_info_module.hud_area_type.phone_area] = hud_info_module.phone_area_ui_priority,
  [hud_info_module.hud_area_type.tracking_area] = hud_info_module.tracking_area_ui_priority,
  [hud_info_module.hud_area_type.gain_area] = hud_info_module.gain_area_ui_priority,
  [hud_info_module.hud_area_type.important_tip_area] = hud_info_module.important_tip_area_ui_priority,
  [hud_info_module.hud_area_type.common_tip_area] = hud_info_module.common_tip_area_ui_priority,
  [hud_info_module.hud_area_type.request_area] = hud_info_module.request_area_ui_priority,
  [hud_info_module.hud_area_type.achieve_area] = hud_info_module.achieve_area_ui_priority
}
hud_info_module.hud_ui_state = {
  pending = 1,
  preparing = 2,
  showing = 3,
  closed = 4
}
return hud_info_module or {}
