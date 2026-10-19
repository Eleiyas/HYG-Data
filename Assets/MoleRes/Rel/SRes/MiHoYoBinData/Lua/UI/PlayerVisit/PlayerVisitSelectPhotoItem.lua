local M = G.Class("PlayerVisitSelectPhotoItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_item, pack(self, M._on_btn_click))
end

function M:_on_btn_click()
  if not self._data or not self._index then
    return
  end
  if self._click_callback then
    self._click_callback(self._index)
  end
end

function M:set_info(data, index, state, click_callback)
  self._data = data
  self._index = index
  self._state = state
  self._click_callback = click_callback
  self._state_had:SetState(state.has_photo and 1 or 0)
  self._state_use:SetState(state.is_using and 0 or 1)
  self._btn_item:SetSelect(state.is_selected)
  if state.has_photo then
    self:_try_set_photo()
  end
end

function M:_try_set_photo()
  if not self._data or is_null(self._data) then
    return
  end
  local current_data = self._data
  current_data:LoadPhotoThumbnailTextureAsync(function(has_tex)
    if not has_tex then
      return
    end
    if is_null(self) or self._data ~= current_data then
      return
    end
    if is_null(self._data) or is_null(self._data.photoThumbnailSprite) then
      return
    end
    if is_null(self._img_pic) then
      return
    end
    UIUtil.set_image(self._img_pic, self._data.photoThumbnailSprite, self:get_load_proxy())
  end)
end

return M
