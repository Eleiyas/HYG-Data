local M = G.Class("LittleCornerMyInfoCardSelectItem", G.UIPanel)
local base = G.UIPanel
M.state = little_corner_module.card_item_state

function M:init()
  base.init(self)
  self._on_selected = nil
  self._suppress_toggle = false
  self._ui_state = nil
  self._icon = nil
  self._tog_item = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_item, pack(self, M._on_toggle))
end

function M:_on_toggle(is_on)
  if self._suppress_toggle then
    return
  end
  if is_on and self._on_selected ~= nil then
    self._on_selected()
  end
end

function M:set_selected_callback(callback)
  self._on_selected = callback
end

function M:set_selected(is_selected)
  if is_null(self._tog_item) then
    return
  end
  self._suppress_toggle = true
  self._tog_item.isOn = is_selected
  self._suppress_toggle = false
end

function M:refresh(entry, state)
  self._ui_state:SetState(state)
  if entry ~= nil and not entry.is_custom and entry.cfg ~= nil and not_null(self._icon) then
    UIUtil.set_image(self._icon, entry.cfg.icon, self:get_load_proxy())
  end
end

return M
