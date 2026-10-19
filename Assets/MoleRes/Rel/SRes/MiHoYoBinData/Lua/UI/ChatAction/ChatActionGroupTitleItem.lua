local M = G.Class("ChatActionGroupTitleItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:refresh(title_text_id)
  if string.is_valid(title_text_id) then
    UIUtil.set_text_by_id(self._txt_title, title_text_id)
  end
  self:set_active(true)
end

return M
