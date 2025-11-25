require("Debug/EmmyLuaDebug")
require("Global/Global")

local function open_materail_star_explore_view(args)
  Logger.Log("TestDrive界面")
  UIManagerInstance:open("UI/MaterialStarExplore/MaterialStarExplorePage")
end

local function open_materail_star_tips(args)
  if not is_null(args) then
    hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.material_star_tip, args)
  end
end

local function open_star_sea_level_tips(args)
  if not is_null(args) then
    hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.star_sea_level_tip, args)
  end
end

local function open_star_sea_unlock_island_tips(args)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.star_sea_unlock_tip, args)
end

local function show_fortune_wheel_tips(args)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.fortune_wheel_tip, args)
end

local function show_galactic_bazaar_daily_mission_tip(args)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.galactic_bazaar_daily_mission_tip, args)
end

local function open_star_sea_get_coin_tips(args)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.star_sea_get_star_coin_tip, args)
end

local function open_ui_by_name(target)
  Logger.Log("收到打开UIcmd信息")
  if galactic_bazaar_module:get_match_state_to_open_tool() then
    UIUtil.show_tips_by_text_id("RhythmShow_Tips1")
    return
  end
  recipe_module:set_is_tool_table_state(true)
  UIManagerInstance:open("UI/Recipe/DIYHandbookPage")
end

local function open_tool_table_view(target)
  Logger.Log("调用 LuaOpenToolTableView 事件")
  if not is_null(target) then
    GameplayUtility.Camera.SetAxis(player_module:get_player_entity().Rotation.eulerAngles.y, 0.65)
    local camTran = GameplayUtility.Camera.MainCamera.transform
    local startPos = camTran.position
    local startRot = camTran.rotation
    local dir = camTran.forward
    local playerTran = CsEntityManagerUtil.avatarManager:GetPlayer().root.transform
    local midPoint = playerTran.position + playerTran.up * 0.7
    local endPos = startPos + (midPoint - startPos).normalized * 3
    GameplayUtility.Camera.EnterPush(function()
      Logger.Log(" 打开工具�??? ")
      UIManagerInstance:open("UI/ToolTableView/ToolTablePage", target)
    end)
  else
    UIManagerInstance:open("UI/ToolTableView/ToolTablePage", target)
  end
end

local function open_confirm_popup(confirm_popup_content)
  Logger.Log("调用 ConfirmDialog")
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(confirm_popup_content.infoTxt, confirm_popup_content.yesTxt, confirm_popup_content.noTxt, confirm_popup_content.titleTxt)
  popup:set_callbacks(confirm_popup_content.yesAction, confirm_popup_content.noAction, confirm_popup_content.closeAction)
  popup:set_style(confirm_popup_content.style)
  popup:set_item(confirm_popup_content.itemIconPath, confirm_popup_content.itemCurrentNumber, confirm_popup_content.itemMaxNumber)
  popup:show()
end

local function open_general_text_input_popup(popup_content)
  Logger.Log("调用 GeneralTextInputDialog")
  local content = {
    tip_txt = popup_content.tipTxt,
    title_txt = popup_content.titleText,
    confirm_text = popup_content.confirmText,
    confirm_callback = popup_content.confirmAction,
    close_callback = popup_content.closeAction,
    show_close_btn = popup_content.showCloseBtn
  }
  UIManagerInstance:open("UI/GeneralTextInput/GeneralTextInputDialog", content)
end

local function open_countdown_page(countdown_context)
  local context = {
    limit_time = countdown_context.limitTime,
    timeout_callback = countdown_context.timeoutCallback,
    info = countdown_context.info
  }
  UIManagerInstance:open("UI/CountDown/CountdownPage", context)
end

local function open_furniture_edit_view(args)
  UIManagerInstance:open("UI/FurnitureEditView/BaseFurnitureEditPage", args)
end

local function open_hand_book_page()
  Logger.Log("打开HandBookPage")
  UIManagerInstance:open("UI/HandBook/HandBookPage")
end

local function open_init_player_world(data)
  local page = UIManagerInstance:is_show("UI/InitPlayer/InitPlayerPage")
  if page then
    page:set_extra_data(data)
    page:set_active(true)
  else
    UIManagerInstance:open("UI/InitPlayer/InitPlayerPage", data)
  end
end

local function open_loading_scene(data)
  local page = UIManagerInstance:is_show("UI/Loading/LoadingPage")
  if page == nil then
    UIManagerInstance:open("UI/Loading/LoadingPage", data)
  end
end

local function open_simple_loading(data)
  local page = UIManagerInstance:is_show("UI/Loading/SimpleLoadingPage")
  if page == nil then
    page = UIManagerInstance:open("UI/Loading/SimpleLoadingPage", data)
  end
end

local function open_detect_action_page(data)
  UIManagerInstance:open("UI/DetectBottomActionPage", data)
end

