local M = G.Class("MiYouZhuOrderTypeTabItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._order_type = nil
  self._order = nil
  self._on_selected = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
end

function M:setup(order_type, text_id, img_path, on_selected)
  self._order_type = order_type
  self._on_selected = on_selected
  UIUtil.set_text_by_id(self._txt_tab, text_id)
  UIUtil.set_image(self._img_icon, img_path, self:get_load_proxy())
end

function M:refresh(order, is_selected)
  self._order = order
  self:set_active(order ~= nil)
  self:set_selected(order ~= nil and is_selected)
  self:_refresh_red_point()
  self:_refresh_tracking_item()
end

function M:set_selected(is_selected)
  if not_null(self._toggle) then
    self._toggle:SetIsOnWithoutNotify(is_selected)
  end
end

function M:get_order_type()
  return self._order_type
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  local is_new = self._order ~= nil and npc_house_order_module:is_order_state_unreleased(self._order) and not npc_house_order_module:is_order_read(self._order.OrderCfgId)
  self._red_point:ShowRedPoint(is_new and RedPointType.NewRp or RedPointType.None)
end

function M:_refresh_tracking_item()
  if is_null(self._trans_tracking_item) then
    return
  end
  local is_tracking = self._order ~= nil and tracking_module:is_tracking_by_track_type(tracking_module.track_type.feature, tracking_module.data_source_type.miyouzhu, self._order.OrderCfgId)
  UIUtil.set_active(self._trans_tracking_item, is_tracking)
  if is_tracking and not_null(self._tracking_state_group) then
    local state = tracking_module:get_tracking_point_style(tracking_module.track_type.feature, tracking_module.data_source_type.miyouzhu, self._order.OrderCfgId)
    self._tracking_state_group:SetState(state)
  end
end

function M:_on_toggle_changed(is_on)
  if not is_on or self._order == nil then
    return
  end
  if self._order ~= nil and npc_house_order_module:is_order_state_unreleased(self._order) and not npc_house_order_module:is_order_read(self._order.OrderCfgId) then
    npc_house_order_module:mark_order_as_read(self._order.OrderCfgId)
    self:_refresh_red_point()
  end
  if self._on_selected ~= nil then
    self._on_selected(self._order_type)
  end
end

return M
