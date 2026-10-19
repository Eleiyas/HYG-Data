local M = G.Class("FortuneWheelIntroItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(text)
  UIUtil.set_text(self._txt, text)
end

return M
