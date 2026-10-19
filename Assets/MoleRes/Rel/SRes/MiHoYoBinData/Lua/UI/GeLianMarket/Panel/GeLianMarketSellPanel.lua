local M = G.Class("GeLianMarketSellPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._sell_host = nil
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._sell_host = context and context.sell_host or nil
  item_module:set_item_icon(self._img_coin_icon, back_bag_module.coin_type.gold, nil, nil, self:get_load_proxy())
  self:bind_callback(self._btn_sale, pack(self, M._on_sale_clicked))
  self:render_sell_bar(nil)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  self._sell_host = nil
  base.on_destroy(self)
end

function M:render_sell_bar(view_data)
  local total_price = view_data and view_data.total_price or 0
  local select_count = view_data and view_data.select_count or 0
  UIUtil.set_text(self._txt_coin_num, math.modf(total_price or 0))
  self._btn_sale.interactable = 0 < select_count
  if 0 < select_count then
    UIUtil.set_text(self._txt_sale_title, string.format(UIUtil.get_text_by_id("Market_Sell_Confirm_Btn"), select_count))
  else
    UIUtil.set_text_by_id(self._txt_sale_title, "Sell_Trans_Choosing")
  end
end

function M:_on_sale_clicked()
  if self._sell_host ~= nil and type(self._sell_host.request_sell) == "function" then
    self._sell_host.request_sell()
  end
end

return M
