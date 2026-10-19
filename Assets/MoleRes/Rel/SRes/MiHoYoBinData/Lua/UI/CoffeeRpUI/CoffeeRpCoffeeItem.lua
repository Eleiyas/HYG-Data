local M = G.Class("CoffeeRpCoffeeItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_select, function()
    self:_on_click()
  end)
end

function M:refresh(model, on_selected)
  self.config_id = model.config_id
  self._on_selected = on_selected
  self.origin_value = model.price
  self.price_value = model.price
  self.sweetness = model.sweetness
  self.temperature = model.temperature
  UIUtil.set_image(self._img_icon, model.icon_path, self:get_load_proxy())
  self:set_free_price(false)
  self:set_selected(false)
end

function M:set_free_price(is_free)
  if is_free then
    self.price_value = 0
    UIUtil.set_text(self._txt_price, "<s>" .. tostring(self.origin_value) .. "</s> 0")
  else
    self.price_value = self.origin_value
    UIUtil.set_text(self._txt_price, tostring(self.price_value))
  end
end

function M:set_selected(selected)
  self._selected = selected
  UIUtil.set_active(self._go_background, not selected)
  UIUtil.set_active(self._go_selected, selected)
end

function M:_on_click()
  if self._on_selected then
    self._on_selected(self.config_id)
  end
end

return M
