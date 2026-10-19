local M = G.Class("CoffeeRpPlayerItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_select, function()
    self:_on_click()
  end)
end

function M:on_disable()
  base.on_disable(self)
  self._icon_path = nil
end

function M:refresh(model, on_changed)
  self.guid = model.guid
  self._on_changed = on_changed
  self._enabled = model.can_order
  self._selected = self._enabled and model.selected or false
  UIUtil.set_text(self._txt_player_name, model.name or UIUtil.get_text_by_id("CoffeeRp_PlayerLeft"))
  if self._icon_path ~= model.icon_path then
    self._icon_path = model.icon_path
    UIUtil.set_image(self._img_player_icon, model.icon_path, self:get_load_proxy())
  end
  UIUtil.set_active(self._go_disabled, not self._enabled)
  self:_refresh_selected()
end

function M:_refresh_selected()
  UIUtil.set_active(self._go_selected, self._enabled and self._selected)
end

function M:_on_click()
  if not self._enabled then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("CoffeeRp_OrderPage_Toast_1"))
    return
  end
  self._selected = not self._selected
  self:_refresh_selected()
  if self._on_changed then
    self._on_changed(self.guid, self._selected)
  end
end

return M
