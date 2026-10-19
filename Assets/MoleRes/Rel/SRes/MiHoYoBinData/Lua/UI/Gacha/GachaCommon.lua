gacha_module = gacha_module or {}
GachaConst = GachaConst or {}
GachaConst.tab = {
  t0 = 1,
  t1_no_replace = 2,
  t1_replace = 3
}
GachaConst.sub_tab = {cloth = 1, furniture = 2}
GachaConst.price_strategy = {replace = 1, no_replace = 2}
GachaConst.page_path = {
  main = "UI/Gacha/GachaMainPage",
  performance_controller = "UI/Gacha/GachaPerformanceControllerPage",
  exchange = "UI/Gacha/GachaExchangePage",
  cloth_pool_show = "UI/Gacha/GachaClothPoolShowPage",
  cloth_new_obtain = "UI/Gacha/GachaClothNewObtainPage",
  description = "UI/Gacha/GachaDescriptionPopUp",
  draw_show_t0 = "UI/Gacha/GachaDrawShowT0Page",
  draw_show_t1 = "UI/Gacha/GachaDrawShowT1Page",
  all_collect_banner = "UI/Gacha/GachaAllCollectBanner",
  process_cloth_t1 = "UI/Gacha/GachaProcessClothT1Page",
  process_furniture_t1 = "UI/Gacha/GachaProcessFurnitureT1Page",
  accum_reward = "UI/Gacha/GachaAccumRewardDialog",
  draw_transition_cover = "UI/Gacha/GachaDrawTransitionCover"
}
GachaConst.panel_path = {
  pool_premium = "UI/Gacha/GachaDetailsFurnitureT00Panel",
  pool_furniture = "UI/Gacha/GachaDetailsFurnitureT01Panel",
  pool_cloth_scratch = "UI/Gacha/GachaDetailsClothT01Panel",
  draw_show_t0 = "UI/Gacha/GachaResultClothT00Page",
  draw_show_t1 = "UI/Gacha/GachaResultFurnitureT01Page",
  cloth_new_obtain = "UI/Gacha/GachaShowClothT00Page",
  process_cloth_t1 = "UI/Gacha/GachaShowClothingPage",
  process_furniture_t1 = "UI/Gacha/GachaShowFurniturePage",
  all_collect_banner = "UI/Gacha/GachaSharePhotoDialog",
  accum_reward = "UI/Gacha/GachaRewardPopup",
  draw_transition_cover = "UI/Gacha/GachaT00Transition"
}
GachaConst.item_path = {
  tab = "UI/Gacha/GachaTabItem",
  tab_title = "UI/Gacha/GachaTabTitleItem",
  description = "UI/Gacha/GachaDescriptionItem",
  exchange = "UI/Gacha/GachaExchangeItem",
  exchange_title = "UI/Gacha/GachaExchangeTitleItem",
  draw_result = "UI/Gacha/GachaDrawResultItem",
  all_collect_reward = "UI/Gacha/GachaAllCollectItem",
  accum_reward = "UI/Gacha/GachaAccumRewardItem"
}
GachaConst.tab_pool_panel_path = {
  [GachaConst.tab.t0] = "UI/Gacha/GachaPremiumPoolPanel",
  [GachaConst.tab.t1_no_replace] = "UI/Gacha/GachaClothScratchPoolPanel",
  [GachaConst.tab.t1_replace] = "UI/Gacha/GachaFurniturePoolPanel"
}
GachaConst.draw_count = {once = 1, ten = 10}
GachaConst.replace_price_strategy_index = 1
GachaConst.exchange_shop_open = 1
GachaConst.rule_tab = {
  inventory = 1,
  details = 2,
  history = 3
}
GachaConst.price_not_enough_style = "TextWarning_Light"
GachaConst.history_page_size = 10
GachaConst.shop_category = {
  suit = 1,
  scatter = 2,
  furniture = 3,
  dye = 4
}
GachaConst.exchange_state = {
  not_owned = 0,
  owned_not_exchangeable = 1,
  owned_exchangeable = 2,
  not_owned_cloth = 3,
  owned_cloth = 4
}
GachaConst.accum_reward_state = {
  claimed = 0,
  can_claim = 1,
  locked = 2
}
GachaConst.all_collect_reward_type = {video = 1, effect = 2}
GachaConst.item_type = {
  normal = "GACHA_ITEM_TYPE_NORMAL",
  core = "GACHA_ITEM_TYPE_CORE"
}
GachaConst.fragment_draw_level = {
  huge_guarantee = 1,
  normal_guarantee = 2,
  no_guarantee = 3
}
GachaConst.group_title_child_name = "group_title"
GachaConst.draw_show_exchangeable_item_count = 3
GachaConst.exchange_max_buy_count = 99
GachaConst.draw_cutscene_id = {
  cloth_single = 88,
  cloth_ten = 89,
  furniture_single = 90,
  furniture_ten = 91
}
GachaConst.new_obtain_anim = "Ani_ShowOffItem_gacha_Perform_GachaNewItemShow"
GachaConst.new_obtain_effect_by_rank = {
  [1] = "Effects/UI/Eff_Gacha_New_Blue",
  [2] = "Effects/UI/Eff_Gacha_New_Purple",
  [3] = "Effects/UI/Eff_Gacha_New_Gold",
  [4] = "Effects/UI/Eff_Gacha_New_Colorful"
}
GachaConst.draw_scene_camera_path = "Art/Content/CameraWrap"
GachaConst.draw_performance_camera_mode_name = {
  normal = "GachaPage1",
  intro = "GachaPage1Intro"
}
GachaConst.performance_type = {
  new_obtain = 1,
  draw_result = 2,
  both = 3
}
GachaConst.new_item_show_tag = 1
GachaConst.draw_show_timeout = 20
return gacha_module
