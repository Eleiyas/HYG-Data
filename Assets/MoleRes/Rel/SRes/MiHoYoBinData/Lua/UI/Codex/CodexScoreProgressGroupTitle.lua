local M = G.Class("CodexScoreProgressGroupTitle", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  data = data or {}
  if not_null(self._txt_title) then
    if data.title_text_id then
      UIUtil.set_text_by_id(self._txt_title, data.title_text_id)
    else
      UIUtil.set_text(self._txt_title, data.title or "")
    end
  end
  if not_null(self._img_title_icon_dynamic) and data.icon then
    UIUtil.set_image(self._img_title_icon_dynamic, data.icon, self:get_load_proxy())
  end
end

return M
