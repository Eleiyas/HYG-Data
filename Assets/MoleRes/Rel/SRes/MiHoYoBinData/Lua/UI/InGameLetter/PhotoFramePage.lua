local M = G.Class("PhotoFramePage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/InGameLetter/PhotoFramePage"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_parse_extra_data()
  self:_refresh_frame()
  self:_refresh_photo()
  self:_refresh_birthday_time()
end

function M:on_disable()
  base.on_disable(self)
  self:_release_owned_photo_data()
  self._item_id = nil
  self._photo_key = nil
  self._birthday_time = nil
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not_null(self._btn_close) then
    self:bind_callback(self._btn_close, function()
      self:close_self()
    end)
  end
  if not_null(self._btn_mask) then
    self:bind_callback(self._btn_mask, function()
      self:close_self()
    end)
  end
end

function M:_parse_extra_data()
  local data = self:get_extra_data()
  if is_null(data) then
    return
  end
  self._item_id = data.item_id
  self._photo_key = data.photo_key
  self._photo_data = nil
  self._own_photo_data = false
  self._birthday_time = data.birthday_time
end

function M:_refresh_frame()
  if is_null(self._img_frame) then
    return
  end
  local icon_path
  local item_id = self._item_id or 0
  if 0 < item_id then
    local frame_cfg = LocalDataUtil.get_value(typeof(PhotoFrameItemFrameCfg), item_id)
    icon_path = frame_cfg and frame_cfg.frameImagePath
  end
  if string.is_valid(icon_path) then
    UIUtil.set_active(self._img_frame, true)
    UIUtil.set_image(self._img_frame, icon_path, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_frame, false)
  end
end

function M:_refresh_birthday_time()
  if is_null(self._txt_birthday_time) then
    return
  end
  local timestamp = tonumber(self._birthday_time) or 0
  if timestamp <= 0 then
    UIUtil.set_active(self._txt_birthday_time, false)
    return
  end
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(timestamp)
  UIUtil.set_text(self._txt_birthday_time, TextMapFormatUtil.FormatDateYMD(date_time))
  UIUtil.set_active(self._txt_birthday_time, true)
end

function M:_refresh_photo()
  if is_null(self._img_photo) then
    return
  end
  if not string.is_valid(self._photo_key) then
    return
  end
  local photo_key = self._photo_key
  if is_null(self._photo_data) then
    CsAlbumManagerUtil.PrepareTemporaryCloudPhotoForPreview(photo_key, function(success, photo_data)
      if not success or is_null(photo_data) or self._photo_key ~= photo_key then
        if not_null(photo_data) then
          CsAlbumManagerUtil.ReleaseTemporaryCloudPhotoForPreview(photo_data)
        end
        return
      end
      self:_release_owned_photo_data()
      self._photo_data = photo_data
      self._own_photo_data = true
      self:_refresh_photo_sprite(photo_key, photo_data)
    end)
    return
  end
  self:_refresh_photo_sprite(photo_key, self._photo_data)
end

function M:_refresh_photo_sprite(photo_key, photo_data)
  if is_null(photo_data) or is_null(self._img_photo) then
    return
  end
  photo_data:LoadPhotoTextureAsync(function(has_tex)
    if not has_tex or self._photo_key ~= photo_key or is_null(photo_data.photoSprite) then
      return
    end
    local photo_rect = photo_data.photoSprite.rect
    if not_null(self._aspect_fitter) and photo_rect.height > 0 then
      self._aspect_fitter.aspectRatio = photo_rect.width / photo_rect.height
    end
    UIUtil.set_image(self._img_photo, photo_data.photoSprite, self:get_load_proxy())
  end)
end

function M:_release_owned_photo_data()
  if self._own_photo_data and not_null(self._photo_data) then
    CsAlbumManagerUtil.ReleaseTemporaryCloudPhotoForPreview(self._photo_data)
  end
  self._photo_data = nil
  self._own_photo_data = false
end

return M
