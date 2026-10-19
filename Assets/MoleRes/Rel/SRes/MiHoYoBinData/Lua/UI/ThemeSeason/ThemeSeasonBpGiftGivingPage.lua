local M = G.Class("ThemeSeasonBpGiftGivingPage", G.UIWindow)
local base = G.UIWindow
local PREFAB_PATH = "UI/BattlePass/BattlePassSeasonGiftGivingPage"

function M:init()
  base.init(self)
  self.config.prefab_path = PREFAB_PATH
  self.config.type = EUIType.Dialog
  self._btn_close = nil
end

function M:on_enable()
  base.on_enable(self)
  local duration = theme_season_module.BP_GIFT_GIVING_PAGE_CLOSE_DELAY
  CsCoroutineManagerUtil.Invoke(duration, function()
    self:close_self()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_close_btn(self._btn_close)
end

return M
