local M = G.Class("SettingVoiceAssetsItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._on_check_changed = nil
  self._on_uncheckable_clicked = nil
  self._can_check = false
  self._state_layout_trans = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_item, pack(self, M._on_item_clicked))
  self:bind_callback(self._tog_check, pack(self, M._on_toggle_changed))
  self._state_layout_trans = UIUtil.find_rect_trans(self.trans, "layout_group_horizontal")
end

function M:on_destroy()
  self._on_check_changed = nil
  self._on_uncheckable_clicked = nil
  base.on_destroy(self)
end

function M:render(data, on_check_changed, on_uncheckable_clicked)
  self:set_active(data ~= nil)
  if data == nil then
    self._can_check = false
    return
  end
  self._on_check_changed = nil
  self._on_uncheckable_clicked = nil
  self._can_check = data.can_delete == true
  UIUtil.set_text(self._txt_voice_name, data.display_name or "")
  UIUtil.set_text(self._txt_voice_state, data.state_text or "")
  UIUtil.set_active(self._tog_check, self._can_check)
  self._tog_check.isOnValue = data.is_checked == true
  self._on_check_changed = on_check_changed
  self._on_uncheckable_clicked = on_uncheckable_clicked
  if not is_null(self._state_layout_trans) then
    LayoutRebuilder.ForceRebuildLayoutImmediate(self._state_layout_trans)
  end
end

function M:_on_item_clicked()
  if not self._can_check then
    if self._on_uncheckable_clicked ~= nil then
      self._on_uncheckable_clicked()
    end
    return
  end
  local is_on = not self._tog_check.isOn
  self._tog_check.isOnValue = is_on
  self:_on_toggle_changed(is_on)
end

function M:_on_toggle_changed(is_on)
  if self._on_check_changed ~= nil then
    self._on_check_changed(is_on)
  end
end

return M
