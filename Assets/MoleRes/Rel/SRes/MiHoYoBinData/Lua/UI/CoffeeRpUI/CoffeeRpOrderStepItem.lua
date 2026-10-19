local M = G.Class("CoffeeRpOrderStepItem", G.UIBase)
local base = G.UIBase

function M:on_disable()
  base.on_disable(self)
  self._icon_path = nil
end

function M:refresh(model)
  self.guid = model.guid
  UIUtil.set_text(self._txt_player_name, model.name or UIUtil.get_text_by_id("CoffeeRp_PlayerLeft"))
  if self._icon_path ~= model.icon_path then
    self._icon_path = model.icon_path
    UIUtil.set_image(self._img_player_icon_enabled, model.icon_path, self:get_load_proxy())
    UIUtil.set_image(self._img_player_icon_disabled, model.icon_path, self:get_load_proxy())
  end
  UIUtil.set_active(self._go_enabled, model.current)
  UIUtil.set_active(self._go_disabled, not model.current)
end

return M
