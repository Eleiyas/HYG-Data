local M = G.Class("GeLianFoodMarketCropStateItem", G.UIBase)
local base = G.UIBase
local ExpiredState = {Expired = 0, NotExpired = 1}
local SECONDS_PER_DAY = 86400

function M:render(view_data)
  if view_data == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local expire_time = view_data.expire_time or 0
  local now = TimeUtil.ServerUtcTimeSeconds
  local is_expired = expire_time <= 0 or expire_time <= now
  self._state_group_expired:SetState(is_expired and ExpiredState.Expired or ExpiredState.NotExpired)
  if is_expired then
    local ratio = gelian_market_module.sell_adapter.get_ordinary_discount_basis_points()
    local ratio_text = string.format("%d%%", ratio)
    UIUtil.set_text_by_id(self._txt_info, "Market_CropUp_ExpiredInfo", ratio_text)
    return
  end
  local remain_days = math.ceil((expire_time - now) / SECONDS_PER_DAY)
  UIUtil.set_text_by_id(self._txt_state, "Market_CropUp_RemainingDays", remain_days)
  UIUtil.set_text_by_id(self._txt_info, "Market_CropUp_UnExpiredInfo")
end

return M
