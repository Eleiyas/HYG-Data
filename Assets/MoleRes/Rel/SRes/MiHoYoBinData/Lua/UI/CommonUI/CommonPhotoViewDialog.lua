local M = G.Class("CommonPhotoViewDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonPhotoViewDialog"
  self.config.type = EUIType.Dialog
  self._sprite = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_bg, pack(self, M._close))
  self:bind_callback(self._btn_close, pack(self, M._close))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
  self:_clear_sprite()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_refresh()
  local data = self._extra_data
  if data == nil then
    return
  end
  self:_clear_sprite()
  if not_null(data.sprite) then
    self._img_photo.sprite = data.sprite
    self:_apply_aspect(data.sprite.rect.width, data.sprite.rect.height)
  elseif not_null(data.texture) then
    local tex = data.texture
    self._sprite = CS.UnityEngine.Sprite.Create(tex, CS.UnityEngine.Rect(0, 0, tex.width, tex.height), Vector2(0.5, 0.5))
    self._img_photo.sprite = self._sprite
    self:_apply_aspect(tex.width, tex.height)
  end
end

function M:_apply_aspect(w, h)
  if 0 < w and 0 < h then
    self._aspect_fitter.aspectRatio = w / h
  end
end

function M:_clear_sprite()
  if not_null(self._sprite) then
    CS.UnityEngine.Object.Destroy(self._sprite)
    self._sprite = nil
  end
end

function M:_close()
  self:close_self()
end

return M
