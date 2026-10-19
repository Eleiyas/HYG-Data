local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexCreatureTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypeBiologyPage"
end

return M
