local M = G.Class("AccompanyingSettlementTips", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Accompanying/AccompanyingSettlementTips"
  self.config.type = EUIType.Info
  self.config.handle_input = true
end

function M:on_enable()
  base.on_enable(self)
  local bonus_num = self._extra_data.bonus_num
  self:_refresh_view(bonus_num)
end

function M:_refresh_view(bonus_num)
  UIUtil.set_text(self._txt_num, string.format("+%d", bonus_num))
  self:_arm_close_timer(AccompanyingConst.settlement_close_duration)
end

function M:_arm_close_timer(close_duration)
  if not close_duration then
    return
  end
  CoolDownManagerIns:unregister(self)
  CoolDownManagerIns:register(self, close_duration, function()
    self:close_self()
  end)
end

return M
