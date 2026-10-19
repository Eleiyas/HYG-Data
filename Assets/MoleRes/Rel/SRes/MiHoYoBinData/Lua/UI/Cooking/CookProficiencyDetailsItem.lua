local M = G.Class("CookProficiencyDetailsItem", G.UIPanel)
local base = G.UIPanel
local unlock_state = {locked = 0, unlocked = 1}

function M:init()
  base.init(self)
  self._cfg = nil
  self._cook_lv = 0
end

function M:refresh(cfg, current_lv)
  if is_null(cfg) then
    return
  end
  self._cfg = cfg
  self._cook_lv = cfg.cooklv or 0
  current_lv = current_lv or 1
  UIUtil.set_text(self._txt_lv_name, cfg.proficiencyname or "")
  UIUtil.set_text(self._txt_info, cfg.unlockdesc or "")
  if not is_null(self._state_group_lv) then
    local lv = self._cook_lv
    if lv < 1 then
      lv = 1
    end
    self._state_group_lv:SetState(lv - 1)
  end
  if not is_null(self._state_group) then
    if current_lv >= self._cook_lv then
      self._state_group:SetState(unlock_state.unlocked)
    else
      self._state_group:SetState(unlock_state.locked)
    end
  end
end

return M
