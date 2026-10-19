local M = G.Class("GeLianMarketUpHelper")
M.GroupKey = {
  SeasonalUp = "seasonal_up",
  Ordinary = "ordinary"
}

function M.get_current_period_id()
  return CsGeLianMarketModuleUtil.CurrentPeriodId or 0
end

function M.get_up_info(server_data)
  if is_null(server_data) then
    return false, 0, 0
  end
  local raw_item = server_data
  if not is_null(server_data.firstItem) then
    raw_item = server_data.firstItem
  end
  local ext = raw_item.CropMarketUpExtension
  if is_null(ext) then
    return false, 0, 0
  end
  local period_id = ext.PeriodId or 0
  local expire_time = ext.ExpireTime or 0
  local current = M.get_current_period_id()
  local is_up = 0 < current and period_id == current
  return is_up, period_id, expire_time
end

function M.is_seasonal_up(server_data)
  local is_up = M.get_up_info(server_data)
  return is_up
end

function M.group_items(items)
  local up_items = {}
  local ordinary_items = {}
  for i = 1, #(items or {}) do
    local item = items[i]
    if item ~= nil and M.is_seasonal_up(item.server_data) then
      up_items[#up_items + 1] = item
    else
      ordinary_items[#ordinary_items + 1] = item
    end
  end
  local groups = {}
  if 0 < #up_items then
    groups[#groups + 1] = {
      key = M.GroupKey.SeasonalUp,
      items = up_items
    }
  end
  if 0 < #ordinary_items then
    groups[#groups + 1] = {
      key = M.GroupKey.Ordinary,
      items = ordinary_items
    }
  end
  return groups
end

return M
