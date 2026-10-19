local M = G.Class("LittleCornerIDCardDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerIDCardDialog"
  self.config.type = EUIType.Dialog
  self._user_id = 0
  self._is_followed = false
  self._post_imgs = {}
  self._post_aspects = {}
  self._cover_photos = {}
  self._img_head = nil
  self._txt_name = nil
  self._trans_lv_bg = nil
  self._txt_lv = nil
  self._ui_state_group_btn = nil
  self._btn_not_follow = nil
  self._txt_thumb_num = nil
  self._txt_follower_num = nil
  self._txt_post_num = nil
  self._img_post_1 = nil
  self._img_aspect_post_1_ = nil
  self._img_post_2 = nil
  self._img_aspect_post_2 = nil
  self._img_post_3 = nil
  self._img_aspect_post_3 = nil
  self._btn_homepage = nil
  self._btn_close_popup = nil
  self._btn_follow = nil
  self._trans_id_card_bg = nil
end

function M:on_create()
  base.on_create(self)
  self._post_imgs = {
    self._img_post_1,
    self._img_post_2,
    self._img_post_3
  }
  self._post_aspects = {
    self._img_aspect_post_1_,
    self._img_aspect_post_2,
    self._img_aspect_post_3
  }
  self._id_card_bg = self:add_panel("UI/LittleCorner/LittleCornerIdCardBg", self._trans_id_card_bg)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data() or {}
  self._user_id = extra_data.user_id or 0
  self._is_followed = extra_data.is_followed or false
  self:_refresh_ui()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._cover_photos = {}
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsFollowChanged, function(data)
    local target_uid = data.value1
    local is_followed = data.value2
    if target_uid == self._user_id then
      self._is_followed = is_followed
      self:_refresh_follow_state()
    end
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_popup)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close_popup, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_follow, pack(self, M._on_btn_follow))
  self:bind_callback(self._btn_not_follow, pack(self, M._on_btn_not_follow))
  self:bind_callback(self._btn_homepage, pack(self, M._on_btn_homepage))
end

function M:_on_btn_close()
  self:close_self()
end

function M:_on_btn_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._user_id, true)
  self._is_followed = true
  self:_refresh_follow_state()
end

function M:_on_btn_not_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._user_id, false)
  self._is_followed = false
  self:_refresh_follow_state()
end

function M:_on_btn_homepage()
  self:close_self()
  little_corner_module:open_user_info_page(self._user_id)
end

function M:_refresh_ui()
  if not CsLittleCornerModuleUtil.HasTargetProfile then
    return
  end
  UIUtil.set_text(self._txt_name, CsLittleCornerModuleUtil.TargetProfileUname)
  UIUtil.set_text(self._txt_thumb_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfileTotalLikes))
  UIUtil.set_text(self._txt_follower_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfileFollowerCount))
  UIUtil.set_text(self._txt_post_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.TargetProfilePostCount))
  local avatar_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), CsLittleCornerModuleUtil.TargetProfileAvatarId)
  if not_null(avatar_cfg) and avatar_cfg.respath then
    UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
  end
  self:_refresh_creator_level()
  self:_refresh_id_card_bg()
  self:_refresh_follow_state()
  self:_refresh_posts()
end

function M:_refresh_creator_level()
  local level = math.max(CsLittleCornerModuleUtil.TargetProfileCreatorLevel, 1)
  UIUtil.set_active(self._trans_lv_bg, true)
  UIUtil.set_text(self._txt_lv, string.format("Lv. %d", level))
end

function M:_refresh_id_card_bg()
  if self._id_card_bg == nil then
    return
  end
  local custom_key = CsLittleCornerModuleUtil.TargetProfileHomepageCustomPicKey or ""
  if custom_key ~= "" then
    self._id_card_bg:show_custom_by_key(custom_key)
    return
  end
  local preset_id = CsLittleCornerModuleUtil.TargetProfileHomepagePresetBgId
  if preset_id == 0 then
    preset_id = little_corner_module.default_homepage_bg_id
  end
  self._id_card_bg:show_preset(little_corner_module:get_homepage_bg_cfg(preset_id))
end

function M:_refresh_follow_state()
  self._ui_state_group_btn:SetState(self._is_followed and 1 or 0)
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

function M:_refresh_posts()
  local pinned_posts = CsLittleCornerModuleUtil.ProfilePinnedPosts
  local pinned_count = 0
  if not_null(pinned_posts) then
    pinned_count = pinned_posts.Count
  end
  local max_post_count = little_corner_module:get_pinned_post_max_count()
  local posts
  local post_count = 0
  if 0 < pinned_count then
    posts = pinned_posts
    post_count = pinned_count
  else
    local recent_posts = CsLittleCornerModuleUtil.ProfilePosts
    if not_null(recent_posts) then
      post_count = recent_posts.Count
    end
    posts = recent_posts
  end
  if max_post_count < post_count then
    post_count = max_post_count
  end
  for i = 1, max_post_count do
    if i <= post_count then
      UIUtil.set_active(self._post_imgs[i], true)
      local post = posts[i - 1]
      self:_load_post_cover(i, post.PostId)
    else
      UIUtil.set_active(self._post_imgs[i], false)
    end
  end
end

function M:_load_post_cover(index, post_id)
  CsLittleCornerModuleUtil.GetPostCoverPhoto(post_id, function(photo_obj)
    if is_null(self.game_obj) then
      return
    end
    local cover_photo = photo_obj
    if is_null(cover_photo) then
      UIUtil.set_active(self._post_imgs[index], false)
      return
    end
    self._cover_photos[index] = cover_photo
    cover_photo:LoadPhotoThumbnailTextureAsync(function(success, file_key)
      if is_null(self.game_obj) then
        return
      end
      if not success then
        return
      end
      local photo = self._cover_photos[index]
      if is_null(photo) or is_null(photo.photoThumbnailSprite) then
        return
      end
      UIUtil.set_image(self._post_imgs[index], photo.photoThumbnailSprite, self:get_load_proxy())
      if not_null(self._post_aspects[index]) then
        self._post_aspects[index].aspectRatio = photo.photoThumbnailSprite.rect.width / photo.photoThumbnailSprite.rect.height
      end
      UIUtil.set_active(self._post_imgs[index], true)
    end)
  end)
end

return M
