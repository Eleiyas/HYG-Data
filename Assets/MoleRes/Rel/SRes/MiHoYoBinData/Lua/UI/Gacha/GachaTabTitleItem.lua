local M = G.Class("GachaTabTitleItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(title)
  UIUtil.set_text_by_id(self._txt_title, title)
end

return M
