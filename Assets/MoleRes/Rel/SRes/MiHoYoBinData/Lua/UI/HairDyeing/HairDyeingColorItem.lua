local base = require("UI/HairDyeing/HairDyeingColorCellBase")
local M = G.Class("HairDyeingColorItem", base)

function M:init()
  base.init(self)
  self._color_id = nil
  self._is_display_only = false
  self._is_preview_only = false
  self._on_click = nil
end

function M:refresh(data)
  self._color_id = data.color_id
  self._owned = data.owned == true
  self._is_display_only = data.display_only == true
  self._is_preview_only = data.preview_only == true
  local icon_path = CsDyeingModuleUtil.GetColorBlockIconPath(self._color_id)
  local show_icon = not self._is_display_only and string.is_valid(icon_path)
  UIUtil.set_active(self._img_color, not show_icon)
  UIUtil.set_active(self._img_icon, show_icon)
  if show_icon then
    UIUtil.set_image(self._img_icon, icon_path, self:get_load_proxy())
  else
    local color = CsDyeingModuleUtil.GetDisplayColorByColorBlockId(self._color_id)
    UIUtil.set_image_color(self._img_color, color)
  end
  self:set_selected((not self._is_display_only or self._is_preview_only) and data.selected == true)
end

function M:get_color_id()
  return self._color_id
end

function M:_notify(is_on)
  if self._is_display_only and not self._is_preview_only then
    return
  end
  if self._on_click then
    self._on_click(self._color_id, self._owned, is_on)
  end
end

return M
