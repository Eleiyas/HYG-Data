local M = G.Class("RabbitTabletopPlayerIndicate", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  if not data then
    return
  end
  UIUtil.set_text(self._txt_name, data.name or "")
  UIUtil.set_text(self._txt_num, tostring(data.card_count or 0))
  self._state_num:SetState((data.card_count or 0) <= 1 and 1 or 0)
  self._state_turn:SetState(data.turn_index or 0)
  UIUtil.set_active(self._obj_auto, data.is_afk or false)
end

return M
