local M = G.Class("CommonIconConfirmDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/Dialog/ConfirmPopup_Icon"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_yes, function()
    self:_close_with_callback(self._yes_callback)
  end)
  self:bind_callback(self._btn_no, function()
    self:_close_with_callback(self._no_callback)
  end)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._yes_callback = data.yes_callback
  self._no_callback = data.no_callback
  if data.icon then
    UIUtil.set_active(self._img_npc, true)
    UIUtil.set_image(self._img_npc, data.icon or "", self:get_load_proxy())
  else
    UIUtil.set_active(self._img_npc, false)
  end
  UIUtil.set_text(self._txt_title, data.title or "")
  UIUtil.set_text(self._txt_content, data.content or "")
  if data.yes_text then
    UIUtil.set_text(self._txt_btn_yes, data.yes_text)
  end
  if data.no_text then
    UIUtil.set_text(self._txt_btn_no, data.no_text)
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, function()
    self:_close_with_callback(self._no_callback)
  end)
end

function M:_close_with_callback(callback)
  self:close_self()
  if callback then
    callback()
  end
end

return M
