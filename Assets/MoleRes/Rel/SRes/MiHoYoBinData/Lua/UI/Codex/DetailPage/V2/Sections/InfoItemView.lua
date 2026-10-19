local M = G.Class("InfoItemView", G.UIPanel)

function M:on_create()
  G.UIPanel.on_create(self)
end

function M:refresh_info(title, value)
  if not_null(self._txt_info_title) then
    UIUtil.set_text(self._txt_info_title, title or "")
  end
  if not_null(self._txt_info) then
    UIUtil.set_text(self._txt_info, value or "")
  end
end

return M
