local M = G.Class("GalacticBazaarMapDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticBazaarMapDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_close, function()
    self:close_self()
  end)
end

return M
