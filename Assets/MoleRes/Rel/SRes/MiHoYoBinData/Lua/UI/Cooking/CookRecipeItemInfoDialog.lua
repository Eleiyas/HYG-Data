local M = G.Class("CookRecipeItemInfoDialog", "UI/Item/ItemInfoDialog")
local base = G.ItemInfoDialog

function M:_refresh_data()
  base._refresh_data(self)
  local extra_data = self:get_extra_data()
  if is_null(extra_data) then
    return
  end
  self._is_learned = extra_data.is_learned
end

function M:_refresh_tag_style_ui()
  base._refresh_tag_style_ui(self)
  if not self._is_learned then
    UIUtil.set_active(self._trans_tag_style_parent, false)
  end
end

return M
