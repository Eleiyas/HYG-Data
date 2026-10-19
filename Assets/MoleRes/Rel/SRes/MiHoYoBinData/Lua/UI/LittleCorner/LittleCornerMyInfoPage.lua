local M = G.Class("LittleCornerMyInfoPage", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local panel_type_enum = {
  my_page = 0,
  thumb_post_page = 1,
  collection_post_page = 2
}
local post_view_item_cls = "UI/LittleCorner/LittleCornerPostListSimpleItem"
local bg_preview_state = little_corner_module.bg_preview_state

local function _set_aspect_ratio(fitter, sprite)
  if not_null(fitter) and not_null(sprite) and sprite.rect.height > 0 then
    fitter.aspectRatio = sprite.rect.width / sprite.rect.height
  end
end

local function _make_page_state()
  return {
    page = 0,
    has_more = false,
    is_loading = false
  }
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerMyInfoPage"
  self.config.type = EUIType.Dialog
  self.config.is_singleton = false
  self._cur_panel_type = panel_type_enum.my_page
  self._target_uid = 0
  self._is_self = false
  self._post_items = {}
  self._item_instance_ids = {}
  self._posts_inited = false
  self._is_data_active = true
  self._is_followed = false
  self._cached_posts = nil
  self._item_extra = {}
  self._pending_bg_pic_key = nil
  self._held_bg_key = nil
  self._page_state = {
    [panel_type_enum.my_page] = _make_page_state(),
    [panel_type_enum.thumb_post_page] = _make_page_state(),
    [panel_type_enum.collection_post_page] = _make_page_state()
  }
  self._txt_name = nil
  self._txt_lv = nil
  self._trans_lv = nil
  self._txt_thumb_num = nil
  self._txt_post_num = nil
  self._txt_follow_num = nil
  self._txt_follower_num = nil
  self._img_head = nil
  self._toggle_my_page = nil
  self._tog_thumb_posts = nil
  self._tog_collection_posts = nil
  self._btn_info = nil
  self._btn_close_normal = nil
  self._trans_empty_group = nil
  self._waterfall_scroll_post_list = nil
  self._btn_group = nil
  self._btn_following_list = nil
  self._btn_follower_list = nil
  self._rect_coin_group = nil
  self._btn_not_follow = nil
  self._btn_follow = nil
  self._ui_state_group_follow_btn = nil
  self._txt_tab_post_unselect = nil
  self._txt_tab_post_select = nil
  self._txt_tab_liked_select = nil
  self._txt_tab_liked_unselect = nil
  self._txt_tab_collect_unselect = nil
  self._txt_tab_collect_select = nil
  self._obj_coin_item = nil
  self._btn_lv = nil
  self._txt_level_num = nil
  self._txt_level_name = nil
  self._btn_setup = nil
  self._btn_idcard = nil
  self._btn_more = nil
  self._ui_state_img = nil
  self._img_pic_custom = nil
  self._img_pic_custom_ratio = nil
  self._img_pic_preset = nil
  self._red_point = nil
  self._slider_lv_progress = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._waterfall_scroll_post_list:RegisterReachBottomAction(pack(self, M._on_reach_bottom))
  self._coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item, {
    coin_id = back_bag_module.coin_type.little_corner_jelly,
    auto_update = true
  })
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  self._target_uid = extra and extra.target_uid or 0
  self:_reset_all_page_states()
  self._cur_panel_type = panel_type_enum.my_page
  self._posts_inited = false
  self._is_self = self._target_uid == 0 or self._target_uid == player_module:get_player_uid()
  UIUtil.set_active(self._btn_group, not self._is_self)
  self._coin_view:set_active(false)
  if not_null(self._btn_setup) then
    UIUtil.set_active(self._btn_setup, self._is_self)
  end
  if not_null(self._btn_idcard) then
    UIUtil.set_active(self._btn_idcard, self._is_self)
  end
  if not_null(self._btn_more) then
    UIUtil.set_active(self._btn_more, false)
  end
  self._is_followed = false
  local is_followed_ready = self:_sync_followed_from_profile()
  UIUtil.set_active(self._ui_state_group_follow_btn, is_followed_ready)
  if is_followed_ready then
    self:_refresh_follow_btn_state()
  end
  self:_refresh_tab()
  if self._is_self then
    little_corner_module:query_creator_level_info()
    CsLittleCornerModuleUtil.GetXhsProfileSettings()
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_user_info()
  self:_request_post_list()
  self:_try_show_creator_level_up_dialog()
