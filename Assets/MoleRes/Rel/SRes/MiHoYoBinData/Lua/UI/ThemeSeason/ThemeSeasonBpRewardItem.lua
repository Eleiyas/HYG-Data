local base_cls = require("UI/Item/ItemV2Panel")
local M = G.Class("ThemeSeasonBpRewardItem", base_cls)
local base = base_cls

function M:init()
  base.init(self)
  self._trans_countdown = nil
end

function M:set_countdown_active(is_active)
  UIUtil.set_active(self._trans_countdown, is_active == true)
end

return M
