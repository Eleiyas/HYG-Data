local M = G.Class("QteGameExitConfirmPopup", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExplore/NpcTipsConfirmPopup"
  self.config.type = EUIType.Dialog
  self._yes_callback = nil
  self._no_callback = nil
  self._close_callback = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_no, function()
    self:_close_with_callback(self._no_callback)
  end)
  self:bind_callback(self._btn_yes, function()
    self:_close_with_callback(self._yes_callback)
  end)
  self:bind_callback(self._btn_close, function()
    self:_close_with_callback(self._close_callback)
  end)
end

function M:on_enable()
  base.on_enable(self)
  local data = self._extra_data or {}
  self._yes_callback = data.yes_callback
  self._no_callback = data.no_callback
  self._close_callback = data.close_callback or data.no_callback
  if data.npc_head then
    UIUtil.set_image(self._img_npc, data.npc_head, self:get_load_proxy())
  end
  if data.info then
    UIUtil.set_active(self._txt_info1, true)
    UIUtil.set_active(self._txt_info2, false)
    UIUtil.set_text(self._txt_info1, data.info)
  end
  if self._txt_btn_yes then
    UIUtil.set_text(self._txt_btn_yes, data.yes_text or "")
  end
  if self._txt_btn_no then
    UIUtil.set_text(self._txt_btn_no, data.no_text or "")
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, function()
    self:_close_with_callback(self._close_callback)
  end)
end

function M:_close_with_callback(callback)
  self:close_self()
  if callback then
    callback()
  end
end

return M
