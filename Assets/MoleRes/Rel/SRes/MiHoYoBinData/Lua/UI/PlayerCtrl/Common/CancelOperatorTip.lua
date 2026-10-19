local M = G.Class("CancelOperatorTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn) then
    self:bind_callback(self._btn, pack(self, M._on_cancel_click))
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:_on_cancel_click()
  EventCenter.Broadcast(EventID.ChangeUIControlMode, PlayerCtrlUIMode.Common)
end

return M
