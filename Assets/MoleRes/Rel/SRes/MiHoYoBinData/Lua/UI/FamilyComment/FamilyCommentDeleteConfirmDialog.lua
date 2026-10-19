local M = G.Class("FamilyCommentDeleteConfirmDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentDeleteConfirmDialog"
  self.config.type = EUIType.Dialog
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._guid_list = data.guid_list or {}
  self._tag_list = data.tag_list or {}
  self._on_confirm = data.on_confirm
  self._on_cancel = data.on_cancel
  self._confirmed = false
  UIUtil.set_text_by_id(self._txt_confirm_delete, "Liuyanban_Delete_Summary", TextMapFormatUtil.FormatInteger(#self._guid_list), TextMapFormatUtil.FormatInteger(#self._tag_list))
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
  local guid_list = self._guid_list
  local tag_list = self._tag_list
  if callback and callback(guid_list, tag_list) == false then
    self._confirmed = false
    return
  end
  self:close_self()
end

return M
