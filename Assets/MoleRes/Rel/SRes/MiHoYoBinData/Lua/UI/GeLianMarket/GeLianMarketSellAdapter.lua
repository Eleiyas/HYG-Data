local M = G.Class("GeLianMarketSellAdapter")
local up_helper = require("UI/GeLianMarket/GeLianMarketUpHelper")
local ORDINARY_DISCOUNT_CFG_ID = 11
local BASIS_POINTS = 100

function M.get_ordinary_discount_basis_points()
  local cfg = ExcelDataUtil.get_value(typeof(BCropTradingNumCfg), ORDINARY_DISCOUNT_CFG_ID)
  if is_null(cfg) then
    return 0
  end
  return math.max(0, math.min(BASIS_POINTS, cfg.value or 0))
end

function M.calc_ordinary_discounted_price(config_id, matched_tag, is_self)
  local server_multiplier = is_self and CsGeLianMarketModuleUtil.GetSelfServerPriceMultiplierDataByTag(matched_tag) or CsGeLianMarketModuleUtil.GetServerPriceMultiplierDataByTag(matched_tag)
  local discount = M.get_ordinary_discount_basis_points()
  if discount <= 0 then
    return CsGeLianMarketModuleUtil.CalculatePriceByMultiplier(config_id, server_multiplier)
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), config_id)
  if is_null(item_cfg) then
    return 0
  end
  local base_price = item_cfg.price or 0
  if base_price <= 0 then
    return 0
  end
  local raw = base_price * server_multiplier * (BASIS_POINTS - discount)
  local price = math.floor((raw + 9999) / 10000)
  local price_range_cfg = ExcelDataUtil.get_value(typeof(BCropPriceRangeCfg), config_id)
  if not is_null(price_range_cfg) then
    price = math.min(math.max(price_range_cfg.pricemin or 0, price), price_range_cfg.pricemax or 0)
  end
  return price
end

function M.apply_ordinary_discount(price, server_data)
  if up_helper.is_seasonal_up(server_data) then
    return price or 0
  end
  local discount = M.get_ordinary_discount_basis_points()
  local p = price or 0
  local ratio = BASIS_POINTS - discount
  return math.floor((p * ratio + 99) / BASIS_POINTS)
end

function M._get_server_multiplier(server_data)
  if is_null(server_data) then
    return nil
  end
  local config_id = server_data.ConfigId or server_data.ConFigID or 0
  if config_id <= 0 then
    return nil
  end
  local tags = list_to_table(CsGeLianMarketModuleUtil.GetSellingTagsByConfigIds({config_id})) or {}
  local tag = tags[1]
  if not string.is_valid(tag) then
    return nil
  end
  return CsGeLianMarketModuleUtil.GetServerPriceMultiplierDataByTag(tag), config_id
end

function M.calc_display_trend_value(trend_value, server_data)
  if trend_value == nil then
    return nil
  end
  local disc = M.get_ordinary_discount_basis_points()
  if up_helper.is_seasonal_up(server_data) or disc <= 0 then
    return trend_value
  end
  local server_multiplier, config_id = M._get_server_multiplier(server_data)
  if server_multiplier == nil then
    return trend_value
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), config_id)
  local price_range_cfg = ExcelDataUtil.get_value(typeof(BCropPriceRangeCfg), config_id)
  if is_null(item_cfg) or is_null(price_range_cfg) then
    return trend_value
  end
  local base_price = item_cfg.price or 0
  local raw = base_price * server_multiplier * (BASIS_POINTS - disc)
  local price = math.floor((raw + 9999) / 10000)
  price = math.min(math.max(price_range_cfg.pricemin or 0, price), price_range_cfg.pricemax or 0)
  if price <= 0 then
    return trend_value
  end
  local ratio = price / base_price * BASIS_POINTS
  if base_price < price then
    return math.max(101, math.ceil(ratio))
  elseif base_price > price then
    return math.min(99, math.floor(ratio))
  end
  return BASIS_POINTS
end

function M.copy_quote(cs_quote)
  if is_null(cs_quote) then
    return nil
  end
  return {
    is_sellable = cs_quote.IsSellable == true,
    matched_tag = cs_quote.MatchedTag,
    final_price = cs_quote.FinalPrice or 0,
    tag_limit_remaining = cs_quote.TagLimitRemaining or 0,
    total_limit_remaining = cs_quote.TotalLimitRemaining or 0,
    trend_state = cs_quote.TrendState or 2
  }
end

function M.get_item_quote_by_config_id(config_id, is_self, quote_cache)
  if not config_id or config_id <= 0 then
    return nil
  end
  if quote_cache ~= nil then
    local cached_quote = quote_cache[config_id]
    if cached_quote ~= nil then
      return cached_quote or nil
    end
  end
  local quote = M.copy_quote(CsGeLianMarketModuleUtil.GetItemMarketQuote(config_id, is_self))
  if quote_cache ~= nil then
    quote_cache[config_id] = quote or false
  end
  return quote
end

function M.get_item_quote(server_data, is_self, quote_cache)
  if is_null(server_data) then
    return nil
  end
  local config_id = server_data.ConfigId or server_data.ConFigID or 0
  local quote = M.get_item_quote_by_config_id(config_id, is_self, quote_cache)
  if quote == nil then
    return nil
  end
  local final_price = quote.final_price
  if not up_helper.is_seasonal_up(server_data) and string.is_valid(quote.matched_tag) then
    final_price = M.calc_ordinary_discounted_price(config_id, quote.matched_tag, is_self)
  end
  return {
    is_sellable = quote.is_sellable,
    matched_tag = quote.matched_tag,
    final_price = final_price,
    tag_limit_remaining = quote.tag_limit_remaining,
    total_limit_remaining = quote.total_limit_remaining,
    trend_state = quote.trend_state
  }
end

function M.is_item_sellable(server_data, is_self, quote_cache)
  local quote = M.get_item_quote(server_data, is_self, quote_cache)
  return quote ~= nil and quote.is_sellable
end

function M.get_selected_item_total_price(select_items, is_self, quote_cache)
  local total_price = 0
  for _, item_data in pairs(select_items or {}) do
    local quote = M.get_item_quote(item_data.server_data, is_self, quote_cache)
    if quote ~= nil and quote.is_sellable then
      total_price = total_price + quote.final_price * item_data.num
    end
  end
  return math.modf(total_price)
end

return M
