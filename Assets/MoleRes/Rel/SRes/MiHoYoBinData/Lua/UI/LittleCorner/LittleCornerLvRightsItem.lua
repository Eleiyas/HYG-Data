local M = G.Class("LittleCornerLvRightsItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(index, icon, desc)
  UIUtil.set_text_by_id(self._txt_num, "LittleCorner_UI_012", index)
  UIUtil.set_image(self._img_dynamic, icon, self:get_load_proxy())
  UIUtil.set_text(self._txt_info, desc)
end

return M
