local M = G.Class("LittleCornerPostListSimpleItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._current_cover_photo = nil
  self._load_thumbnail_callback = nil
  self._txt_nub = nil
  self._btn_item = nil
  self._img_aspect_ratio = nil
  self._anim_good_group = nil
  self._ui_state_group = nil
  self._trans_loading = nil
  self._img_post_cover = nil
  self._img_pinned = nil
  self._trans_category = nil
  self._txt_categroy = nil
end

function M:on_create()
  base.on_create(self)
  
  function self._load_thumbnail_callback(success, file_key)
    self:_on_thumbnail_loaded(success, file_key)
  end
end

function M:on_open()
  base.on_open(self)
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item))
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._current_cover_photo = nil
end

function M:on_destroy()
  base.on_destroy(self)
  self._load_thumbnail_callback = nil
end

function M:register_events()
  base.register_events(self)
end

function M:_on_btn_item()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  if not_null(self._post_view) then
    local extra = self._enable_pin and {
      post_view = self._post_view,
      show_pin = true
    } or self._post_view
    UIManagerInstance:open("UI/LittleCorner/LittleCornerViewDialog", extra)
  end
end

function M:_refresh_ui()
  if is_null(self._post_view) then
    return
  end
  UIUtil.set_text(self._txt_nub, TextMapFormatUtil.FormatAbbreviation(self._post_view.Thumb))
  self:_refresh_cover_photo()
  self:_refresh_mark_state()
  self:_refresh_category()
end

function M:_refresh_cover_photo()
  if not_null(self._post_view) then
    local cover_photo = CsLittleCornerModuleUtil.GetPostCoverPhoto(self._post_view)
    UIUtil.set_active(self._img_post_cover, false)
    if not_null(cover_photo) then
      self._current_cover_photo = cover_photo
      cover_photo:LoadPhotoThumbnailTextureAsync(self._load_thumbnail_callback)
    end
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
    UIUtil.set_image(self._img_post_cover, cover_photo.photoThumbnailSprite, self:get_load_proxy())
    local h = cover_photo.photoThumbnailSprite.rect.height
    if 0 < h then
      self._img_aspect_ratio.aspectRatio = cover_photo.photoThumbnailSprite.rect.width / h
    end
    UIUtil.set_active(self._img_post_cover, true)
  end
end

function M:_refresh_mark_state()
  if is_null(self._post_view) then
    return
  end
  local pinned = CsLittleCornerModuleUtil.IsPinnedPost(self._post_view.PostId)
  local multi_photo = false
  if self._post_view then
    local file_key = self._post_view.PicKey
    local _, photo_count = file_key:gsub("|", "")
    multi_photo = 0 < photo_count
  end
  local state = 0
  if pinned and multi_photo then
    state = 2
  elseif pinned and not multi_photo then
    state = 1
  elseif not pinned and multi_photo then
    state = 3
  end
  self._ui_state_group:SetState(state)
end

function M:_refresh_category()
  if is_null(self._post_view) then
    return
  end
  local category_id = self._post_view.Category
  local category_name = ""
  if category_id ~= 0 then
    local category_cfg = ExcelDataUtil.get_value(typeof(BXhsCategoryCfg), category_id)
    category_name = category_cfg and category_cfg.name or ""
  end
  UIUtil.set_active(self._trans_category, category_name ~= "")
  if category_name ~= "" then
    UIUtil.set_text(self._txt_categroy, category_name)
  end
end

function M:force_refresh()
  local extra_data = self:get_extra_data()
  self._post_view = extra_data.post_view
  self._enable_pin = extra_data.enable_pin or false
  self:_refresh_ui()
end

return M
