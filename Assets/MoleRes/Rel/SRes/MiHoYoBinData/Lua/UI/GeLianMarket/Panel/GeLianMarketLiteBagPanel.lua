local M = G.Class("GeLianMarketLiteBagPanel", "UI/LitePacketView/LiteCommonColumnsBagPanel")
local up_helper = gelian_market_module.up_helper

function M:_build_display_groups()
  local up_indices = {}
  local ordinary_indices = {}
  for i = 1, #self._lst_cur_show_data do
    local item_data = self._lst_cur_show_data[i]
    if not is_null(item_data) and (is_null(item_data.server_data) or is_null(item_data.index)) then
      self:_init_item_extra_data(item_data, i)
    end
    if not is_null(item_data) and 0 < (item_data.guid or 0) then
      if up_helper.is_seasonal_up(item_data.server_data) then
        up_indices[#up_indices + 1] = i
      else
        ordinary_indices[#ordinary_indices + 1] = i
      end
    end
  end
  local groups = {}
  if 0 < #up_indices then
    groups[#groups + 1] = {
      key = up_helper.GroupKey.SeasonalUp,
      title = UIUtil.get_text_by_id("Market_Sell_Group_Up"),
      flat_indices = up_indices
    }
  end
  if 0 < #ordinary_indices then
    groups[#groups + 1] = {
      key = up_helper.GroupKey.Ordinary,
      title = UIUtil.get_text_by_id("Market_Sell_Group_Normal"),
      flat_indices = ordinary_indices
    }
  end
  return groups
end

return M