local function open_main_page(args)
  UIManagerInstance:open("UI/MainPage/MainPage", args)
  UIManagerInstance:open("UI/HUDInfo/HUDInfoPage")
  UIManagerInstance:open("UI/MainPage/MainSpecialItemTipPanel")
  UIManagerInstance:open("UI/ClickScene")
  UIManagerInstance:open("UI/OverheadHint/NameHintScene")
  UIManagerInstance:open("UI/OverheadHint/CountDownHintScene")
  UIManagerInstance:open("UI/OverheadHint/BubbleHintScene")
  UIManagerInstance:open("UI/OverheadHint/PublicChatHintScene")
  UIManagerInstance:open("UI/OverheadHint/PublicReactionHintScene")
  UIManagerInstance:open("UI/OverheadHint/PickItemBubbleHintScene")
  UIManagerInstance:open("UI/OverheadHint/KnockBubbleHintScene")
  UIManagerInstance:open("UI/OverheadHint/WeakGuideHintScene")
  UIManagerInstance:open("UI/OverheadHint/FunctionBuildingHintScene")
  UIManagerInstance:open("UI/OverheadHint/TaskTrackHintScene")
  UIManagerInstance:open("UI/OverheadHint/CaptureHintScene")
  UIManagerInstance:open("UI/OverheadHint/FortuneWheelHintScene")
  UIManagerInstance:open("UI/OverheadHint/CaptureEmojiHintScene")
  UIManagerInstance:open("UI/OverheadHint/NpcFavourIncreaseHintScene")
  UIManagerInstance:open("UI/OverheadHint/CameraThirdPersonHintScene")
  UIManagerInstance:open("UI/StarMarket/TalkingBoardScene")
  UIManagerInstance:open("UI/OverheadHint/MessageHostScene")
  UIManagerInstance:open("UI/OverheadHint/SocialHintScene")
  common_ui_module:load_bg_background_board()
end

local function open_or_hide_empty_main_page(active)
  if active then
    UIManagerInstance:open("UI/MainPage/EmptyMainPage")
  else
    local page = UIManagerInstance:is_show("UI/MainPage/EmptyMainPage")
    if page ~= nil and page.is_active then
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_or_hide_empty_page(active)
  if active then
    UIManagerInstance:open("UI/MainPage/EmptyPage")
  else
    local page = UIManagerInstance:is_show("UI/MainPage/EmptyPage")
    if page ~= nil and page.is_active then
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_coffee_rp_page(active)
  if active then
    UIManagerInstance:open("UI/CoffeeRpUI/CoffeeRpUIAllPage")
  else
    local page = UIManagerInstance:is_show("UI/CoffeeRpUI/CoffeeRpUIAllPage")
    if page ~= nil and page.is_active then
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_dream_house_furniture_edit_page(args)
  UIManagerInstance:open("UI/FurnitureEditView/DreamHouseFurnitureEditPage", args)
end

local function open_function_building_furniture_edit_page(args)
  UIManagerInstance:open("UI/FurnitureEditView/FunctionBuildingFurnitureEditPage", args)
end

local function open_function_ecology_donation_page(args)
  UIManagerInstance:open("UI/EcologyDonation/EcologyDonationPage", args)
end

local function open_work_island_page(args)
  local _, page = UIManagerInstance:open("UI/WorkIsland/WorkingIslandPage", "reminder")
end

local function open_work_island_introduction(args)
  UIManagerInstance:open("UI/WorkIsland/WorkIslandIntroductionDialog", args)
end

local function open_work_island_finish_page(args)
  if args == "set_state" then
    return
  end
  local _, page = UIManagerInstance:open("UI/WorkIsland/WorkingIslandFinishPage", args)
end

local PreviewMode = {
  CameraPhoto = 1,
  AlbumPhoto = 2,
  DinePhoto = 3
}

local function open_photo_show_page(args)
  CsCameraManagerUtil.CreatePicture(false, function(guid)
    local sprite = CsCameraManagerUtil.GetPhoto(guid)
    if is_null(sprite) == false then
      local data = {
        mode = PreviewMode.DinePhoto,
        sprite = sprite,
        guid = guid,
        action = args
      }
      UIManagerInstance:open("UI/Photography/PhotoPreviewPage", data)
    end
  end)
end

local function open_work_island_block(args)
  local page = UIManagerInstance:is_show("UI/WorkIsland/WorkingIslandPage")
  if page then
    page:set_active(true)
  else
    local _, page = UIManagerInstance:open("UI/WorkIsland/WorkingIslandPage", args)
  end
end

local function open_gallery_board_page(tank_id)
  UIManagerInstance:open("UI/GalleryBoard/GalleryBoardPage", tank_id)
end

local function open_gallery_achievement_panel_ui(args)
  UIManagerInstance:open("UI/Gallery/GalleryAchievementPanel", args)
end

local function open_function_building_hud_page(args)
  UIManagerInstance:open("UI/FunctionBuilding/FunctionBuildingHUDPage", args)
end

local function open_function_building_free_edit_page(args)
  UIManagerInstance:open("UI/FunctionBuilding/FunctionBuildingFreeEditPage", args)
end

local function open_shop_page(args)
  UIManagerInstance:open("UI/Shop/ShopPage", args)
end

local function open_house_upgrade_page(args)
  UIManagerInstance:open("UI/HouseUpgrade/HouseUpgradePage", args)
end

local function open_map_page(args)
  UIManagerInstance:open("UI/Map/MapPage", args)
end

local function open_test_map_page(args)
  UIManagerInstance:open("UI/Map/TestMapPage", args)
end

local function open_nickname_page(args)
  UIManagerInstance:open("UI/Npc/NickNamePage", args)
end

local function open_blank_page(args)
  UIManagerInstance:open("UI/Performance/BlankPage", args)
end

local function open_function_building_customer_page(args)
  UIManagerInstance:open("UI/FunctionBuilding/FunctionBuildingCustomerPage", args)
end

