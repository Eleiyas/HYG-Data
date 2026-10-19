local base_cls = require("UI/ThemeSeason/ThemeSeasonBpRewardPageBase")
local M = G.Class("ThemeSeasonBpRewardPage2", base_cls)
local base = base_cls

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonRewardPage2"
end

return M
