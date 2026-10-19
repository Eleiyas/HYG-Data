local M = G.Class("GeLianMarketLeftPanel", "UI/GeLianMarket/Panel/GeLianMarketContainerPanel")
local base = G.GeLianMarketContainerPanel
local market_page_service_cls = require("UI/GeLianMarket/GeLianMarketPageService")
local SaleState = {NonSale = 0, Sale = 1}

function M:init()
  base.init(self)
  self._host = nil
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._host = context and context.host or nil
  self:bind_callback(self._btn_friend, pack(self, M._on_friend_price_clicked))
  self:bind_callback(self._btn_board, pack(self, M._on_leave_message_clicked))
  self:provide_service_port(market_page_service_cls.Port.LeftArea, {
    show_buttons = pack(self, M.show_buttons),
    enter_sell = pack(self, M.enter_sell),
    leave_sell = pack(self, M.leave_sell),
    refresh = pack(self, M.refresh),
    refresh_sell_bar = pack(self, M.refresh_sell_bar)
  })
end

function M:on_enable()
  base.on_enable(self)
  self._state_group_sale:SetState(SaleState.NonSale)
end

function M:on_destroy()
  self._host = nil
  base.on_destroy(self)
end

function M:show_buttons(is_active)
  UIUtil.set_active(self._trans_button_panel, is_active)
  self._state_group_sale:SetState(SaleState.NonSale)
end

function M:enter_sell(payload, complete)
  if self._host == nil or type(self._host.show_bag) ~= "function" then
    if complete ~= nil then
      complete(false)
    end
    return
  end
  UIUtil.set_active(self._trans_button_panel, false)
  self._host.show_bag(payload, complete)
  self:refresh_sell_bar()
  self._state_group_sale:SetState(SaleState.Sale)
end

function M:leave_sell()
  if self._host ~= nil and type(self._host.hide_bag) == "function" then
    self._host.hide_bag()
  end
end

function M:refresh(snapshot)
end

function M:refresh_sell_bar(view_data)
  local select_count = view_data and view_data.select_count or 0
  if select_count <= 0 then
    if self._sell_panel == nil then
      UIUtil.set_active(self._trans_sell_panel, false)
    else
      self._sell_panel:set_active(false, true)
    end
    return
  end
  if self._sell_panel == nil then
    self._sell_panel = self:add_panel("UI/GeLianMarket/Panel/GeLianMarketSellPanel", self._trans_sell_panel, {
      sell_host = self:get_extra_data().sell_host
    })
  end
  self._sell_panel:render_sell_bar(view_data)
  self._sell_panel:set_active(true, true)
end

function M:_on_friend_price_clicked()
  UIManagerInstance:open("UI/GeLianMarket/GeLianMarketSocialPage")
end

function M:_on_leave_message_clicked()
  if self._page_service ~= nil then
    self._page_service:enter_leave_message()
  end
end

return M
