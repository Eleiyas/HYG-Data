local M = G.Class("MiYouZhuNpcTabItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._orders = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  self:bind_callback(self._toggle, pack(self, M._on_click))
end

function M:_on_click(is_on)
  if not is_on then
    self._toggle:SetIsOnWithoutNotify(true)
    return
  end
  if self.holder and self._npc_id then
    self.holder:_on_npc_selected(self._npc_id)
  end
end

function M:set_selected(is_on)
  if self._toggle then
    self._toggle:SetIsOnWithoutNotify(is_on)
  end
end

function M:refresh(npc_id, orders)
  self._npc_id = npc_id
  self._orders = orders or {}
  npc_module:set_npc_icon_by_id(self._img_npc, npc_id, self:get_load_proxy())
  local is_all_finished = #self._orders > 0
  for _, order in ipairs(self._orders) do
    if not npc_house_order_module:is_order_state_finished(order) then
      is_all_finished = false
      break
    end
  end
  UIUtil.set_active(self._trans_mark, is_all_finished)
  self:refresh_red_point()
end

function M:refresh_red_point()
  if is_null(self._red_point_container) then
    return
  end
  local has_unread_order = false
  for _, order in ipairs(self._orders) do
    if npc_house_order_module:is_order_state_unreleased(order) and not npc_house_order_module:is_order_read(order.OrderCfgId) then
      has_unread_order = true
      break
    end
  end
  self._red_point_container:ShowRedPoint(has_unread_order and RedPointType.NewRp or RedPointType.None)
end

return M
