local base = require("UI/HairDyeing/HairDyeingColorCellBase")
local M = G.Class("HairDyeingColorSysItem", base)

function M:init()
  base.init(self)
  self._sys_id = nil
  self._owned = true
  self._on_click = nil
end

function M:refresh(data)
  self._sys_id = data.sys_id
  self._owned = data.owned == nil and true or data.owned == true
  local show_icon = string.is_valid(data.icon_path)
  UIUtil.set_active(self._img_color, not show_icon)
  UIUtil.set_active(self._img_icon, show_icon)
  if show_icon then
    UIUtil.set_image(self._img_icon, data.icon_path, self:get_load_proxy())
  elseif data.display_color then
    UIUtil.set_image_color(self._img_color, data.display_color)
  end
  self:set_selected(data.selected == true)
end

function M:get_sys_id()
  return self._sys_id
end

function M:_notify(is_on)
  if self._on_click then
    self._on_click(self._sys_id, is_on)
  end
end

return M