local function close_blank_page(args)
  local page = UIManagerInstance:is_show("UI/Performance/BlankPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_scene_activity_blank_page(args)
  UIManagerInstance:open("UI/GalacticBazaar/SceneActivityBlankPage", args)
end

local function close_scene_activity_blank_page(args)
  local page = UIManagerInstance:is_show("UI/GalacticBazaar/SceneActivityBlankPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_edit_name_popup(args)
  UIManagerInstance:open("UI/FunctionBuilding/FunctionBuildingEditNamePopup", args)
end

local function open_function_building_manage_page(args)
  UIManagerInstance:open("UI/FunctionBuilding/FunctionBuildingManagePage", args)
end

local function open_function_building_manage_page_new(args)
  UIManagerInstance:open("UI/FunctionBuilding/Manage/FunctionBuildingManagePageNew", args)
end

local function open_npc_house_build_page(args)
  local npc_id = args
  local _, page = UIManagerInstance:open("UI/NpcHouseUpgrade/NpcHouseUpgradePage", npc_id)
  Logger.Log("OpenNpcHouseBuildPage NpcID:" .. tostring(npc_id))
end

local function open_npc_house_upgrade_page(args)
  local _, page = UIManagerInstance:open("UI/NpcHouseUpgrade/NpcHouseUpgradePage")
end

local function open_npc_house_co_build_record_dialog(args)
  local npc_id = args
  local _, page = UIManagerInstance:open("UI/NpcHouseUpgrade/NpcHouseBuildRecordDialog", npc_id)
end

local function open_get_reason_tips_page(args)
  UIManagerInstance:open("UI/NpcInvite/GetReasonTipsPage", args)
end

local function open_npc_invite_success_tips_page(args)
  UIManagerInstance:open("UI/NpcInvite/NpcInviteSuccessTipsPage", args)
end

local function open_select_invitation_reason_page(args)
  UIManagerInstance:open("UI/NpcInvite/SelectInvitationReasonPage", args)
end

local function open_npc_settle_select_page(args)
  UIManagerInstance:open("UI/NpcInvite/NpcSettleSelectPage", args)
end

local function open_black_screen_view(args)
  UIManagerInstance:open("UI/BlackScreen/BlackScreenView", args)
end

local function prepare_black_screen_view(args)
  UIManagerInstance:pre_open("UI/BlackScreen/BlackScreenView", args)
end

local function open_passport_page(args)
  UIManagerInstance:open("UI/Passport/PassportPage")
end

local function open_main_star_name_page(args)
  UIManagerInstance:open("UI/MainStarName/MainStarNamePage")
end

local function open_photography_page(args)
  UIManagerInstance:open("UI/Photography/PhotographyPage", args)
end

local function open_cutscene_page(args)
  UIManagerInstance:open("UI/CutscenePage")
end

local function open_npc_move_house_page(args)
  UIManagerInstance:open("UI/NpcHouseMove/NpcMoveHousePage")
end

local function open_mitai_construction_page(args)
  UIManagerInstance:open("UI/MiTai/MiTaiConstructionPage", args)
end

local function open_mitai_order_page(args)
  UIManagerInstance:open("UI/MiTai/MiTaiOrderPageNew", args)
end

local function open_mitai_contribution_box_page(args)
  UIManagerInstance:open("UI/MiTai/MiTaiCoBuildBoxPage", args)
end

local function open_mitai_app_page(args)
  UIManagerInstance:open("UI/MiTai/MiTaiAppPage", args)
end

local function open_planet_tree_level_up_dialog(args)
end

local function open_phone_call_dialog(context)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.npc_phone_call, context)
end

local function close_phone_call_dialog()
  hud_info_module:remove_hud_info_ui(hud_info_module.hud_ui_type.npc_phone_call)
end

local function on_controller_change(layout_version)
  if is_null(layout_version) == false then
    UIManagerInstance:change_layout_version(layout_version, true)
    if ApplicationUtil.IsEnableGM() then
      local gm_model = GMModule.instance
      if is_null(gm_model) == false then
        gm_model.needRefresh = true
      end
    end
  end
end

local function open_GM_page(action)
  if ApplicationUtil.IsEnableGM() then
    action.handled = true
    if not UIManagerInstance:is_active("UI/GMPage/GMPro/GMProPage") then
      UIManagerInstance:open("UI/GMPage/GMPro/GMProPage")
    end
  end
end

local function open_full_screen_video(data)
  if not UIManagerInstance:is_active("UI/Video/FullScreenVideoPage") then
    UIManagerInstance:open("UI/Video/FullScreenVideoPage", data)
  else
    Logger.LogError("无法播放全屏视频，界面正被占用！")
  end
end

local function cfg_call_lua(data)
  if data and type(data) ~= "string" then
    data = list_to_table(data)
    if 0 < #data and data[1] == "CameraExit" then
      if data[2] and data[2] ~= "" and tonumber(data[2]) == 4 then
        GameplayUtility.Camera.ExitUI("ToolTable")
      elseif data[1] == "StarSettlement" then
        NetHandlerIns:send_data(StarSettleReq, {})
      elseif data[1] == "StarLeave" then
        NetHandlerIns:send_data(QuitInstanceReq, {})
      end
    end
  end
end

local function open_bubble_page(args)
end

local function on_cutscene_playing(is_play)
  BubbleManagerIns:set_bubbles_showhide(not is_play)
end

local function open_main_login_page(args)
  if not is_null(args) and UIManagerInstance:is_show("UI/Login/MainLoginPage") == nil then
    UIManagerInstance:open("UI/Login/MainLoginPage", args)
  end
end

local function open_net_info_page(args)
  if not is_null(args) then
    UIManagerInstance:open("UI/NetState/NetInfoPage", args)
  end
end

local function _show_net_error(error_pack)
  if not is_null(error_pack) then
    UIManagerInstance:open("UI/NetState/NetErrorDialog", error_pack)
    EventCenter.Broadcast(EventID.luaCloseNetWaitPage, nil)
  end
end

local function _show_net_wait(data)
  UIManagerInstance:open("UI/NetState/NetWaitPage", data)
end

local function open_mall_dialog_page(args)
  if not is_null(args) then
    UIManagerInstance:open("UI/Mall/MallDialog", args)
  end
end

local function open_gallery_edit_page(args)
  UIManagerInstance:open("UI/Gallery/GalleryEditPage")
end

local function open_wanxiang_handbook_page(args)
  UIManagerInstance:open("UI/Gallery/GalleryHandbookPanel")
end

local function open_identify_page(args)
  UIManagerInstance:open("UI/Donate/DonateResultPage", args)
end

local function open_tv_shopping_page(tag)
  local extra_data = {}
  if tag == "luomi_ad" then
    extra_data.tab_type = TVShopTabsType.TvShopTabsLuomi
    extra_data.enter_by_ad = true
  elseif tag == "luomi" then
    extra_data.tab_type = TVShopTabsType.TvShopTabsLuomi
    extra_data.enter_by_ad = false
  elseif tag == "haitao_ad" then
    extra_data.tab_type = TVShopTabsType.TvShopTabsGold
    extra_data.enter_by_ad = true
  elseif tag == "haitao" then
    extra_data.tab_type = TVShopTabsType.TvShopTabsGold
    extra_data.enter_by_ad = false
  end
  if tag == "4s" or tag == "4s_ad" then
    UIManagerInstance:open("UI/TVShopping/CarModifyNewPage")
  else
    UIManagerInstance:open("UI/TVShopping/TVShoppingNewPage", extra_data)
  end
end

local function open_tv_shopping_ad_page(show_item_id)
  UIManagerInstance:open("UI/TVShopping/TVShoppingADPage", {item_id = show_item_id})
end

local function open_star_explore_prepare_page()
  EventCenter.Broadcast(EventID.LuaOpenSimpleLoading, {
    duration = 1.0,
    open_callback = function()
      CsCoroutineManagerUtil.InvokeAfterFrames(3, function()
        UIManagerInstance:open("UI/StarExplore/StarExplorePage")
      end)
    end
  })
end

local function open_broadcast(args)
  UIManagerInstance:open("UI/Broadcast/BroadcastDialog")
end

local function open_sdk_page(is_show)
  if is_show then
    UIManagerInstance:open("UI/SDK/MihoyoSDKPage")
  else
    local page = UIManagerInstance:is_show("UI/SDK/MihoyoSDKPage")
    if page ~= nil and page.is_active then
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_sdk_dialog(is_show)
  if is_show then
    UIManagerInstance:open("UI/SDK/MihoyoSDKDialog")
  else
    local page = UIManagerInstance:is_show("UI/SDK/MihoyoSDKDialog")
    if page ~= nil and page.is_active then
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_page(arg)
  if string.is_valid(arg) then
    UIManagerInstance:open(arg)
  end
end

local function open_dialog_page(context)
  local page = UIManagerInstance:is_show("UI/Performance/DialogPage")
  local data = {context = context}
  if page == nil then
    UIManagerInstance:open("UI/Performance/DialogPage", data)
  else
    page:set_extra_data(data)
    page:prepare()
    page:start()
  end
end

local function close_dialog_page()
  local page = UIManagerInstance:is_show("UI/Performance/DialogPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function show_curtain_caption_page(context)
  UIManagerInstance:open("UI/Performance/CurtainCaptionPage", context)
end

local function show_gm_bar_graph_page(context)
  UIManagerInstance:open("UI/GMPage/GMInfoPage/GMBarGraphPage", context)
end

local function show_social_confirm_dialog(context)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.npc_confirm_popup, {
    npc_id = context.NpcId,
    agree_callback = context.AgreeCallback,
    refuse_callback = context.RefuseCallback,
    timeout_callback = context.TimeoutCallback,
    interact_type = social_module.social_multi_play_visite_interact_type.apply
  })
end

local function show_dance_start_dialog(info)
  if info.isShowcase then
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.scene_activity, {
    uid = info.playerId,
    source = "scene_activity",
    count_down = info.countDown,
    callback = function(from_uid, accept)
      if is_null(from_uid) then
        Logger.LogWarning("show_dance_start_dialog: start callback - from_uid is null")
        return
      end
      CsSceneActivityModuleUtil.SceneActivityAgreeRunningReq(accept and 1 or 2)
    end
  })
