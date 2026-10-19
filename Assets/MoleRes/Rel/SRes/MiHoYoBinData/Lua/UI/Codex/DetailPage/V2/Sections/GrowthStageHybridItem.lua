local lock_state = {unlocked = 1, locked = 0}
local M = G.Class("GrowthStageHybridItem", G.UIPanel)

function M:refresh(data)
  local discovered = data.first_time > 0
  if not_null(self._ui_state_group_lock) then
    self._ui_state_group_lock:SetState(discovered and lock_state.unlocked or lock_state.locked)
  end
  if not_null(self._txt_hybridization) then
    UIUtil.set_text_by_id(self._txt_hybridization, "Codex_HybridObtain")
  end
end

return M
