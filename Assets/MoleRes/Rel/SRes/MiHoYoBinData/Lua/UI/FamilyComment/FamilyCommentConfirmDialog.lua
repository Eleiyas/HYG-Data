local M = G.Class("FamilyCommentConfirmDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentConfirmDialog"
  self.config.type = EUIType.Dialog
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._on_confirm = data.on_confirm
  self._on_cancel = data.on_cancel
  self._confirmed = false
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_cancel_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_cancel_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_confirm_click))
end

function M:_on_cancel_click()
  local callback = self._on_cancel
  self:close_self()
  if callback then
    callback()
  end
end

function M:_on_confirm_click()
  if self._confirmed then
    return
  end
  self._confirmed = true
  local callback = self._on_confirm
  if callback and callback() == false then
    self._confirmed = false
    return
  end
  self:close_self()
end

return M