end

function M:_try_show_creator_level_up_dialog()
  if not self._is_self then
    return
  end
  little_corner_module:try_show_creator_level_up_dialog()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  little_corner_module:on_info_page_closed(self)
  self:_reset_all_page_states()
  self._cur_panel_type = panel_type_enum.my_page
  self._posts_inited = false
end

function M:on_destroy()
  base.on_destroy(self)
  if not_null(self._waterfall_scroll_post_list) then
    self._waterfall_scroll_post_list:UnregisterReachBottomAction()
  end
  self:_release_held_bg()
end

function M:_release_held_bg()
  if self._held_bg_key then
    little_corner_module:release_profile_bg_photo(self._held_bg_key)
    self._held_bg_key = nil
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsUserProfileUpdated, function(uid)
    if self._target_uid == uid or self._target_uid == 0 and uid == player_module:get_player_uid() then
      self:_refresh_user_info()
    end
  end)
  self:add_evt_listener(EventID.OnXhsCreatorLevelUpdated, function()
    self:_refresh_creator_level()
    self:_try_show_creator_level_up_dialog()
  end)
  self:add_lua_listener(lua_event_module.event_type.on_little_corner_reward_notify_reddot_state_event, function()
    self:_refresh_creator_level_red_point()
  end)
  self:add_evt_listener(EventID.OnXhsHomepageBgUpdated, function()
    self:_refresh_bg()
  end)
  self:add_evt_listener(EventID.OnXhsProfilePostsUpdated, function()
    if not self._is_data_active then
      return
    end
    self:_on_profile_data_updated(panel_type_enum.my_page)
  end)
  self:add_evt_listener(EventID.OnXhsProfileLikedPostsUpdated, function()
    if not self._is_data_active then
      return
    end
    self:_on_profile_data_updated(panel_type_enum.thumb_post_page)
  end)
  self:add_evt_listener(EventID.OnXhsProfileFavoritePostsUpdated, function()
    if not self._is_data_active then
      return
    end
    self:_on_profile_data_updated(panel_type_enum.collection_post_page)
  end)
  self:add_evt_listener(EventID.OnXhsFollowChanged, function(data)
    if not self._is_data_active then
      return
    end
    if self._target_uid ~= 0 then
      local target_uid = data.value1
      local is_followed = data.value2
      if target_uid == self._target_uid then
        self._is_followed = is_followed
        self:_refresh_follow_btn_state()
      end
    end
    self:_refresh_follow_info()
  end)
  self:add_evt_listener(EventID.OnXhsPostThumbChanged, function()
    self:_on_post_interaction_changed(panel_type_enum.thumb_post_page)
  end)
  self:add_evt_listener(EventID.OnXhsPostFavoriteChanged, function()
    self:_on_post_interaction_changed(panel_type_enum.collection_post_page)
  end)
  self:add_evt_listener(EventID.OnXhsPinPostChanged, function()
    if not self._is_data_active then
      return
    end
    if self._cur_panel_type == panel_type_enum.my_page and self._posts_inited then
      self._waterfall_scroll_post_list:RefreshCurrent()
    end
  end)
  self:add_evt_listener(EventID.OnXhsPostDeleted, function(post_id)
    if not self._is_data_active then
      return
    end
    if not self._posts_inited then
      return
    end
    self:_reload_current_post_list()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_normal)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info))
  self:bind_callback(self._btn_lv, pack(self, M._on_btn_lv))
  if not_null(self._btn_setup) then
    self:bind_callback(self._btn_setup, pack(self, M._on_btn_setup))
  end
  if not_null(self._btn_idcard) then
    self:bind_callback(self._btn_idcard, pack(self, M._on_btn_idcard))
  end
  if not_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_btn_more))
  end
  self:bind_callback(self._toggle_my_page, pack(self, M._on_toggle_my_page))
  self:bind_callback(self._tog_thumb_posts, pack(self, M._on_tog_thumb_posts))
  self:bind_callback(self._btn_close_normal, pack(self, M._on_btn_close_normal))
  self:bind_callback(self._tog_collection_posts, pack(self, M._on_tog_collection_posts))
  self:bind_callback(self._btn_following_list, pack(self, M._on_btn_following_list))
  self:bind_callback(self._btn_follower_list, pack(self, M._on_btn_follower_list))
  self:bind_callback(self._btn_follow, pack(self, M._on_btn_follow))
  self:bind_callback(self._btn_not_follow, pack(self, M._on_btn_not_follow))
