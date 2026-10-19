local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexClothTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypeClothingPage"
end

return M
