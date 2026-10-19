local M = G.Class("ShopTabTogItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._info = nil
  self._callback = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
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

function M:_add_ui_listener()
  self:bind_callback(self._tog, pack(self, M._on_tog_click))
end

function M:_on_tog_click(is_on)
  if self._callback then
    self._callback(is_on)
  end
end

function M:refresh(info, callback)
  self._info = info
  self._callback = callback
  self:_refresh_ui()
end

function M:refresh_tracking_state(tracking_data, store_ui_cfg_id, index)
  if CsShopModuleUtil.IsShowTrackingByStoreUICfgIdAndIndex(store_ui_cfg_id, index - 1) then
    UIUtil.set_active(self._obj_tracking_point, true)
    self._ui_state_group_type:SetState(tracking_module:get_tracking_point_style(tracking_data.track_type, tracking_data.source_type, tracking_data.source_id))
  else
    UIUtil.set_active(self._obj_tracking_point, false)
  end
end

function M:get_tog()
  return self._tog
end

function M:is_show()
  if is_null(self._info) or not self._info:IsShow() then
    return false
  end
  return true
end

function M:_refresh_ui()
  if is_null(self._info) or not self._info:IsShow() then
    self:set_active(false)
    return
  end
  self:set_active(true)
  if not is_null(self._img_select_icon) then
    UIUtil.set_image(self._img_select_icon, self._info:GetIconPath(), self:get_load_proxy())
    UIUtil.set_image(self._img_unselect_icon, self._info:GetIconPath(), self:get_load_proxy())
  else
    UIUtil.set_image(self._img_icon, self._info:GetIconPath(), self:get_load_proxy())
  end
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, self._info:GetName())
  end
end

return M