end

function M:_on_btn_info()
  common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.little_corner)
end

function M:_on_btn_lv()
  little_corner_module:open_award_page()
end

function M:_on_btn_setup()
  little_corner_module:open_setup_dialog()
end

function M:_on_btn_idcard()
  little_corner_module:open_my_info_card_select_page(pack(self, M._on_card_select_closed))
end

function M:_on_btn_more()
  if self:_get_reportable_bg() == nil then
    return
  end
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Xhs_UI_Text16"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_report)
    }
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 0),
    state = 4,
    menus = menus
  })
end

function M:_on_menu_report()
  local file_key, content_version = self:_get_reportable_bg()
  if file_key == nil then
    return
  end
  report_module:open_report_page({
    target = report_module.report_target.xhs_homepage_bg,
    target_uid = self._target_uid,
    player_name = CsLittleCornerModuleUtil.TargetProfileUname,
    file_key = file_key,
    content_version = content_version
  })
end

function M:_on_card_select_closed()
  if is_null(self) then
    return
  end
  self._pending_bg_pic_key = nil
  self:_release_held_bg()
  self:_refresh_bg()
end

function M:_refresh_creator_level()
  UIUtil.set_active(self._btn_lv, self._is_self)
  if not self._is_self then
    local is_profile_ready = CsLittleCornerModuleUtil.TargetProfileUid == self._target_uid
    UIUtil.set_active(self._trans_lv, is_profile_ready)
    if is_profile_ready then
      local target_level = math.max(CsLittleCornerModuleUtil.TargetProfileCreatorLevel, 1)
      UIUtil.set_text(self._txt_lv, string.format("Lv. %d", target_level))
    end
    UIUtil.set_active(self._slider_lv_progress, false)
    return
  end
  UIUtil.set_active(self._trans_lv, false)
  local level = CsLittleCornerModuleUtil.TargetProfileCreatorLevel
  UIUtil.set_text(self._txt_level_num, tostring(level))
  if not_null(self._txt_level_name) then
    UIUtil.set_text_by_id(self._txt_level_name, "Xhs_UI_Text30")
  end
  if not_null(self._slider_lv_progress) then
    UIUtil.set_active(self._slider_lv_progress, true)
    local _, exp, exp_to_next = little_corner_module:get_creator_level()
    local ratio = 1
    if exp_to_next and 0 < exp_to_next then
      ratio = math.min(exp / exp_to_next, 1)
    end
    self._slider_lv_progress.value = ratio
  end
end

function M:_refresh_creator_level_red_point()
  if is_null(self._red_point) then
    return
  end
  if not self._is_self then
    self._red_point:ShowRedPoint(RedPointType.None)
    return
  end
  self._red_point:ShowRedPoint(little_corner_module:get_little_corner_reward_red_dot_state())
