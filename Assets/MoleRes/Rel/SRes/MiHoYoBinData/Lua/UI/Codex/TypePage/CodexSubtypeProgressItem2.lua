local M = G.Class("CodexSubtypeProgressItem2", "UI/Codex/TypePage/CodexSubtypeProgressItemBase")
local base = G.CodexSubtypeProgressItemBase

function M:on_create()
  base.on_create(self)
  if self._progress_bar_panel then
    self._progress_bar_panel:set_even_distribution(true)
  end
end

return M
