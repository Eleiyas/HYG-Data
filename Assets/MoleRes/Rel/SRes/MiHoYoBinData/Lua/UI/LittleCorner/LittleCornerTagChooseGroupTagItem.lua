local M = G.Class("LittleCornerTagChooseGroupTagItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._toggle = nil
  self._txt_type_1 = nil
  self._txt_type_2 = nil
  self._tag_id = nil
  self._dialog = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
  self:_refresh_ui()
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if not data then
    return
  end
  self._tag_id = data.tag_id
  self._dialog = data.dialog
  local tag_name = little_corner_module:get_tag_name(self._tag_id)
  UIUtil.set_text(self._txt_type_1, tag_name)
  UIUtil.set_text(self._txt_type_2, tag_name)
  local is_selected = self._dialog:is_tag_selected(self._tag_id)
  self._toggle.isOnValue = is_selected
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:force_refresh()
  self:_refresh_ui()
end

function M:_add_ui_listener()
  self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
end

function M:_on_toggle_changed(is_on)
  if not self._dialog or not self._tag_id then
    return
  end
  local accepted = self._dialog:on_tag_toggled(self._tag_id, is_on)
  if not accepted then
    self._toggle.isOnValue = not is_on
  end
end

return M