end

function M:_on_btn_close_normal()
  self:close_self()
end

function M:set_data_active(active)
  self._is_data_active = active
end

function M:restore_data_context()
  CsLittleCornerModuleUtil.SetProfileTarget(self._target_uid)
  self:_reset_all_page_states()
  self._posts_inited = false
  self._is_data_active = true
  local uid = self._target_uid
  if uid == 0 then
    uid = player_module:get_player_uid()
  end
  CsLittleCornerModuleUtil.GetXhsUserProfile(uid)
  self:_refresh_user_info()
  self:_request_post_list()
end

function M:_on_toggle_my_page(is_on)
  if is_on then
    self:_change_panel(panel_type_enum.my_page)
  end
end

function M:_on_tog_thumb_posts(is_on)
  if is_on then
    self:_change_panel(panel_type_enum.thumb_post_page)
  end
end

function M:_on_tog_collection_posts(is_on)
  if is_on then
    self:_change_panel(panel_type_enum.collection_post_page)
  end
end

function M:_on_btn_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._target_uid, true)
  self._is_followed = true
  self:_refresh_follow_btn_state()
end

function M:_on_btn_not_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._target_uid, false)
  self._is_followed = false
  self:_refresh_follow_btn_state()
end

function M:_on_btn_following_list()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  if not self._is_self and not little_corner_module:is_target_profile_tab_visible(CsLittleCornerModuleUtil.TargetProfileFollowingTabVisibility) then
    UIUtil.show_tips_by_text_id("LittleCorner_UI_TabPrivacyTip")
    return
  end
  local extra_data = {
    title = UIUtil.get_text_by_id("Xhs_UI_Text18"),
    list_type = "following",
    target_uid = self._target_uid
  }
  UIManagerInstance:open("UI/LittleCorner/LittleCornerFollowingListDialog", extra_data)
end

function M:_on_btn_follower_list()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  if not self._is_self and not little_corner_module:is_target_profile_tab_visible(CsLittleCornerModuleUtil.TargetProfileFollowerTabVisibility) then
    UIUtil.show_tips_by_text_id("LittleCorner_UI_TabPrivacyTip")
    return
  end
  local extra_data = {
    title = UIUtil.get_text_by_id("Xhs_UI_Text19"),
    list_type = "follower",
    target_uid = self._target_uid
  }
  UIManagerInstance:open("UI/LittleCorner/LittleCornerFollowingListDialog", extra_data)
end

function M:_reset_all_page_states()
  for _, state in pairs(self._page_state) do
    state.page = 0
    state.has_more = false
    state.is_loading = false
  end
end

function M:_refresh_user_info()
  self:_refresh_tab()
  self:_refresh_my_info()
  self:_refresh_follow_info()
  self:_refresh_creator_level()
  self:_refresh_creator_level_red_point()
  self:_refresh_bg()
  self:_refresh_more_btn()
end

function M:_get_reportable_bg()
  if self._is_self then
    return nil
  end
  if CsLittleCornerModuleUtil.TargetProfileUid ~= self._target_uid then
    return nil
  end
  local custom_key = CsLittleCornerModuleUtil.TargetProfileHomepageCustomPicKey or ""
  if custom_key == "" then
    return nil
  end
  return custom_key, CsLittleCornerModuleUtil.TargetProfileHomepageContentVersion
end

function M:_refresh_more_btn()
  if is_null(self._btn_more) then
    return
  end
  UIUtil.set_active(self._btn_more, self:_get_reportable_bg() ~= nil)
end

