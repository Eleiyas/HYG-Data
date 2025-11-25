local M = G.Class("MaskInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "Launch/UI/Item/MaskInfo"
  self.config.type = EUIType.Info
  self._show_mask_texture = false
  self._texture_cache = nil
end

function M:on_create()
  base.on_create(self)
  InputManagerIns:set_touch_mask_init()
end

function M:set_mask_texture(texture)
  self._img_raw.texture = texture
  self._img_raw.color = ColorUtil.get_color(ColorUtil.C.white)
end

function M:clear_mask_texture()
  if not is_null(self._texture_cache) then
    UIUtil.destroy_go(self._texture_cache)
    self._texture_cache = nil
  end
  if self._img_raw == nil or self._show_mask_texture == false then
    return
  end
  self._show_mask_texture = false
  self._img_raw.texture = nil
  self._img_raw.color = ColorUtil.get_color(ColorUtil.C.transparent)
end

function M:on_enable()
  base.on_enable(self)
  local mask_type = self:get_extra_data()
  if mask_type == nil then
    self:clear_mask_texture()
  elseif mask_type == EUIMask.BlackScreen then
    self._img_raw.texture = nil
    self._img_raw.color = ColorUtil.get_color(ColorUtil.C.black)
    self.binder:PlayAnim("fade")
  elseif mask_type == EUIMask.ScreenCapture then
    self._img_raw.color = ColorUtil.get_color(ColorUtil.C.white)
    if self._img_raw.texture == nil then
      CsUIUtil.CaptureScreen(function(texture)
        texture.name = "MaskInfo"
        self._img_raw.texture = texture
        self._texture_cache = texture
      end)
    end
  else
    self:clear_mask_texture()
  end
  self._show_mask_texture = true
end

function M:on_disable()
  base.on_disable(self)
  self:clear_mask_texture()
end

return M
