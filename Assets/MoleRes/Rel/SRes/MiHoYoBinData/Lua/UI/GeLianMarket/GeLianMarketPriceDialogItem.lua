local M = G.Class("GeLianMarketPriceDialogItem", G.UIBase)
local base = G.UIBase

function M:render(view_data)
  if view_data == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), view_data.config_id)
  UIUtil.set_text(self._txt_type, item_cfg and item_cfg.name or "")
  UIUtil.set_text(self._txt_price, view_data.price or 0)
end

return M
