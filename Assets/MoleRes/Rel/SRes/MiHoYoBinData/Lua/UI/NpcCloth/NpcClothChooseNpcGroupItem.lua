local M = G.Class("NpcClothChooseNpcGroupItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:refresh(data)
  if data == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  UIUtil.set_text(self._txt_shape_dynamic, data.title or "")
end

return M
