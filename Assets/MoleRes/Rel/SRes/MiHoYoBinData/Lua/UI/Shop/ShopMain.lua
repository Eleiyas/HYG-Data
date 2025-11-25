shop_module = shop_module or {}

function shop_module:get_shop_item_buy_num(data, coin)
  local cfg = item_module:get_cfg_by_id(data.ItemID)
  if data.ItemCount == 0 then
    return shop_module.shop_buy_state.good_lack_of, 0
  end
  local max_buy_num = data.ItemCount
  local amount = data.CAmount or 0
  if max_buy_num < 0 then
    max_buy_num = 99999999
  end
  local stack_num = back_bag_module:get_packet_data():GetItemStackNum(cfg.id)
  local item_num = back_bag_module:get_item_num(cfg.id, 0)
  local all_item_grid_num = math.ceil((item_num + amount) / stack_num)
  local cur_item_grid_num = math.ceil(item_num / stack_num)
  local need_grid_num = all_item_grid_num - cur_item_grid_num
  local bag_type = data.BackPackType.value__
  local max_grid_num = back_bag_module:get_packet_data():GetPacketMaxCountByPackType(bag_type)
  local cur_grid_num = back_bag_module:get_packet_data():GetPacketCurCountByPackType(bag_type)
  if max_grid_num < need_grid_num + cur_grid_num then
    need_grid_num = max_grid_num - cur_grid_num
  end
  local odd_item = 0
  if 0 < item_num then
    odd_item = item_num % cur_item_grid_num
  end
  local currency_buy_num = math.floor(coin / math.ceil(data.Price * data.Discount * 0.01))
  if currency_buy_num <= 0 then
    return shop_module.shop_buy_state.currency_lack_of, 0
  end
  local can_buy_num = need_grid_num * stack_num + (stack_num - odd_item)
  if can_buy_num <= 0 then
    return shop_module.shop_buy_state.good_lack_of, 0
  end
  can_buy_num = math.min(amount, currency_buy_num, can_buy_num, max_buy_num)
  return shop_module.shop_buy_state.buy, can_buy_num
end

function shop_module:get_entity_shop_item_buy_num(data, coin)
  if data.StockNum == 0 then
    return shop_module.shop_buy_state.good_lack_of, 0
  end
  local max_buy_num = data.StockNum
  if max_buy_num < 0 then
    max_buy_num = 99999999
  end
  local currency_buy_num = math.floor(coin / data.Price)
  if currency_buy_num <= 0 then
    return shop_module.shop_buy_state.currency_lack_of, 0
  end
  local can_buy_num = math.min(currency_buy_num, max_buy_num)
  return shop_module.shop_buy_state.buy, can_buy_num
end

function shop_module:get_select_bg_path_by_quality(quality)
  local ret_path = shop_module.shop_select_bg_path[1]
  if quality and 0 <= quality then
    quality = quality + 1
    if quality <= #shop_module.shop_select_bg_path then
      ret_path = shop_module.shop_select_bg_path[quality]
    end
  end
  return ret_path
end

function shop_module:open_entity_shop_page()
  UIManagerInstance:open("UI/Shop/EntityShopPage")
end

function shop_module:get_accumulative_lemi()
  if CsShopModuleUtil.shopData then
    return CsShopModuleUtil.shopData.accumulativeLemi
  end
end

return shop_module or {}
