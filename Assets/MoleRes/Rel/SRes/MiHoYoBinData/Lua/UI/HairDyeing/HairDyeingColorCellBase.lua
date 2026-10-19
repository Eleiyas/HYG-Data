local M = G.Class("HairDyeingColorCellBase", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._owned = false
  self._selected = false
  self._suppress = false
  self._is_toggle = false
  self._on_click = nil
end

function M:on_create()
  base.on_create(self)
  self:_bind_control()
end

function M:_bind_control()
  if self._tog_item ~= nil and not is_null(self._tog_item) then
    self._is_toggle = true
    self:bind_callback(self._tog_item, pack(self, M._on_toggle_changed))
    return
  end
  self._is_toggle = false
  local btn = self._btn_item
  if btn == nil or is_null(btn) then
    btn = self._btn_select
  end
  self:bind_callback(btn, pack(self, M._on_btn_click))
end

function M:set_selected(is_select)
  self._selected = is_select
  if self._is_toggle then
    if self._tog_item.SetIsOnWithoutNotify then
      self._tog_item:SetIsOnWithoutNotify(is_select)
    else
      self._suppress = true
      self._tog_item.isOn = is_select
      self._suppress = false
    end
  end
  self:_refresh_state()
end

function M:_refresh_state()
  self._ui_start_group_worn:SetState(hair_dyeing_module:calc_worn_state(self._owned, self._selected))
end

function M:get_selected()
  return self._selected
end

function M:is_owned()
  return self._owned
end

function M:set_on_click(callback)
  self._on_click = callback
end

function M:_on_btn_click()
  self:_notify(true)
end

function M:_on_toggle_changed(is_on)
  if self._suppress then
    return
  end
  self._selected = is_on
  self:_refresh_state()
  self:_notify(is_on)
end

function M:_notify(is_on)
end

return M
