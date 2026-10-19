local M = G.Class("AvatarInfoEditorSingleEntityPanel", G.UIPanel)
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

function M:update(deltaTime)
  base.update(self, deltaTime)
  local can_rotate = self.holder:can_rotate_selected_decoration()
  local can_cancel = self.holder:has_selected_decoration()
  local can_withdraw = self.holder:can_withdraw_selected_decoration()
  self._btn_rotate.interactable = can_rotate
  UIUtil.set_active(self._trans_rotate_tip, can_rotate)
  self._btn_cancel.interactable = can_cancel
  UIUtil.set_active(self._trans_cancel_tip, can_cancel)
  self._btn_withdraw.interactable = can_withdraw
  UIUtil.set_active(self._trans_withdraw_tip, can_withdraw)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_cancel, pack(self, M.on_btn_cancel_click))
  self:bind_callback(self._btn_rotate, pack(self, M.on_btn_rotate_click))
  self:bind_callback(self._btn_withdraw, pack(self, M.on_btn_withdraw_click))
  self:bind_callback(self._btn_info, pack(self, M.on_btn_info_click))
end

function M:try_handle_back()
  if not self._extra_data then
    return false
  end
  self:on_btn_cancel_click()
  return true
end

function M:on_btn_cancel_click()
  self.holder:on_single_entity_cancel()
end

function M:on_btn_rotate_click()
  self.holder:on_single_entity_rotate()
end

function M:on_btn_withdraw_click()
  self.holder:on_single_entity_withdraw()
end

function M:on_btn_info_click()
end

function M:refresh_view()
  self:set_active(self._extra_data ~= nil)
  if not self._extra_data then
    return
  end
  local config_id = self:_get_selected_decoration_config_id()
  local id_cfg = 0 < config_id and ExcelDataUtil.get_value(typeof(BIdCfg), config_id) or nil
  UIUtil.set_text(self._txt_name, id_cfg and id_cfg.name or "")
end

function M:_get_selected_decoration_config_id()
  local entity_transform = self._extra_data and self._extra_data.entity
  if is_null(entity_transform) then
    return 0
  end
  local life = entity_transform:GetComponent(typeof(CS.miHoYo.HYG.MiniPlanetDIYDecorationResourceLifetime))
  if is_null(life) or is_null(life.Entity) or not life.Entity.IsValid then
    return 0
  end
  return life.Entity.ConfigId or 0
end

return M