end

local function open_miyouzhu_settlement_page(args)
  UIManagerInstance:open("UI/MiYouZhu/MiYouZhuSettlementPage", args)
end

local function open_get_item_detail_tips(args)
  local class_name = "UI/Tips/GetItemDetailTips"
  local window = UIManagerInstance:get_window_by_class(class_name)
  local extra_data = {}
  if window ~= nil then
    extra_data = window:get_extra_data()
  end
  for i = 0, args.Length - 1 do
    table.insert(extra_data, args[i])
  end
  if window == nil or not window:is_showing() then
    UIManagerInstance:open(class_name, extra_data)
  else
    window:set_extra_data(extra_data)
  end
end

local function open_planet_tree_page(args)
  local cur_level = CsPlanetTreeUtil.GetPlanetTreeLevel()
  local is_record_level_up = red_point_module:is_recorded_with_id(red_point_module.red_point_type.planet_tree_level_up, cur_level)
  if cur_level ~= 1 and not is_record_level_up then
    red_point_module:record_with_id(red_point_module.red_point_type.planet_tree_level_up, cur_level)
    UIManagerInstance:open("UI/PlanetTree/PlanetTreeLevelUpDialog")
  else
    UIManagerInstance:open("UI/PlanetTree/PlanetTreePage", args)
  end
