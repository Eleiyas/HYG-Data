local M = G.Class("SpringFestivalShoppingMainPanel", G.UIPanel)
local base = G.UIPanel
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_buy_click = data.on_buy_click
  self._on_close_click = data.on_close_click
  self._coin_view = nil
  self._token_item_id = 0
  if self._btn_buy ~= nil then
    self:bind_callback(self._btn_buy, pack(self, M._on_click_buy))
  end
  if self._btn_close ~= nil then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
  end
  self:_refresh_coin_view()
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  data = data or {}
  self._on_buy_click = data.on_buy_click
  self._on_close_click = data.on_close_click
end

function M:_on_click_buy()
  if self._on_buy_click ~= nil then
    self._on_buy_click()
  end
end

function M:_on_click_close()
  if self._on_close_click ~= nil then
    self._on_close_click()
  end
end

function M:refresh_page_title(page_title_text_id)
  if self._txt_page_title == nil then
    return
  end
  local text_id = page_title_text_id
  if not string.is_valid(text_id) then
    text_id = "SpringFestival_Shopping_SubTitle_01"
  end
  UIUtil.set_text_by_id(self._txt_page_title, text_id)
end

function M:_refresh_coin_view()
  if self._token_item_id == nil or self._token_item_id <= 0 then
    self._token_item_id = spring_festival_exchange_module:get_token_item_id() or 0
  end
  if self._token_item_id <= 0 or self._obj_coin_item == nil then
    return
  end
  if self._coin_view == nil then
    self._coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item, {
      coin_id = self._token_item_id,
      auto_update = true
    })
    return
  end
  self._coin_view:set_data({
    coin_id = self._token_item_id,
    auto_update = true
  })
end

function M:refresh_selected(goods, extra_can_buy, page_title_text_id)
  self:_refresh_coin_view()
  local has_goods = goods ~= nil and 0 < (goods.goods_id or 0)
  self:refresh_page_title(page_title_text_id)
  local can_buy = has_goods and (goods.remain_buy_num == nil or goods.remain_buy_num ~= 0)
  if extra_can_buy ~= nil then
    can_buy = can_buy and extra_can_buy == true
  end
  if self._btn_buy ~= nil then
    self._btn_buy.interactable = can_buy
  end
end

return M
