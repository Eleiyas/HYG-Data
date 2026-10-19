local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexPlantTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypePlantsPage"
end

return M