end

local function open_world_editor_page(args)
  UIManagerInstance:open("UI/WorldEditor/WorldEditorPage")
  lua_event_module:send_event(lua_event_module.event_type.set_click_scene_active, false)
end

local function open_player_visit_page()
  UIManagerInstance:open("UI/PlayerVisit/PlayerVisitPage")
end

local function open_star_friend_Page()
  star_friend_module:open_star_friend_page()
end

local function open_player_social_page()
  UIManagerInstance:open("UI/Friend/StarFriendSocialPage", true)
end

local function open_blueprint_area_select_page(args)
  UIManagerInstance:open("UI/Blueprint/BlueprintAreaSelectPage", args)
end

local function open_blueprint_area_change_page(args)
  UIManagerInstance:open("UI/Blueprint/BluePrintBtnPage", args)
end

local function open_blueprint_hud(args)
  local guid = tonumber(args)
  if guid and 0 < guid then
    UIManagerInstance:open("UI/Blueprint/BlueprintHUDPage", {blueprint_guid = guid})
  end
end

local function close_blueprint_hud(args)
  local guid = tonumber(args)
  if guid and 0 < guid then
    local page = UIManagerInstance:is_show("UI/Blueprint/BlueprintHUDPage")
    if page ~= nil and page:get_extra_data().blueprint_guid == guid then
      page:set_extra_data(nil)
      UIManagerInstance:close(page.guid)
    end
  end
end

local function open_blueprint_settlement_page(args)
  UIManagerInstance:open("UI/Blueprint/BlueprintSettlementPage", args)
end

