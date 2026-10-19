local M = G.Class("NpcClothGelianShopGroupItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  if is_null(data) then
    self:set_active(false)
    return
  end
  self:set_active(true)
  UIUtil.set_text(self._txt_title, data.title or "")
end

return M
