local M = G.Class("CoffeeRpInviteConfirmPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_accept, function()
    if self._on_accept then
      self._on_accept()
    end
  end)
  self:bind_callback(self._btn_reject, function()
    if self._on_reject then
      self._on_reject()
    end
  end)
end

function M:set_callbacks(callbacks)
  self._on_accept = callbacks and callbacks.on_accept
  self._on_reject = callbacks and callbacks.on_reject
end

function M:refresh(model)
  UIUtil.set_text(self._txt_player_name, model.player_name)
  UIUtil.set_text(self._txt_coffee_message, model.coffee_message)
  self:set_countdown_fill(0)
end

function M:set_countdown_fill(progress)
  if not_null(self._img_countdown_fill) then
    self._img_countdown_fill.fillAmount = math.min(progress, 1)
  end
end

return M
