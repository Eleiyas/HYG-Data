local M = G.Class("InterviewThemeItem", G.UIBase)
local base = G.UIBase

function M:refresh(text_id, topic)
  UIUtil.set_text_by_id(self._txt_des, text_id, topic)
end

return M
