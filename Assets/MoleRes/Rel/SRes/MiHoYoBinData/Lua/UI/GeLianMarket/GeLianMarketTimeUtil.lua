local M = {}

function M.get_rotation_left_time()
  return UIUtil.format_left_time((CsGeLianMarketModuleUtil.MarketEndTime or 0) - TimeUtil.ServerUtcTimeSeconds)
end

local PRICE_REFRESH_CFG_ID = 8
local price_refresh_hours_cache

local function get_price_refresh_hours()
  if price_refresh_hours_cache ~= nil then
    return price_refresh_hours_cache
  end
  local hours = {}
  local cfg = ExcelDataUtil.get_value(typeof(BCropTradingNumCfg), PRICE_REFRESH_CFG_ID)
  if cfg and string.is_valid(cfg.value2) then
    local time_list = lua_str_split(cfg.value2, ",")
    for i = 1, #time_list do
      local hour = tonumber(string.match(time_list[i], "(%d+):%d+:%d+"))
      if hour ~= nil then
        hours[#hours + 1] = hour
      end
    end
  end
  if #hours == 0 then
    hours = {12, 20}
  end
  table.sort(hours)
  price_refresh_hours_cache = hours
  return hours
end

function M.get_next_price_refresh_left_seconds()
  local local_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(TimeUtil.ServerUtcTimeSeconds)
  local now_seconds = local_time.Hour * 3600 + local_time.Minute * 60 + local_time.Second
  local hours = get_price_refresh_hours()
  local min_left
  for i = 1, #hours do
    local left = hours[i] * 3600 - now_seconds
    if 0 < left and (min_left == nil or min_left > left) then
      min_left = left
    end
  end
  if min_left == nil then
    min_left = hours[1] * 3600 + 86400 - now_seconds
  end
  return min_left
end

function M.get_last_price_refresh_time()
  local now = TimeUtil.ServerUtcTimeSeconds or 0
  if now <= 0 then
    return 0
  end
  local local_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(now)
  local now_seconds = local_time.Hour * 3600 + local_time.Minute * 60 + local_time.Second
  local hours = get_price_refresh_hours()
  for i = #hours, 1, -1 do
    local past_seconds = hours[i] * 3600 - now_seconds
    if past_seconds <= 0 then
      return now + past_seconds
    end
  end
  return now - now_seconds - (24 - hours[#hours]) * 3600
end

function M.get_next_price_refresh_left_time()
  return UIUtil.format_left_time(M.get_next_price_refresh_left_seconds())
end

function M.get_today_text()
  local server_local_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(TimeUtil.ServerUtcTimeSeconds)
  return TextMapFormatUtil.FormatDateYMD(server_local_time)
end

function M.get_market_period_texts()
  local start_time = CsGeLianMarketModuleUtil.MarketStartTime or 0
  local end_time = CsGeLianMarketModuleUtil.MarketEndTime or 0
  if start_time <= 0 or end_time <= 0 then
    return "", ""
  end
  return TextMapFormatUtil.FormatDateMD(TimeUtil.ChangeServerUtcTimeToServerLocalTime(start_time)), TextMapFormatUtil.FormatDateMD(TimeUtil.ChangeServerUtcTimeToServerLocalTime(end_time))
end

return M
