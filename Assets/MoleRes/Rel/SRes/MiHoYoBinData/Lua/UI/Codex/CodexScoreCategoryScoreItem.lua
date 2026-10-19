local M = G.Class("CodexScoreCategoryScoreItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  data = data or {}
  if not_null(self._img_icon) and data.icon then
    UIUtil.set_image(self._img_icon, data.icon, self:get_load_proxy())
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, data.title)
  end
  if not_null(self._txt_num) then
    UIUtil.set_text(self._txt_num, tostring(data.num or 0))
  end
end

return M
