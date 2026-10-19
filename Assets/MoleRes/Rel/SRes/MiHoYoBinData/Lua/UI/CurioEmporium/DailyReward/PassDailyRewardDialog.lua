local M = G.Class("PassDailyRewardDialog", G.UIWindow)
local base = G.UIWindow
local monthly_pass_panel_cls = "UI/CurioEmporium/DailyReward/MonthlyPassDailyRewardPanel"
local battle_pass_panel_cls = "UI/CurioEmporium/DailyReward/BattlePassDailyRewardPanel"
local reward_state = {
  monthly_pass = 0,
  battle_pass = 1,
  both = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/PassDailyRewardDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_bg)
  self._monthly_pass_panel = self:add_panel(monthly_pass_panel_cls, self._obj_monthly_pass)
  self._battle_pass_panel = self:add_panel(battle_pass_panel_cls, self._obj_battle_pass)
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_reward_state()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:close_self()
  CsGameStoreModuleUtil.ClearDailyRewardNotify()
  base.close_self(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_reward_state()
  if not CsGameStoreModuleUtil.HasDailyRewardNotify() then
    Logger.LogWarning("[PassDailyRewardDialog] DailyRewardNotify is not cached")
    return
  end
  local notify = CsGameStoreModuleUtil.GetDailyRewardNotify()
  if not notify then
    Logger.LogWarning("[PassDailyRewardDialog] DailyRewardNotify is nil")
    return
  end
  local has_monthly_pass = not is_null(notify.VipCardReward)
  local has_battle_pass = not is_null(notify.BpReward)
  if has_monthly_pass and self._monthly_pass_panel then
    self._monthly_pass_panel:refresh(notify.VipCardReward)
  end
  if has_battle_pass and self._battle_pass_panel then
    self._battle_pass_panel:refresh(notify.BpReward)
  end
  if has_monthly_pass and has_battle_pass then
    self._ui_state_group:SetState(reward_state.both)
  elseif has_monthly_pass then
    self._ui_state_group:SetState(reward_state.monthly_pass)
  elseif has_battle_pass then
    self._ui_state_group:SetState(reward_state.battle_pass)
  else
    Logger.LogWarning("[PassDailyRewardDialog] DailyRewardNotify contains no reward data")
  end
end

return M
