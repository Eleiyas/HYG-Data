local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexItemTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypeMaterialPage"
end

return M
