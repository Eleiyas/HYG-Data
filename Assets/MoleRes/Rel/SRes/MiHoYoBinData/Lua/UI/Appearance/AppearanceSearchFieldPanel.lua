local base = require("UI/CompanionStarDetail/ExchangeDiary/StarbaySearchFieldPanel")
local M = G.Class("AppearanceSearchFieldPanel", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Appearance/AppearanceSearchFieldDialog"
end

return M
