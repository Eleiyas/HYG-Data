local M = G.Class("InteractRecordSummaryBestieItem", G.UIBase)
local base = G.UIBase
local STATE_NO_PHOTO = 0
local STATE_HAS_PHOTO = 1

function M:init()
  base.init(self)
  self._cur_moment_photo = nil
  self._moment_data = nil
  self._friend_uid = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_photo, pack(self, M._on_btn_photo_click))
end

function M:on_disable()
  base.on_disable(self)
  if self._cur_moment_photo then
    self._cur_moment_photo:ClearThumbnail()
    self._cur_moment_photo = nil
  end
end

function M:refresh_view(summary_text, moment_data, friend_uid)
  self._moment_data = moment_data
  self._friend_uid = friend_uid
  UIUtil.set_text(self._txt_random, summary_text or "")
  local url = moment_data and moment_data.MomentPhotoUrl
  local has_photo = string.is_valid(url)
  self._state:SetState(has_photo and STATE_HAS_PHOTO or STATE_NO_PHOTO)
  if self._cur_moment_photo then
    self._cur_moment_photo:ClearThumbnail()
    self._cur_moment_photo = nil
  end
  if has_photo then
    local photo_data = CsAlbumManagerUtil.GetOrCreateMomentPhoto(url)
    self._cur_moment_photo = photo_data
    photo_data:LoadPhotoThumbnailTextureAsync(function(result)
      if result and not_null(self._img_photo) then
        UIUtil.set_image(self._img_photo, photo_data.photoThumbnailSprite)
      end
    end)
  end
end

function M:_on_btn_photo_click()
  friend_level_module:open_interact_photo_info(self._moment_data, self._friend_uid)
end

return M
