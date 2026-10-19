local M = G.Class("WorldEditorMultiEntityPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  local can_withdraw = editCtrl:CanRetrieveMultiSelection()
  local can_cancel = editCtrl.MultiSelectedCount > 0
  self._btn_withdraw.interactable = can_withdraw
  UIUtil.set_active(self._trans_withdraw_tip, can_withdraw)
  self._btn_cancel.interactable = can_cancel
  UIUtil.set_active(self._trans_cancel_tip, can_cancel)
end

function M:on_disable()
  base.on_disable(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_cancel, pack(self, M.on_btn_cancel_click))
  self:bind_callback(self._btn_withdraw, pack(self, M.on_btn_withdraw_click))
end

function M:bind_input_action()
  self:bind_input_and_fun(ActionType.Act.Esc, function()
    self:on_btn_cancel_click()
  end)
  self:bind_input_and_fun(ActionType.Act.R, function()
    self:on_btn_withdraw_click()
  end)
end

function M:on_btn_cancel_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  editCtrl:DeselectAllMulti()
end

function M:on_btn_withdraw_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if not editCtrl:CanRetrieveMultiSelection() then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("WorldEditor_MultiSelect_RetrieveTip"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    AudioManagerIns:post_event_by_cfg(UEvent.Furniture_SmokeDel)
    editCtrl:RetrieveMultiSelection()
  end)
  popup:show()
end

function M:refresh_view()
  local count = self._extra_data or 0
  self:set_active(true)
  if not_null(self._txt_count) then
    UIUtil.set_text(self._txt_count, tostring(count))
  end
end

return M
