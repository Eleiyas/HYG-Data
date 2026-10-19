local M = G.Class("GeLianMarketColorUtil")
M.TREND_STATE = {
  Up = 0,
  Down = 1,
  Flat = 2,
  UpAlt = 3,
  DownAlt = 4
}
local TREND_COLOR_PREFIX = {
  [0] = "CommonPriceRed",
  [1] = "CommonPriceGreen",
  [2] = "CommonPriceDefault",
  [3] = "CommonPriceGreen",
  [4] = "CommonPriceRed"
}
local TREND_COLOR_BG = {
  Green = "GeLianFoodMarket_Green",
  Red = "GeLianFoodMarket_Red"
}
M.LIGHTNESS = {Light = 0, Dark = 1}
local _color_key_cache = {}
do
  local _suffix = {
    [M.LIGHTNESS.Light] = "Light",
    [M.LIGHTNESS.Dark] = "Dark"
  }
  for trend_state = 0, M.TREND_STATE.DownAlt do
    local prefix = TREND_COLOR_PREFIX[trend_state] or "CommonPriceDefault"
    for _, lightness in pairs(M.LIGHTNESS) do
      _color_key_cache[trend_state * 2 + lightness] = prefix .. "_" .. _suffix[lightness]
    end
  end
end

function M.get_trend_color_key(trend_state, is_dark)
  local ts = trend_state or M.TREND_STATE.Flat
  local lightness = is_dark and M.LIGHTNESS.Dark or M.LIGHTNESS.Light
  return _color_key_cache[ts * 2 + lightness]
end

function M.get_direction_bg_color_key(is_rise)
  local trend_style = CsGeLianMarketModuleUtil.GetTrendStyle() or 0
  if is_rise then
    return trend_style == 0 and TREND_COLOR_BG.Red or TREND_COLOR_BG.Green
  else
    return trend_style == 0 and TREND_COLOR_BG.Green or TREND_COLOR_BG.Red
  end
end

function M.get_direction_color_key(is_rise, is_dark)
  local trend_style = CsGeLianMarketModuleUtil.GetTrendStyle() or 0
  local trend_state
  if is_rise then
    trend_state = trend_style == 0 and M.TREND_STATE.Up or M.TREND_STATE.UpAlt
  else
    trend_state = trend_style == 0 and M.TREND_STATE.Down or M.TREND_STATE.DownAlt
  end
  return M.get_trend_color_key(trend_state, is_dark)
end

function M.get_profit_color_key(basis_points, is_dark)
  if basis_points == 0 then
    return M.get_trend_color_key(M.TREND_STATE.Flat, is_dark)
  end
  return M.get_direction_color_key(0 < basis_points, is_dark)
end

return M
