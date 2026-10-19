local M = G.Class("FamilyCommentDeletePanel", G.UIPanel)
local base = G.UIPanel

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_callback(self._btn_close, pack(self, M._on_cancel_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_cancel_click))
  self:bind_callback(self._btn_delete, pack(self, M._on_delete_click))
end

function M:set_selected_count(count)
  local text = UIUtil.get_text_by_id("Liuyanban_Edit_Num")
  UIUtil.set_text(self._txt_delete_number, text .. TextMapFormatUtil.FormatInteger(count))
end

function M:_on_cancel_click()
  if self.holder and self.holder.on_delete_panel_cancel then
    self.holder:on_delete_panel_cancel()
  end
end

function M:_on_delete_click()
  if self.holder and self.holder.on_delete_panel_delete then
    self.holder:on_delete_panel_delete()
  end
end

return M
