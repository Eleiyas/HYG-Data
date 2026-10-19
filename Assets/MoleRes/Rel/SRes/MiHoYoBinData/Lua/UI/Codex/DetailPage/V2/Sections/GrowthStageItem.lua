local lock_state = {unlocked = 1, locked = 0}
local M = G.Class("GrowthStageItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_icon_dynamic) then
    self:bind_callback(self._btn_icon_dynamic, pack(self, M._on_btn_click))
  end
end

function M:_on_btn_click()
  if self._entity_id and self._entity_id > 0 and self._discovered then
    item_module:open_item_info_dialog(self._entity_id)
  end
end

function M:refresh(data)
  self._entity_id = data.entity_id
  local discovered = data.first_time > 0
  self._discovered = discovered
  if not_null(self._txt_stage_name) then
    if data.is_hybrid then
      UIUtil.set_text_by_id(self._txt_stage_name, "Codex_HybridObtain")
      UIUtil.set_active(self._txt_stage_name, true)
    elseif data.is_seed then
      UIUtil.set_text_by_id(self._txt_stage_name, "Codex_Seed")
      UIUtil.set_active(self._txt_stage_name, true)
    else
      UIUtil.set_active(self._txt_stage_name, false)
    end
  end
  if data.is_hybrid then
    UIUtil.set_active(self._img_stage_icon, false)
  else
    local item_cfg = item_module:get_cfg_by_id(data.entity_id)
    if not_null(item_cfg) and not_null(self._img_stage_icon) then
      UIUtil.set_image(self._img_stage_icon, item_cfg.icon, self:get_load_proxy())
    end
  end
  if not_null(self._ui_state_group_lock) then
    self._ui_state_group_lock:SetState(discovered and lock_state.unlocked or lock_state.locked)
  elseif not_null(self._img_stage_icon) then
    local c = discovered and Color(1, 1, 1, 1) or Color(0, 0, 0, 1)
    UIUtil.set_image_color(self._img_stage_icon, c)
  end
  UIUtil.set_active(self._trans_arrow, not data.is_last)
end

return M