local function close_blueprint_settlement_page(args)
  local page = UIManagerInstance:is_show("UI/Blueprint/BlueprintSettlementPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_blueprint_assess_page(args)
  UIManagerInstance:open("UI/Blueprint/BlueprintAssessPage", args)
end

local function open_dialog_picture_page(args)
  UIManagerInstance:open("UI/Dialogue/DialogPicturePage", args)
end

local function close_dialog_picture_page(args)
  local page = UIManagerInstance:is_show("UI/Dialogue/DialogPicturePage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_instrument_play_page(instrument_type)
  UIManagerInstance:open("UI/InstrumentPlay/InstrumentPlayPage", {instrument_type = instrument_type})
end

local function close_instrument_play_page(args)
  local page = UIManagerInstance:is_show("UI/InstrumentPlay/InstrumentPlayPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_talking_board_page(args)
  UIManagerInstance:open("UI/StarMarket/TalkingBoardPage", nill)
end

local function open_ai_assistant_page(args)
  UIManagerInstance:open("UI/AIAssistant/AIAssistantPage", args)
end

local function open_plant_plot_page(args)
  UIManagerInstance:open("UI/PlantPlot/PlantPlotPage", args)
end

local function open_galactic_bazaar_dancing_page(args)
  galactic_bazaar_module:open_dancing_panel(args)
end

local function open_galactic_bazaar_dance_finished_page(args)
  galactic_bazaar_module:open_dance_finished_panel(args)
end

local function close_galactic_bazaar_dancing_page(args)
  local page = UIManagerInstance:is_show("UI/GalacticBazaar/GalacticBazaarDancingPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

local function open_galactic_bazaar_dance_settlement_page(args)
  galactic_bazaar_module:open_dance_settlement_page()
end

local function open_planet_choose_page(args)
  UIManagerInstance:open("UI/PlanetChoose/PlanetChoosePage")
end

local function open_login_island_page(args)
  local page = UIManagerInstance:is_show("UI/StarExplore/StarExploreIslandCoinNumInfo")
  if is_null(page) then
    UIManagerInstance:open("UI/StarExplore/StarExploreIslandCoinNumInfo", args)
  end
end

local function open_guide_board_text_set_page(args)
  local page = UIManagerInstance:is_show("UI/LoanSignPage/GuideBoardTextTop")
  if is_null(page) then
    UIManagerInstance:open("UI/LoanSignPage/GuideBoardTextTop", args)
  else
    page:create_text(args)
  end
end

local function open_fortune_wheel_reward_page(args)
  local page = UIManagerInstance:is_show("UI/FortuneWheel/FortuneWheelRewardPage")
  if is_null(page) then
    UIManagerInstance:open("UI/FortuneWheel/FortuneWheelRewardPage", args)
  end
end

local function open_tutorial_page(context)
  tutorial_module:open_tutorial_handbook_single_dialog(context.tutorialModuleId, context.tutorialGroupId, context.onClosedCallback)
end

local function open_galactic_bazaar_bulletin_page(args)
  UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarBulletinPage")
end

local function open_kick_out_tips(args)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.kick_out_tip, args)
end

local function close_all_but_main_page(args)
  UIManagerInstance:close_all_stack_window_without_main_page_for_performance()
end

local function on_screen_size_changed(args)
  UIManagerInstance:check_adaptive()
end

local events = {}

local function register_event(event_id, callback)
  EventCenter.LuaAddListener(event_id, callback)
  events[event_id] = callback
end

local function unregister_event(event_id, callback)
  EventCenter.LuaRemoveListener(event_id, callback)
  events[event_id] = nil
end

local function bridge_open_event()
  register_event(EventID.LuaOpenNewMaterialStarTip, open_materail_star_tips)
  register_event(EventID.ShowLevelTip, open_star_sea_level_tips)
  register_event(EventID.ShowUnlockIslandTip, open_star_sea_unlock_island_tips)
  register_event(EventID.LuaShowFortuneWheelTip, show_fortune_wheel_tips)
  register_event(EventID.LuaShowGalacticBazaarDailyMissionTip, show_galactic_bazaar_daily_mission_tip)
  register_event(EventID.ShowGetCoinTip, open_star_sea_get_coin_tips)
  register_event(EventID.LuaOpenMaterialStarExploreHUD, open_materail_star_explore_view)
  register_event(EventID.LuaOpenToolTableView, open_ui_by_name)
  register_event(EventID.LuaOpenConfirmPopup, open_confirm_popup)
  register_event(EventID.LuaOpenGeneralTextInputPopup, open_general_text_input_popup)
  register_event(EventID.LuaOpenCountDown, open_countdown_page)
  register_event(EventID.LuaOpenInitPlayerWorld, open_init_player_world)
  register_event(EventID.LuaOpenLoadingScene, open_loading_scene)
  register_event(EventID.LuaOpenSimpleLoading, open_simple_loading)
  register_event(EventID.LuaDetectActionPage, open_detect_action_page)
  register_event(EventID.LuaOpenMainPanel, open_main_page)
  register_event(EventID.LuaOpenShopUI, open_shop_page)
  register_event(EventID.LuaOpenBlackScreenView, open_black_screen_view)
  register_event(EventID.LuaPrepareBlackScreenView, prepare_black_screen_view)
  register_event(EventID.LuaOpenPassportPage, open_passport_page)
  register_event(EventID.LuaOpenMainStarNamePage, open_main_star_name_page)
  register_event(EventID.LuaOpenPhotographyPage, open_photography_page)
  register_event(EventID.LuaOpenCutscenePage, open_cutscene_page)
  register_event(EventID.CfgCallLua, cfg_call_lua)
  register_event(EventID.LuaOpenBubblePage, open_bubble_page)
  register_event(EventID.OnCutscenePlaying, on_cutscene_playing)
  register_event(EventID.luaShowMainLoginPage, open_main_login_page)
  register_event(EventID.luaShowNetInfoPage, open_net_info_page)
  register_event(EventID.luaShowNetError, _show_net_error)
  register_event(EventID.luaShowNetWaitPage, _show_net_wait)
  register_event(EventID.ScreenSizeChanged, on_screen_size_changed)
  register_event(EventID.LuaShowFullScreenVideo, open_full_screen_video)
  register_event(EventID.LuaOpenDialogPage, open_dialog_page)
  register_event(EventID.LuaCloseDialogPage, close_dialog_page)
  register_event(EventID.LuaShowCurtainCaption, show_curtain_caption_page)
  register_event(EventID.OnControllerChange, on_controller_change)
  register_event(EventID.luaShowMallDialog, open_mall_dialog_page)
  register_event(EventID.LuaOpenGalleryEditPage, open_gallery_edit_page)
  register_event(EventID.LuaOpenWanXiangHandbookPage, open_wanxiang_handbook_page)
  register_event(EventID.LuaOpenIdentifyPage, open_identify_page)
  register_event(EventID.ShowTVShopping, open_tv_shopping_page)
  register_event(EventID.ShowTVShoppingAD, open_tv_shopping_ad_page)
  register_event(EventID.LuaShowBroadcast, open_broadcast)
  register_event(EventID.ShowOrHideMihoyoSDKPage, open_sdk_page)
  register_event(EventID.ShowOrHideMihoyoSDKDialog, open_sdk_dialog)
  register_event(EventID.LuaOpenHouseUpgradePage, open_house_upgrade_page)
  register_event(EventID.LuaOpenMapPage, open_map_page)
  register_event(EventID.LuaOpenTestMapPage, open_test_map_page)
  register_event(EventID.LuaOpenNickNamePage, open_nickname_page)
  register_event(EventID.LuaShowBlank, open_blank_page)
  register_event(EventID.LuaCloseBlank, close_blank_page)
  register_event(EventID.LuaOpenSceneActivityBlank, open_scene_activity_blank_page)
  register_event(EventID.LuaCloseSceneActivityBlank, close_scene_activity_blank_page)
  register_event(EventID.OnShowNpcHouseBuildPage, open_npc_house_build_page)
  register_event(EventID.OnShowNpcHouseUpgradePage, open_npc_house_upgrade_page)
  register_event(EventID.OnShowNpcHouseCoBuildRecordDialog, open_npc_house_co_build_record_dialog)
  register_event(EventID.LuaOpenGetReasonTipsPage, open_get_reason_tips_page)
  register_event(EventID.LuaOpenNpcInviteSuccessTipsPage, open_npc_invite_success_tips_page)
  register_event(EventID.LuaOpenSelectInvitationReasonPage, open_select_invitation_reason_page)
  register_event(EventID.LuaOpenNpcSettleSelectPage, open_npc_settle_select_page)
  register_event(EventID.LuaOpenGalleryAchievementPanel, open_gallery_achievement_panel_ui)
  register_event(EventID.LuaOpenFunctionBuildingHUDPage, open_function_building_hud_page)
  register_event(EventID.LuaOpenFunctionBuildingFreeEditPage, open_function_building_free_edit_page)
  register_event(EventID.LuaOpenFunctionBuildingCustomerPage, open_function_building_customer_page)
  register_event(EventID.LuaOpenEditNamePopUpPage, open_edit_name_popup)
  register_event(EventID.LuaOpenFunctionBuildingManagePage, open_function_building_manage_page)
  register_event(EventID.LuaOpenFunctionBuildingManagePageNew, open_function_building_manage_page_new)
  register_event(EventID.LuaOpenFurnitureEditView, open_furniture_edit_view)
  register_event(EventID.LuaOpenNpcMoveHousePage, open_npc_move_house_page)
  register_event(EventID.LuaOpenMiTaiConstructionPage, open_mitai_construction_page)
  register_event(EventID.LuaOpenMiTaiOrderPage, open_mitai_order_page)
  register_event(EventID.LuaOpenMiTaiContributionBoxPage, open_mitai_contribution_box_page)
  register_event(EventID.LuaOpenMiTaiAppPage, open_mitai_app_page)
  register_event(EventID.LuaOpenPlanetTreeLevelUpPopDialog, open_planet_tree_level_up_dialog)
  register_event(EventID.LuaOpenStarExploreParePage, open_star_explore_prepare_page)
  register_event(EventID.LuaOpenOrHideEmptyMainPage, open_or_hide_empty_main_page)
  register_event(EventID.LuaOpenOrHideEmptyPage, open_or_hide_empty_page)
  register_event(EventID.GalleryTankIDToOpenBoard, open_gallery_board_page)
  register_event(EventID.LuaOpenCoffeeRpPage, open_coffee_rp_page)
  register_event(EventID.LuaOpenDreamHouseFurnitureEditPage, open_dream_house_furniture_edit_page)
  register_event(EventID.LuaOpenFunctionBuildingFurnitureEditView, open_function_building_furniture_edit_page)
  register_event(EventID.LuaOpenEcologyDonation, open_function_ecology_donation_page)
  register_event(EventID.LuaOpenWorkIslandIntroduction, open_work_island_introduction)
  register_event(EventID.LuaWorkIslandGameFinishNotify, open_work_island_finish_page)
  register_event(EventID.LuaOpenPhotoShowPage, open_photo_show_page)
  register_event(EventID.LuaOpenGMBarGraphPage, show_gm_bar_graph_page)
  register_event(EventID.LuaOpenSocialConfirmDialog, show_social_confirm_dialog)
  register_event(EventID.SceneActivity.OnSceneActivityAgreeRunning, show_dance_start_dialog)
  register_event(EventID.LuaOpenMiYouZhuSettlementPage, open_miyouzhu_settlement_page)
  register_event(EventID.LuaOpenPhoneCallDialog, open_phone_call_dialog)
  register_event(EventID.LuaClosePhoneCallDialog, close_phone_call_dialog)
  register_event(EventID.LuaOpenGetItemDetailTips, open_get_item_detail_tips)
  register_event(EventID.LuaOpenPlanetTreePage, open_planet_tree_page)
  register_event(EventID.WorldEdit.LuaUI.OpenWorldEditorPage, open_world_editor_page)
  register_event(EventID.LuaOpenPlayerVisitPage, open_player_visit_page)
  register_event(EventID.LuaOpenPlayerSocialPage, open_player_social_page)
  register_event(EventID.LuaOpenStarFriendPage, open_star_friend_Page)
  register_event(EventID.LuaOpenBlueprintAreaSelectPage, open_blueprint_area_select_page)
  register_event(EventID.LuaOpenBlueprintAreaChangePage, open_blueprint_area_change_page)
  register_event(EventID.LuaOpenDialogPicturePage, open_dialog_picture_page)
  register_event(EventID.LuaCloseDialogPicturePage, close_dialog_picture_page)
  register_event(EventID.LuaOpenBlueprintSettlementPage, open_blueprint_settlement_page)
  register_event(EventID.LuaCloseBlueprintSettlementPage, close_blueprint_settlement_page)
  register_event(EventID.LuaOpenBlueprintAssessPage, open_blueprint_assess_page)
  register_event(EventID.LuaOpenInstrumentPlayPage, open_instrument_play_page)
  register_event(EventID.LuaCloseInstrumentPlayPage, close_instrument_play_page)
  register_event(EventID.Performance.LuaTalkingBoardPageOpen, open_talking_board_page)
  register_event(EventID.LuaOpenAIAssistantPage, open_ai_assistant_page)
  register_event(EventID.LuaOpenPlantPlotPage, open_plant_plot_page)
  register_event(EventID.SceneActivity.LuaOpenGalacticBazaarDancingPage, open_galactic_bazaar_dancing_page)
  register_event(EventID.SceneActivity.LuaCloseGalacticBazaarDancingPage, close_galactic_bazaar_dancing_page)
  register_event(EventID.SceneActivity.LuaOpenGalacticBazaarDanceFinishedPage, open_galactic_bazaar_dance_finished_page)
  register_event(EventID.SceneActivity.LuaOpenGalacticBazaarDanceSettlementPage, open_galactic_bazaar_dance_settlement_page)
  register_event(EventID.LuaOpenPlanetChoosePage, open_planet_choose_page)
  register_event(EventID.LoginIsland, open_login_island_page)
  register_event(EventID.LuaShowUITexText, open_guide_board_text_set_page)
  register_event(EventID.LuaShowFortuneWheelRewardPage, open_fortune_wheel_reward_page)
  register_event(EventID.LuaOpenTutorialPage, open_tutorial_page)
  register_event(EventID.LuaOpenGalacticBazaarBulletin, open_galactic_bazaar_bulletin_page)
  register_event(EventID.LuaOpenKickOutTips, open_kick_out_tips)
  register_event(EventID.LuaCloseAllButMainPage, close_all_but_main_page)
  if ApplicationUtil.IsEnableGM() then
    register_event(EventID.LuaShowPage, open_page)
    InputManagerIns:add_global_action(ActionType.Act.OpenGM, open_GM_page)
  end
end

local function bridge_close_event()
  for k, v in pairs(events) do
    unregister_event(k, v)
  end
end

function main()
  math.randomseed(CS.System.DateTime.Now.Ticks)
  require("LuaModule/LuaModuleMgr")
  bridge_open_event()
end

function reload_res()
end

function init_logo()
  lua_module_mgr:load_module()
  UIManagerInstance:init_ui(function()
    open_main_login_page({
      type = MainLoginType.Logo
    })
    init_gm()
  end)
end

function init_logo_mock()
  UIManagerInstance:init_ui(function()
    init_gm()
    lua_module_mgr:reload_module()
  end)
end

function reinit_ui()
  reload_res()
  lua_module_mgr:reload_module()
  UIManagerInstance:init_ui(function()
    init_gm()
  end)
end

function init_gm()
  if ApplicationUtil.IsEnableGM() then
    UIManagerInstance:open("UI/GMPage/GMBtnPage")
    UIManagerInstance:open("UI/GMPage/GMFPSPage")
  else
    UIManagerInstance:open("UI/InfoPage/FPSPage")
  end
end

function update(deltaTime)
  if UIManagerInstance then
    UIManagerInstance:update(deltaTime)
  end
  if InputManagerIns then
    InputManagerIns:update(deltaTime)
  end
  if UIIdleDetectManagerIns then
    UIIdleDetectManagerIns:update(deltaTime)
  end
  if CoolDownManagerIns then
    CoolDownManagerIns:update(deltaTime)
  end
  if ModelPreviewManagerIns then
    ModelPreviewManagerIns:update(deltaTime)
  end
end

function lateUpdate(deltaTime)
  if UIManagerInstance then
    UIManagerInstance:late_update(deltaTime)
  end
end

function on_level_prepare()
  if UIManagerInstance then
    UIManagerInstance:on_level_prepare()
  end
  if BGSceneManagerIns then
    BGSceneManagerIns:clear_model()
  end
  if ModelPreviewManagerIns then
    ModelPreviewManagerIns:hide()
  end
  if lua_event_module then
    lua_event_module:send_event(lua_event_module.event_type.on_level_prepare)
  end
end

function on_level_destroy()
  if lua_module_mgr then
    lua_module_mgr:on_level_destroy()
  end
  if InputManagerIns then
    InputManagerIns:clear()
  end
  if UIManagerInstance then
    UIManagerInstance:on_level_destroy()
  end
end

function destroy()
  bridge_close_event()
  UIManagerInstance:destroy()
  CoolDownManagerIns:destroy()
  BubbleManagerIns:destroy()
  InputManagerIns:destroy()
  UIIdleDetectManagerIns:destroy()
  NetHandlerIns:destroy()
  RTManagerInstance:destroy()
  BGSceneManagerIns:destroy()
  if lua_module_mgr then
    lua_module_mgr:close_module()
  end
  Hotfix:clear()
end

function clear_on_back_home()
  Logger.Log("lua clear on back home")
  GMPro = nil
  UIManagerInstance:clear_on_back_home()
  InputManagerIns:clear()
  UIIdleDetectManagerIns:clear_on_back_home()
  if lua_module_mgr then
    lua_module_mgr:reload_module()
  end
  LocalDataUtil.init()
  SingletonUtil:clear_on_back_home()
  init_gm()
end

function clear_on_disconnect()
  Logger.Log("lua clear on disconnect")
  if lua_module_mgr then
    lua_module_mgr:clear_on_disconnect()
  end
end

function init_on_connect(isReLogin)
  Logger.Log("lua init on connect")
  if lua_module_mgr then
    lua_module_mgr:init_on_connect(isReLogin)
  end
end

function clear_on_light_relogin()
  UIManagerInstance:clear_on_light_relogin()
  InputManagerIns:clear()
  init_gm()
  if ModelPreviewManagerIns then
    ModelPreviewManagerIns:hide()
  end
end

function input_dispatch()
  if InputManagerIns then
    InputManagerIns:dispatch_input_event()
  end
end

function is_page_showing(page_path, panel_path, check_animation)
  if UIManagerInstance and string.is_valid(page_path) then
    local page = UIManagerInstance:is_show(page_path)
    if page then
      if string.is_valid(panel_path) then
        local panel = page:is_panel_showing(panel_path)
        return panel ~= nil and (check_animation and panel:is_play_anim() == false or true)
      else
        return check_animation and page:is_play_anim() == false or true
      end
    else
      return false
    end
  end
  return false
end

function is_page_showing_by_hash(page_path_hash, panel_path_hash, check_animation)
  if UIManagerInstance and page_path_hash then
    local page = UIManagerInstance:is_show_by_hash(page_path_hash)
    if page then
      if panel_path_hash and panel_path_hash ~= 0 then
        local panel = page:is_panel_showing_by_hash(panel_path_hash)
        return panel ~= nil and (check_animation and panel:is_play_anim() == false or true)
      else
        return check_animation and page:is_play_anim() == false or true
      end
    else
      return false
    end
  end
  return false
end
