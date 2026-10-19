local M = G.Class("ActivityCenterActTabItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  if data == nil then
    self:set_active(false)
    return
  end
  self._data = data
  self:set_active(true)
  self:_refresh_title()
  self:_refresh_state()
  self:_refresh_kv()
  self:refresh_red_dot()
end

function M:_refresh_title()
  local ui_cfg = activity_center_module:get_ui_cfg(self._data.activity_id)
  local title = ui_cfg ~= nil and ui_cfg.activityname or ""
  UIUtil.set_text(self._txt_select_title, title)
  UIUtil.set_text(self._txt_unselect_title, title)
end

function M:_refresh_state()
  local state = activity_center_module:get_activity_state(self._data.activity_id)
  UIUtil.set_active(self._trans_achieve, state == activity_center_module.activity_state.Finished)
end

function M:_refresh_kv()
  if is_null(self._img_kv) then
    return
  end
  local activity_id = self._data and self._data.activity_id or 0
  local ui_cfg = activity_center_module:get_ui_cfg(activity_id)
  if ui_cfg and string.is_valid(ui_cfg.listicon) then
    UIUtil.set_active(self._img_kv, true)
    UIUtil.set_image(self._img_kv, ui_cfg.listicon, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_kv, false)
  end
end

function M:refresh_red_dot()
  local activity_id = self._data and self._data.activity_id or 0
  local rp_type = activity_center_module:get_red_dot_type(activity_id)
  self._red_point:ShowRedPoint(rp_type)
end

function M:set_selected(is_on)
  self._toggle.isOn = is_on
end

function M:get_activity_id()
  return self._data and self._data.activity_id or 0
end

function M:get_toggle()
  return self._toggle
end

function M:is_great_style()
  return not is_null(self._img_kv)
end

function M:get_act_tab_type()
  if self:is_great_style() then
    return activity_center_module.act_tab_type.kv
  end
  return activity_center_module.act_tab_type.normal
end

return M
