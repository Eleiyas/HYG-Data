local ItemV2Panel = require("UI/Item/ItemV2Panel")
local M = G.Class("NpcImpressionHallExchangeItem", ItemV2Panel)
local base = ItemV2Panel

function M:init()
  base.init(self)
  self._selected = false
  self._on_select = nil
  self._tog = nil
  self._red_point = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog) then
    self:bind_callback(self._tog, pack(self, M._on_toggle_value_changed))
  end
end

function M:on_destroy()
  self._on_select = nil
  base.on_destroy(self)
end

function M:set_lock_state(state)
  if not_null(self._ui_state_group_lock) then
    self._ui_state_group_lock:SetState(state or 0)
  end
end

function M:set_get_state(state)
  if not_null(self._ui_state_group_get) then
    self._ui_state_group_get:SetState(state or 0)
  end
end

function M:set_red_point(rp_type)
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(rp_type or RedPointType.None)
  end
end

function M:set_toggle_click(fn)
  self._on_select = fn
end

function M:set_selected(is_selected)
  self._selected = is_selected == true
  if not_null(self._tog) then
    self._tog:SetIsOnWithoutNotify(self._selected)
  end
end

function M:_on_toggle_value_changed(is_on)
  if not is_on then
    if self._selected then
      self:set_selected(true)
    end
    return
  end
  if self._on_select then
    self._on_select()
  end
end

return M
