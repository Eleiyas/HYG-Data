local M = G.Class("AvatarInfoEditorSettingPanel", G.UIPanel)
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
  self:refresh_view()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_clicked))
  self:bind_callback(self._btn_close_bg, pack(self, M._on_btn_close_clicked))
  self:bind_callback(self._toggle_auto_save, pack(self, M._on_toggle_auto_save_clicked))
end

function M:refresh_view()
  if not is_null(self._trans_auto_save) then
    UIUtil.set_active(self._trans_auto_save, true)
  end
  local key = self.holder:get_auto_save_key()
  if key == nil then
    self._toggle_auto_save.isOnValue = false
    self._toggle_auto_save.interactable = false
    self._toggle_auto_save.enabled = false
    return
  end
  self._toggle_auto_save.enabled = true
  self._toggle_auto_save.interactable = true
  self._toggle_auto_save.isOnValue = CsLocalSaveDataUtil.GetBool(key, false)
end

function M:try_handle_back()
  if not self.holder:is_setting_active() then
    return false
  end
  self:_on_btn_close_clicked()
  return true
end

function M:_on_btn_close_clicked()
  self.holder:refresh_setting_active(false)
end

function M:_on_toggle_auto_save_clicked(is_on)
  local key = self.holder:get_auto_save_key()
  if key == nil then
    return
  end
  if is_on and avatar_info_editor_module.try_block_diy_with_tip() then
    self._toggle_auto_save.isOnValue = false
    return
  end
  if CsLocalSaveDataUtil.GetBool(key, false) == is_on then
    return
  end
  CsLocalSaveDataUtil.SetBool(key, is_on)
  self.holder:reset_auto_save_timer()
  self.holder:refresh_auto_save_ui()
end

return M
