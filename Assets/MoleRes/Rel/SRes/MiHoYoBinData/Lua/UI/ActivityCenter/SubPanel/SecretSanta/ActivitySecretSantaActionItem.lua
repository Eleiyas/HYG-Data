local M = G.Class("ActivitySecretSantaActionItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._callback = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn, pack(self, M._on_click))
end

function M:refresh(text, callback)
  UIUtil.set_text(self._txt, text)
  self._callback = callback
end

function M:_on_click()
  if self._callback then
    self._callback()
  end
end

return M
