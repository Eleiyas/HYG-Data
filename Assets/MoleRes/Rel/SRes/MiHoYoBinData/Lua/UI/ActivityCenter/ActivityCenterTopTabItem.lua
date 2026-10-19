local M = G.Class("ActivityCenterTopTabItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh(data)
  if data == nil then
    self:set_active(false)
    return
  end
  self._data = data
  self:set_active(true)
  local icon = activity_center_module.top_tab_icon[data.category]
  if string.is_valid(icon) then
    UIUtil.set_image(self._icon, activity_center_module.top_tab_icon[data.category], self:get_load_proxy())
  end
  self:refresh_red_dot()
end

function M:refresh_red_dot()
  local category = self._data and self._data.category or 0
  local rp_type = activity_center_module:get_any_red_dot_type_by_tab_category(category)
  self._red_point:ShowRedPoint(rp_type)
end

function M:set_selected(is_on)
  if not is_null(self._toggle) then
    self._toggle.isOn = is_on
  end
end

function M:get_toggle()
  return self._toggle
end

function M:get_category()
  return self._data and self._data.category or 0
end

return M
