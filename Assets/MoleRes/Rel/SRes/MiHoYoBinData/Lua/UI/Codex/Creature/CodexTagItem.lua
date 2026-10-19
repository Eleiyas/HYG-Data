local M = G.Class("CodexTagItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(tag_text)
  UIUtil.set_text(self._txt_tag, tag_text or "")
end

return M
