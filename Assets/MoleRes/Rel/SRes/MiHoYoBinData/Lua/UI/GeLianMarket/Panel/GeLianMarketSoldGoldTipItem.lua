local M = G.Class("GeLianMarketSoldGoldTipItem", G.UIBase)
local base = G.UIBase
local PROFIT_THRESHOLD_CFG_ID = 12

function M.get_profit_threshold()
  local cfg = ExcelDataUtil.get_value(typeof(BCropTradingNumCfg), PROFIT_THRESHOLD_CFG_ID)
  if is_null(cfg) then
    return 0
  end
  return cfg.value or 0
end

function M.get_current_sold_gold()
  local sold_gold_map = dic_to_table(CsGeLianMarketModuleUtil.GetAllCropTagSoldGold()) or {}
  local total = 0
  for _, gold in pairs(sold_gold_map) do
    total = total + (gold or 0)
  end
  return total
end

function M:render(data)
  local threshold = data and data.threshold or 0
  local current_gold = data and data.current_gold or 0
  local is_show = 0 < threshold
  if not is_show then
    self:set_active(false)
    return
  end
  UIUtil.set_text_by_id(self._txt_tip, "Market_ProfitThreshold_Tip", threshold)
  UIUtil.set_text_by_id(self._txt_count, "Market_ProfitThreshold_Count", current_gold, threshold)
end

return M
