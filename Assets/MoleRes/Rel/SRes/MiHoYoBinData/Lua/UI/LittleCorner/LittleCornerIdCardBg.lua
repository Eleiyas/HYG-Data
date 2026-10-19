local M = G.Class("LittleCornerIdCardBg", G.UIPanel)
local base = G.UIPanel
local bg_preview_state = little_corner_module.bg_preview_state

local function _set_aspect_ratio(fitter, sprite)
  if not_null(fitter) and not_null(sprite) and sprite.rect.height > 0 then
    fitter.aspectRatio = sprite.rect.width / sprite.rect.height
  end
end

function M:init()
  base.init(self)
  self._temp_photo = nil
  self._pending_pic_key = nil
  self._held_bg_key = nil
  self._ui_state_group = nil
  self._img_preset = nil
  self._img_custom = nil
  self._img_custom_ratio = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self:_release_held_bg()
end

function M:_release_held_bg()
  if self._held_bg_key then
    little_corner_module:release_profile_bg_photo(self._held_bg_key)
    self._held_bg_key = nil
  end
end

function M:reset_bg()
  self._pending_pic_key = nil
  self:_release_held_bg()
end

function M:show_preset(cfg)
  if cfg == nil then
    return
  end
  self._pending_pic_key = nil
  self:_release_held_bg()
  self._ui_state_group:SetState(bg_preview_state.preset)
  UIUtil.set_image(self._img_preset, cfg.path2, self:get_load_proxy())
end

function M:show_custom(sprite)
  self._pending_pic_key = nil
  self:_release_held_bg()
  self._ui_state_group:SetState(bg_preview_state.custom)
  if not_null(self._img_custom) then
    self._img_custom.sprite = sprite
    _set_aspect_ratio(self._img_custom_ratio, sprite)
  end
end

function M:show_custom_by_key(pic_key)
  self._ui_state_group:SetState(bg_preview_state.custom)
  self._pending_pic_key = pic_key
  if not string.is_valid(pic_key) then
    self:_release_held_bg()
    return
  end
  if self._held_bg_key == pic_key then
    return
  end
  self:_release_held_bg()
  self._held_bg_key = pic_key
  little_corner_module:acquire_profile_bg_photo(pic_key, function(success, photo_data)
    if is_null(self._img_custom) or self._pending_pic_key ~= pic_key then
      return
    end
    if not success or is_null(photo_data) then
      return
    end
    photo_data:LoadPhotoTextureAsync(function(has_tex)
      if is_null(self._img_custom) or self._pending_pic_key ~= pic_key or is_null(photo_data.photoSprite) then
        return
      end
      self._img_custom.sprite = photo_data.photoSprite
      _set_aspect_ratio(self._img_custom_ratio, photo_data.photoSprite)
    end)
  end)
end

return M
