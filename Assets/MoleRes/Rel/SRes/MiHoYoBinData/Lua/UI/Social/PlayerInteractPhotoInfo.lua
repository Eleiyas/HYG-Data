local M = G.Class("PlayerInteractPhotoInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/PlayerInteractPhotoInfo"
  self.config.type = EUIType.Info
  self._cur_moment_photo = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:refresh_view(self:get_extra_data())
end

function M:on_disable()
  base.on_disable(self)
  if self._cur_moment_photo then
    self._cur_moment_photo:ClearPhoto()
    self._cur_moment_photo = nil
  end
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:refresh_view(extra_data)
  if is_null(extra_data) or is_null(extra_data.moment_data) then
    return
  end
  local moment_data = extra_data.moment_data
  local friend_uid = extra_data.friend_uid or 0
  UIUtil.set_text(self._txt_moment, friend_level_module:get_moment_display_text(moment_data))
  local timestamp = moment_data.MomentTime or 0
  if 0 < timestamp then
    UIUtil.set_text(self._txt_time, os.date("%Y-%m-%d", math.floor(timestamp)))
  else
    UIUtil.set_text(self._txt_time, "")
  end
  local photo_url = moment_data.MomentPhotoUrl
  if not string.is_valid(photo_url) then
    UIUtil.set_active(self._img_photo, false)
    return
  end
  if self._cur_moment_photo then
    self._cur_moment_photo:ClearPhoto()
    self._cur_moment_photo = nil
  end
  local photo_data = CsAlbumManagerUtil.GetOrCreateMomentPhoto(photo_url)
  self._cur_moment_photo = photo_data
  photo_data:LoadPhotoTextureAsync(function(has_tex)
    if not has_tex or is_null(self._img_photo) then
      return
    end
    UIUtil.set_active(self._img_photo, true)
    UIUtil.set_image(self._img_photo, photo_data.photoSprite, self:get_load_proxy())
  end)
end

return M
