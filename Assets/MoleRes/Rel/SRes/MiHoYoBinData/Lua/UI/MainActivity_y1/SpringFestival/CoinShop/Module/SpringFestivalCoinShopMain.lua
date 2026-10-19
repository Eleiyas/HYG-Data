spring_festival_coin_shop_module = spring_festival_coin_shop_module or {}
local M = spring_festival_coin_shop_module

function M:send_coin_shop_buy_req(goods_id, buy_num)
  goods_id = tonumber(goods_id) or 0
  buy_num = tonumber(buy_num) or 0
  if goods_id <= 0 or buy_num <= 0 then
    Logger.LogWarning("[spring_festival_coin_shop_module] send_coin_shop_buy_req invalid args")
    return
  end
  CsSpringFestivalModuleUtil.SendCoinShopGoodsBuyReq(goods_id, buy_num)
end

return M
