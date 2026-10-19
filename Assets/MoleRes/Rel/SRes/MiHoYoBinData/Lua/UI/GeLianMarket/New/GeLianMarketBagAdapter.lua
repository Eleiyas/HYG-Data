local M = {}

local function get_config_id(server_data)
  if is_null(server_data) then
    return 0
  end
  return server_data.ConfigId or server_data.ConFigID or 0
end

function M.get_item_quote(server_data, is_self, quote_cache)
  if is_null(server_data) then
    return nil
  end
  return M.get_item_quote_by_config_id(get_config_id(server_data), is_self, quote_cache)
end

function M.get_item_quote_by_config_id(config_id, is_self, quote_cache)
  if not config_id or config_id <= 0 then
    return nil
  end
  if quote_cache then
    local cached_quote = quote_cache[config_id]
    if cached_quote ~= nil then
      return cached_quote or nil
    end
  end
  local quote = CsGeLianMarketModuleUtil.GetItemMarketQuote(config_id, is_self)
  if quote_cache then
    quote_cache[config_id] = quote or false
  end
  return quote
end

function M.is_item_sellable(server_data, is_self, quote_cache)
  local quote = M.get_item_quote(server_data, is_self, quote_cache)
  return quote ~= nil and quote.IsSellable
end

function M.get_selected_item_total_price(select_items, is_self, quote_cache)
  local total_price = 0
  for _, item_data in pairs(select_items or {}) do
    local quote = M.get_item_quote(item_data.server_data, is_self, quote_cache)
    if quote and quote.IsSellable then
      total_price = total_price + (quote.FinalPrice or 0) * item_data.num
    end
  end
  return math.modf(total_price)
end

return M
