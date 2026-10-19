local M = G.Class("GeLianMarketFriendCropPriceItem", G.UIBase)
local base = G.UIBase
local color_util = gelian_market_module.color_util

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:render(entry)
  if entry == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  item_module:set_item_icon(self._img_icon_crop, entry.display_config_id, nil, nil, self:get_load_proxy())
  item_module:set_item_icon(self._img_coin_icon, back_bag_module.coin_type.gold, nil, nil, self:get_load_proxy())
  local display_price = math.modf(entry.final_price or 0)
  local trend_state = entry.trend_state or 2
  local color_key = color_util.get_trend_color_key(trend_state, self._is_price_txt_dark)
  UIUtil.set_text(self._txt_coin_num, display_price, color_key)
end

function M:set_price_txt_color_lightness(lightness)
  self._is_price_txt_dark = lightness and lightness == color_util.LIGHTNESS.Dark
end

return M
