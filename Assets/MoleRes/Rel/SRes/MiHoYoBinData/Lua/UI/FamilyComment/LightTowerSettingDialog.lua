local M = G.Class("LightTowerSettingDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/LightTowerSettingDialog"
  self.config.type = EUIType.Dialog
  self._suppress_callback = false
end

function M:on_enable()
  base.on_enable(self)
  self:_init_permission_options()
  self:_refresh_permission()
end

function M:_init_permission_options()
  self._dropdown_permission:ClearOptions()
  local options = {"公开", "私密"}
  for _, text in ipairs(options) do
    local option = Dropdown.OptionData()
    option.text = text
    self._dropdown_permission.options:Add(option)
  end
  self._dropdown_permission:RefreshShownValue()
end

function M:_refresh_permission()
  self._dropdown_permission:SetValueWithoutNotify(family_comment_module:get_permission())
  self._dropdown_permission:RefreshShownValue()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._on_back_action))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._dropdown_permission, pack(self, M._on_permission_changed))
end

function M:_on_back_action()
  self:close_self()
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_permission_changed(index)
  if self._suppress_callback or index == family_comment_module:get_permission() then
    return
  end
  self._pending_permission = index
  family_comment_module:open_confirm_dialog({
    on_confirm = pack(self, M._on_permission_confirm),
    on_cancel = pack(self, M._on_permission_cancel)
  })
end

function M:_on_permission_confirm()
  if family_comment_module:set_permission(self._pending_permission) then
    self:close_self()
    return true
  else
    self:_refresh_permission()
    return false
  end
end

function M:_on_permission_cancel()
  self:_refresh_permission()
end

return M
