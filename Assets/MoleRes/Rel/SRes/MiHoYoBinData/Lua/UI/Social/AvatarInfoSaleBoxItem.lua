local M = G.Class("AvatarInfoSaleBoxItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._slot_view_data = nil
  self._item_cls = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item))
end

function M:_on_btn_item()
  if not self._slot_view_data then
    return
  end
  item_module:open_item_info_dialog(self._slot_view_data.config_id, self._slot_view_data.count)
end

function M:refresh(slot_view_data)
  self._slot_view_data = slot_view_data
  if is_null(slot_view_data) or slot_view_data.config_id == 0 then
    self._state_group_ui:SetState(1)
    return
  end
  if slot_view_data.count == 0 then
    self._state_group_ui:SetState(2)
  else
    self._state_group_ui:SetState(0)
  end
  if self._item_cls == nil then
    self._item_cls = item_module:init_item_cls(UIUtil.find_trans(self._trans_item, "content"))
  end
  item_module:set_item_cls(self._item_cls, slot_view_data.config_id, slot_view_data.count, self:get_load_proxy())
  item_module:set_item_name(self._txt_name, slot_view_data.config_id)
  UIUtil.set_text_by_id(self._txt_num, "Salebox_Upgrade_HowManyLeft", slot_view_data.count)
  UIUtil.set_text(self._txt_money, TextMapFormatUtil.FormatInteger(slot_view_data.unit_price) .. UIUtil.get_text_by_id("Salebox_Upgrade_Unit"))
end

return M