function M:_refresh_bg()
  if is_null(self._ui_state_img) then
    return
  end
  local custom_key, preset_id
  if self._is_self and CsLittleCornerModuleUtil.HasHomepageBg then
    custom_key = CsLittleCornerModuleUtil.DisplayHomepageCustomPicKey or ""
    preset_id = CsLittleCornerModuleUtil.HomepagePresetBgId
  else
    local viewed_uid = self._is_self and player_module:get_player_uid() or self._target_uid
    if CsLittleCornerModuleUtil.TargetProfileUid ~= viewed_uid then
      return
    end
    custom_key = CsLittleCornerModuleUtil.TargetProfileHomepageCustomPicKey or ""
    preset_id = CsLittleCornerModuleUtil.TargetProfileHomepagePresetBgId
  end
  if custom_key ~= "" then
    self._ui_state_img:SetState(bg_preview_state.custom)
    self._pending_bg_pic_key = custom_key
    if self._held_bg_key ~= custom_key then
      self:_release_held_bg()
      self._held_bg_key = custom_key
      little_corner_module:acquire_profile_bg_photo(custom_key, function(success, photo_data)
        if is_null(self._img_pic_custom) or self._pending_bg_pic_key ~= custom_key then
          return
        end
        if not success or is_null(photo_data) then
          return
        end
        photo_data:LoadPhotoTextureAsync(function(has_tex)
          if is_null(self._img_pic_custom) or self._pending_bg_pic_key ~= custom_key or is_null(photo_data.photoSprite) then
            return
          end
          self._img_pic_custom.sprite = photo_data.photoSprite
          _set_aspect_ratio(self._img_pic_custom_ratio, photo_data.photoSprite)
        end)
      end)
    end
  else
    self._pending_bg_pic_key = nil
    self:_release_held_bg()
    self._ui_state_img:SetState(bg_preview_state.preset)
    if preset_id == 0 then
      preset_id = little_corner_module.default_homepage_bg_id
    end
    local cfg = little_corner_module:get_homepage_bg_cfg(preset_id)
    if cfg ~= nil then
      UIUtil.set_image(self._img_pic_preset, cfg.path1, self:get_load_proxy())
    end
  end
end

function M:_refresh_tab()
  UIUtil.set_active(self._tog_thumb_posts, self._is_self)
  local collection_visible = self._is_self or little_corner_module:is_target_profile_tab_visible(CsLittleCornerModuleUtil.TargetProfileFavoriteTabVisibility)
  UIUtil.set_active(self._tog_collection_posts, collection_visible)
  if self._is_self then
    UIUtil.set_text_by_id(self._txt_tab_post_unselect, "Xhs_UI_Text21")
    UIUtil.set_text_by_id(self._txt_tab_post_select, "Xhs_UI_Text21")
    UIUtil.set_text_by_id(self._txt_tab_liked_select, "Xhs_UI_Text22")
    UIUtil.set_text_by_id(self._txt_tab_liked_unselect, "Xhs_UI_Text22")
    UIUtil.set_text_by_id(self._txt_tab_collect_unselect, "Xhs_UI_Text23")
    UIUtil.set_text_by_id(self._txt_tab_collect_select, "Xhs_UI_Text23")
  else
    UIUtil.set_text_by_id(self._txt_tab_post_unselect, "Xhs_UI_Text24")
    UIUtil.set_text_by_id(self._txt_tab_post_select, "Xhs_UI_Text24")
    UIUtil.set_text_by_id(self._txt_tab_liked_select, "Xhs_UI_Text25")
    UIUtil.set_text_by_id(self._txt_tab_liked_unselect, "Xhs_UI_Text25")
    UIUtil.set_text_by_id(self._txt_tab_collect_unselect, "Xhs_UI_Text26")
    UIUtil.set_text_by_id(self._txt_tab_collect_select, "Xhs_UI_Text26")
  end
end

