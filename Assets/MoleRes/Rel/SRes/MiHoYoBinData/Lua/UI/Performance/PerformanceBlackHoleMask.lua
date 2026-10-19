local M = G.Class("PerformanceBlackHoleMask", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Performance/PerformanceBlackHoleMask"
  self.config.type = EUIType.Page
  self.config.order_in_layer = 0
  self.config.input_penetrate = true
end

return M
