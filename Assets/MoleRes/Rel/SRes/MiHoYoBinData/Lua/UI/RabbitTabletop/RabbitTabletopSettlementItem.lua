local M = G.Class("RabbitTabletopSettlementItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  if is_null(data) then
    return
  end
  self._data = data
  UIUtil.set_text(self._txt_result, data.title or "")
  UIUtil.set_text(self._txt_num, data.num or "")
  if string.is_valid(data.icon) then
    UIUtil.set_image(self._img_icon, data.icon, self:get_load_proxy())
  end
  self._state_group_limit:SetState(data.is_limit and 0 or 1)
end

return M