function M:_refresh_my_info()
  if self._is_self then
    local player_name = player_module:get_player_name()
    UIUtil.set_text(self._txt_name, player_name)
    local server_data = player_module:get_player_data().playerServerData
    local avatar_id = server_data.AvatarID
    local avatar_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id)
    if avatar_cfg and avatar_cfg.respath then
      UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
    end
  elseif CsLittleCornerModuleUtil.TargetProfileUid == self._target_uid then
    UIUtil.set_text(self._txt_name, CsLittleCornerModuleUtil.TargetProfileUname)
    local avatar_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), CsLittleCornerModuleUtil.TargetProfileAvatarId)
    if avatar_cfg and avatar_cfg.respath then
      UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
    end
  end
end

function M:_sync_followed_from_profile()
  if self._is_self then
    return false
  end
  if CsLittleCornerModuleUtil.TargetProfileUid ~= self._target_uid then
    return false
  end
  self._is_followed = CsLittleCornerModuleUtil.TargetProfileIsFollowed
  return true
end

function M:_refresh_follow_info()
  if self._is_self then
    if CsLittleCornerModuleUtil.HasMyProfile then
      UIUtil.set_text(self._txt_thumb_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyTotalLikes))
      UIUtil.set_text(self._txt_post_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyPostCount))
      UIUtil.set_text(self._txt_follow_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyFollowingCount))
      UIUtil.set_text(self._txt_follower_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyFollowerCount))
    end
  elseif CsLittleCornerModuleUtil.TargetProfileUid == self._target_uid then
    UIUtil.set_text(self._txt_thumb_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfileTotalLikes))
    UIUtil.set_text(self._txt_post_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfilePostCount))
    UIUtil.set_text(self._txt_follow_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfileFollowingCount))
    UIUtil.set_text(self._txt_follower_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfileFollowerCount))
    self:_sync_followed_from_profile()
    UIUtil.set_active(self._ui_state_group_follow_btn, true)
    self:_refresh_follow_btn_state()
  end
end

function M:_refresh_follow_btn_state()
  self._ui_state_group_follow_btn:SetState(self._is_followed and 1 or 0)
  if self._is_followed then
    self:_refresh_not_follow_btn_text()
  end
end

function M:_refresh_not_follow_btn_text()
  local is_mutual = self._is_followed and CsLittleCornerModuleUtil.TargetProfileIsFollowingMe
  local text_ids = little_corner_module.follow_btn_text_id
  local text_id = is_mutual and text_ids.mutual_follow or text_ids.unfollow
  UIUtil.set_text_by_id(self._btn_not_follow, text_id)
end

function M:_change_panel(panel_type)
  if self._cur_panel_type == panel_type then
    return
  end
  self._cur_panel_type = panel_type
  self._posts_inited = false
  local state = self._page_state[panel_type]
  if little_corner_module:try_block_little_corner_with_tip() then
    self:_refresh_post_list()
    return
  end
  if state.page == 0 and not state.is_loading then
    self:_request_post_list()
  else
    self:_refresh_post_list()
  end
end

function M:_request_post_list()
  local state = self._page_state[self._cur_panel_type]
  if state.is_loading then
    return
  end
  if self._cur_panel_type == panel_type_enum.my_page and state.page == 0 then
    local posts = CsLittleCornerModuleUtil.ProfilePosts
    if not_null(posts) and 0 < posts.Count then
      self:_on_profile_data_updated(panel_type_enum.my_page)
    else
      self:_refresh_post_list()
    end
    return
  end
  state.is_loading = true
  local page = state.page
  if self._cur_panel_type == panel_type_enum.my_page then
    CsLittleCornerModuleUtil.GetProfileUserPosts(self._target_uid, page)
  elseif self._cur_panel_type == panel_type_enum.thumb_post_page then
    CsLittleCornerModuleUtil.GetProfileLikedPosts(self._target_uid, page)
  elseif self._cur_panel_type == panel_type_enum.collection_post_page then
    CsLittleCornerModuleUtil.GetProfileFavoritePosts(self._target_uid, page)
  end
end

