spring_festival_exchange_module = spring_festival_exchange_module or {}
local M = spring_festival_exchange_module

function M:send_exchange_req(count)
  count = tonumber(count) or 0
  if count <= 0 then
    Logger.LogWarning("[spring_festival_exchange_module] send_exchange_req invalid count")
    return
  end
  local max_exchangeable = self:calc_max_exchangeable()
  if max_exchangeable <= 0 then
    Logger.LogWarning("[spring_festival_exchange_module] send_exchange_req but max_exchangeable=0")
    return
  end
  if count > max_exchangeable then
    count = max_exchangeable
  end
  CsSpringFestivalModuleUtil.SendExchangeTokenReq(count)
end

return M
