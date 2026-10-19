local M = G.Class("LittleCornerPostListItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._post_view = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._current_cover_photo = nil
  
  function self._load_thumbnail_callback(success, file_key)
    self:_on_thumbnail_loaded(success, file_key)
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsPostThumbChanged, function(post_id)
    if not_null(self._post_view) and post_id == self._post_view.PostId then
      self:_refresh_thumbup_state()
    end
  end)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item))
  self:bind_callback(self._toggle_thumbup, pack(self, M._on_toggle_thumb_up))
  self:bind_callback(self._btn_head, pack(self, M._on_btn_head))
end

function M:_on_btn_item()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  if not_null(self._post_view) then
    UIManagerInstance:open("UI/LittleCorner/LittleCornerViewDialog", self._post_view)
  end
end

function M:_on_toggle_thumb_up(is_on)
  if is_null(self._post_view) then
    return
  end
  if little_corner_module:try_block_little_corner_with_tip() then
    self._toggle_thumbup.isOnValue = not is_on
    return
  end
  if is_on then
    self._anim_good_group:SetTrigger("like")
  end
  CsLittleCornerModuleUtil.ThumbXhsPost(self._post_view.PostId, is_on)
end

function M:_on_btn_head()
  if is_null(self._post_view) then
    return
  end
  little_corner_module:open_user_id_card(self._post_view.Uid)
end

function M:_refresh_ui()
  if is_null(self._post_view) then
    return
  end
  self:_refresh_post_info()
end

function M:_refresh_post_info()
  self._ui_state_group_type:SetState(self._post_view.ActivityId ~= 0 and 0 or 1)
  self:_refresh_post_player_info()
  self:_refresh_thumbup_state()
  self:_refresh_category()
  if little_corner_module.debug_mode then
    UIUtil.set_text(self._txt_title, self._post_view.PostId)
  else
    local content = self._post_view.Content
    UIUtil.set_active(self._txt_title, content ~= "")
    UIUtil.set_text(self._txt_title, content)
  end
  self:_refresh_post_photo()
  UIUtil.set_active(self._img_frame_review, self._post_view.ReviewStatus ~= nil and self._post_view.ReviewStatus == 1)
  UIUtil.set_active(self._img_frame_activity, false)
end

function M:_refresh_category()
  local category_id = self._post_view.Category
  local category_name = ""
  if category_id ~= 0 then
    local category_cfg = ExcelDataUtil.get_value(typeof(BXhsCategoryCfg), category_id)
    category_name = category_cfg and category_cfg.name or ""
  end
  UIUtil.set_active(self._trans_tag, category_name ~= "")
  if category_name ~= "" then
    UIUtil.set_text(self._txt_tag, category_name)
  end
end

function M:_refresh_post_player_info()
  UIUtil.set_text(self._txt_name, self._post_view.Uname)
  local avatar_id = self._post_view.AvatarId or 0
  local avatar_cfg = 0 < avatar_id and ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id) or nil
  local has_head = not_null(avatar_cfg) and string.is_valid(avatar_cfg.respath)
  UIUtil.set_active(self._img_head, has_head)
  if has_head then
    UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
  end
end

function M:_refresh_post_photo()
  local cover_photo = CsLittleCornerModuleUtil.GetPostCoverPhoto(self._post_view)
  UIUtil.set_active(self._pic, false)
  if not_null(cover_photo) then
    self._current_cover_photo = cover_photo
    cover_photo:LoadPhotoThumbnailTextureAsync(self._load_thumbnail_callback)
  end
end

function M:_on_thumbnail_loaded(success, file_key)
  if is_null(self.game_obj) then
    return
  end
  if not success then
    return
  end
  if is_null(self._post_view) or is_null(self._post_view.PicKey) then
    return
  end
  if is_null(file_key) then
    return
  end
  local cover_photo = self._current_cover_photo
  if is_null(cover_photo) then
    return
  end
  if string.sub(self._post_view.PicKey, 1, #file_key) == file_key and not_null(cover_photo.photoThumbnailSprite) then
    UIUtil.set_image(self._pic, cover_photo.photoThumbnailSprite, self:get_load_proxy())
    local h = cover_photo.photoThumbnailSprite.rect.height
    if 0 < h then
      self._pic_aspect_ratio.aspectRatio = cover_photo.photoThumbnailSprite.rect.width / h
    end
    UIUtil.set_active(self._pic, true)
  end
end

function M:_refresh_thumbup_state()
  if self._toggle_thumbup.isOn ~= self._post_view.IsLiked then
    self._toggle_thumbup.isOnValue = self._post_view.IsLiked
  end
  UIUtil.set_text(self._txt_nub, TextMapFormatUtil.FormatAbbreviation(self._post_view.Thumb))
end

function M:force_refresh()
  local extra_data = self:get_extra_data()
  self._post_view = extra_data.post_view
  self:_refresh_ui()
end

return M
