local M = G.Class("CommonTxtInfoItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:refresh(text)
  UIUtil.set_text(self._txt, text or "")
end

return M
