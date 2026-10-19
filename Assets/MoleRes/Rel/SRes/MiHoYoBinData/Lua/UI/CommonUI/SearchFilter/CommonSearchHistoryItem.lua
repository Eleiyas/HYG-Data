local M = G.Class("CommonSearchHistoryItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_select, pack(self, M._on_btn_select))
end

function M:refresh(display_text, callback)
  self._display_text = display_text or ""
  self._click_callback = callback
  UIUtil.set_text(self._txt_name, self._display_text)
  self:set_active(string.is_valid(self._display_text))
end

function M:refresh_button(button_text, callback)
  self:refresh(button_text, callback)
end

function M:_on_btn_select()
  if self._click_callback then
    self._click_callback(self._display_text)
  end
end

return M
