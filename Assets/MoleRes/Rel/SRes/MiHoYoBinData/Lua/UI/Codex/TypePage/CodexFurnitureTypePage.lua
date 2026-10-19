local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexFurnitureTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypeFurniturePage"
end

return M
