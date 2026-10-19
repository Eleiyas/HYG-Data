local M = G.Class("SourceItemNormal", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(source_cfg, item_id, is_season_unavailable)
  if is_season_unavailable then
    local desc = source_cfg.sourcedescription or ""
    local hint = UIUtil.get_text_by_id("Codex_Source_Season_Unavailable")
    UIUtil.set_text(self._txt, desc .. " " .. (hint or ""))
  else
    UIUtil.set_text(self._txt, source_cfg.sourcedescription)
  end
end

return M
