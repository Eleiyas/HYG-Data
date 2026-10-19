local M = G.Class("CookProduceItemView", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:set_visible(visible)
  UIUtil.set_active(self.trans, visible)
end

function M:refresh(info, load_proxy)
  if not_null(self._txt_cookware_title) then
    UIUtil.set_text(self._txt_cookware_title, info.title or "")
  end
  local locked = info.locked
  local sg = self._ui_state_group_lock or self._state_group_lock
  if not_null(sg) then
    sg:SetState(locked and 0 or 1)
  end
end

return M
