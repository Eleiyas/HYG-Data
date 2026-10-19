local M = G.Class("TagGroupItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(value)
  UIUtil.set_text(self._txt_tag, value or "")
end

return M
