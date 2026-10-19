local M = G.Class("HairDyeingExchangeRegionTogItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._dye_part = nil
  self._on_selected = nil
  self._toggle = nil
end

function M:on_create()
  base.on_create(self)
  local extra_data = self:get_extra_data() or {}
  self._toggle = self._tog_item or extra_data.toggle
  if not_null(self._toggle) then
    local callback = pack(self, M._on_toggle_changed)
    if self._has_binder then
      self:bind_callback(self._toggle, callback)
    else
      self.holder:bind_callback(self._toggle, callback)
    end
  end
  self:_refresh_red_point()
  self:_refresh_tracking_item()
end

function M:setup(dye_part, on_selected)
  self._dye_part = dye_part
  self._on_selected = on_selected
end

function M:get_dye_part()
  return self._dye_part
end

function M:refresh(is_selected)
  self:set_selected(is_selected)
  self:_refresh_red_point()
  self:_refresh_tracking_item()
  self:refresh_icon()
  self:refresh_text()
end

function M:set_selected(is_selected)
  if is_null(self._toggle) then
    return
  end
  if self._toggle.SetIsOnWithoutNotify ~= nil then
    self._toggle:SetIsOnWithoutNotify(is_selected == true)
  else
    self._toggle.isOn = is_selected == true
  end
end

function M:refresh_icon()
end

function M:refresh_text()
end

function M:_refresh_red_point()
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
    UIUtil.set_active(self._red_point, false)
  end
end

function M:_refresh_tracking_item()
  if not_null(self._trans_tracking_item) then
    UIUtil.set_active(self._trans_tracking_item, false)
  end
end

function M:_on_toggle_changed(is_on)
  if is_on and self._on_selected then
    self._on_selected(self._dye_part)
  end
end

return M
