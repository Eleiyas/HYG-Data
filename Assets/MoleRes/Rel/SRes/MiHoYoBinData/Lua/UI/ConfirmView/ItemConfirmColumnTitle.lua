local M = G.Class("ItemConfirmColumnTitle", G.UIBase)
local base = G.UIBase
local color_util = gelian_market_module.color_util

function M:render(group)
  UIUtil.set_text(self._txt_title, group and group.title or "")
  local show_fluctuate = group ~= nil and group.key == "ordinary"
  UIUtil.set_active(self._trans_price_fluctuate, show_fluctuate)
  if not show_fluctuate then
    return
  end
  local fluctuate = group.price_fluctuate or 0
  local color_key = color_util.get_direction_bg_color_key(false)
  local text_color_key = color_util.get_trend_color_key(color_util.TREND_STATE.Flat, true)
  self._state_group_fluctuate:SetState(1)
  UIUtil.set_text(self._txt_amount_dynamic, TextMapFormatUtil.FormatPercent(-math.abs(fluctuate), 0), text_color_key)
  UIUtil.set_image_color(self._img_bg, color_key)
  UIUtil.set_image_color(self._img_arrow, text_color_key)
end

function M:set_title(title)
  UIUtil.set_text(self._txt_title, title or "")
end

return M
