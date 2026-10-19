local M = G.Class("GeLianMarketSellCoinItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  item_module:set_item_icon(self._img_coin_icon, back_bag_module.coin_type.gold, nil, nil, self:get_load_proxy())
end

function M:render(total_price)
  UIUtil.set_text(self._txt_coin_num, math.modf(total_price or 0))
end

return M