function M:_on_profile_data_updated(panel_type)
  local state = self._page_state[panel_type]
  state.is_loading = false
  state.page = state.page + 1
  if panel_type == panel_type_enum.my_page then
    state.has_more = CsLittleCornerModuleUtil.ProfilePostsHasMore
  elseif panel_type == panel_type_enum.thumb_post_page then
    state.has_more = CsLittleCornerModuleUtil.ProfileLikedPostsHasMore
  elseif panel_type == panel_type_enum.collection_post_page then
    state.has_more = CsLittleCornerModuleUtil.ProfileFavoritePostsHasMore
  end
  if self._cur_panel_type == panel_type then
    self:_refresh_post_list()
  end
end

function M:_on_post_interaction_changed(related_panel_type)
  if not self._is_data_active then
    return
  end
  if not self._posts_inited then
    return
  end
  if self._cur_panel_type == related_panel_type then
    self:_reload_current_post_list()
  else
    self._waterfall_scroll_post_list:RefreshCurrent()
  end
end

function M:_on_reach_bottom()
  local state = self._page_state[self._cur_panel_type]
  if not state.has_more or state.is_loading then
    return
  end
  self:_request_post_list()
end

function M:_get_current_show_posts()
  if self._cur_panel_type == panel_type_enum.my_page then
    return CsLittleCornerModuleUtil.ProfilePosts
  elseif self._cur_panel_type == panel_type_enum.thumb_post_page then
    return CsLittleCornerModuleUtil.ProfileLikedPosts
  elseif self._cur_panel_type == panel_type_enum.collection_post_page then
    return CsLittleCornerModuleUtil.ProfileFavoritePosts
  end
end

function M:_refresh_post_list()
  local posts = self:_get_current_show_posts()
  self._cached_posts = posts
  if is_null(posts) then
    UIUtil.set_active(self._trans_empty_group, true)
    return
  end
  local post_count = posts.Count
  if not self._posts_inited then
    self._post_items = {}
    self._item_instance_ids = {}
    self._waterfall_scroll_post_list:Init(pack(self, self._refresh_post_item), post_count)
    self._posts_inited = true
  else
    local current_count = self._waterfall_scroll_post_list.ItemCount
    if post_count > little_corner_module.max_feed_posts then
      self._waterfall_scroll_post_list:ReLoad(pack(self, M._refresh_post_item), post_count)
    elseif post_count > current_count then
      self._waterfall_scroll_post_list:AppendItems(post_count)
    elseif post_count == current_count then
      self._waterfall_scroll_post_list:RefreshCurrent()
    else
      self._waterfall_scroll_post_list:ReLoad(pack(self, M._refresh_post_item), post_count)
    end
  end
  UIUtil.set_active(self._trans_empty_group, post_count == 0)
end

function M:_reload_current_post_list()
  local posts = self:_get_current_show_posts()
  self._cached_posts = posts
  local post_count = not_null(posts) and posts.Count or 0
  self._waterfall_scroll_post_list:ReLoad(pack(self, M._refresh_post_item), post_count)
  UIUtil.set_active(self._trans_empty_group, post_count == 0)
end

function M:_refresh_post_item(trans, index)
  local posts = self._cached_posts
  if is_null(posts) or posts.Count == 0 then
    return
  end
  local post_view = posts[index]
  if is_null(post_view) then
    return
  end
  local instance_id = trans:GetInstanceID()
  self._item_instance_ids[index] = instance_id
  local cls_obj = self._post_items[instance_id]
  if is_null(cls_obj) then
    cls_obj = self:add_panel(post_view_item_cls, trans)
    self._post_items[instance_id] = cls_obj
  end
  self._item_extra.post_view = post_view
  self._item_extra.enable_pin = self._is_self and self._cur_panel_type == panel_type_enum.my_page
  cls_obj:set_extra_data(self._item_extra)
  cls_obj:force_refresh()
end

return M
