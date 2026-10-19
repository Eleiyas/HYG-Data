local M = G.Class("BlueprintCustomItem", G.UIPanel)
local base = G.UIPanel
local STATE_USED = 0
local STATE_REVIEW = 1

function M:init()
  base.init(self)
  self._data = nil
  self._btn_item = nil
  self._img_pic = nil
  self._txt_name = nil
  self._ui_state_group = nil
  self._txt_favorite_num = nil
  self._txt_paste_num = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_item) then
    self:bind_callback(self._btn_item, pack(self, M._on_btn_item_click))
  end
  if not_null(self._txt_favorite_num) then
    UIUtil.set_active(self._txt_favorite_num, false)
  end
  if not_null(self._txt_paste_num) then
    UIUtil.set_active(self._txt_paste_num, false)
  end
  self._current_cover_photo = nil
  
  function self._load_cover_cb(success, file_key)
    self:_on_cover_loaded(success, file_key)
  end
end

function M:refresh(data, on_click)
  self._data = data
  self._on_click = on_click
  if data == nil then
    self._current_cover_photo = nil
    self:set_active(false)
    return
  end
  self:_set_state(new_blueprint_module:is_under_review(data) and STATE_REVIEW or STATE_USED)
  UIUtil.set_text(self._txt_name, data.Name)
  self:_refresh_cover(data)
end

function M:_set_state(state)
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(state)
  end
end

function M:_refresh_cover(data)
  if is_null(self._img_pic) then
    return
  end
  UIUtil.set_active(self._img_pic, false)
  local image_key = data.ImageKey
  if image_key == nil or image_key == "" then
    self._current_cover_photo = nil
    return
  end
  local cover_photo = CsNewBlueprintModuleUtil.GetCoverPhoto(image_key)
  self._current_cover_photo = cover_photo
  if is_null(cover_photo) then
    return
  end
  cover_photo:LoadPhotoThumbnailTextureAsync(self._load_cover_cb)
end

function M:_on_cover_loaded(success, file_key)
  if is_null(self.game_obj) then
    return
  end
  if not success then
    return
  end
  if self._data == nil or is_null(file_key) then
    return
  end
  if self._data.ImageKey ~= file_key then
    return
  end
  local cover_photo = self._current_cover_photo
  if is_null(cover_photo) or is_null(cover_photo.photoThumbnailSprite) then
    return
  end
  UIUtil.set_image(self._img_pic, cover_photo.photoThumbnailSprite, self:get_load_proxy())
  UIUtil.set_active(self._img_pic, true)
end

function M:_on_btn_item_click()
  if self._on_click then
    self._on_click(self._data)
    return
  end
  if self._data == nil then
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintCustomInfoPage", {
    bp_guid = self._data.BpGuid
  })
end

return M
