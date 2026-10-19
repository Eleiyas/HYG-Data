local base = require("UI/Codex/TypePage/CodexTypePage")
local M = G.Class("CodexFoodTypePage", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexSubtypeCookPage"
end

function M:_init_page()
  local result = base._init_page(self)
  if self._bg_item and not_null(self._bg_item._trans_tab_content_mobile) then
    UIUtil.set_active(self._bg_item._trans_tab_content_mobile, false)
  end
  return result
end

return M
