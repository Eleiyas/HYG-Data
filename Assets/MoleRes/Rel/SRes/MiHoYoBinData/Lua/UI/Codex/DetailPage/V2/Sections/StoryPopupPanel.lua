local M = G.Class("StoryPopupPanel", G.UIPanel)

function M:show(text)
  UIUtil.set_text(self._txt_story, text or "")
  self:set_active(true)
end

function M:hide()
  self:set_active(false)
end

function M:is_showing()
  return self.is_active
end

return M
