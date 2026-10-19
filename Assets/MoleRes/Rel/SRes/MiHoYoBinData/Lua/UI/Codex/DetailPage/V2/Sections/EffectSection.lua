local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("EffectSection", base_path)

function M:should_show(item_data)
  return item_data.Type == CodexDataType.Food
end

function M:refresh(item_data)
  if is_null(self._txt_describe) then
    return
  end
  if not_null(self._txt_effect) then
    UIUtil.set_text(self._txt_effect, UIUtil.get_text_by_id("Codex_FoodEffect") or "")
  end
  local strategy = codex_module:get_type_view_strategy(item_data.Type)
  local unlock_state = strategy:get_food_unlock_state(item_data)
  local FUS = strategy.FoodUnlockState
  local show_effect = unlock_state >= FUS.PartialUnlocked
  if show_effect then
    local power = item_data.ItemCfg.powerrecovery or 0
    if 0 < power then
      UIUtil.set_text(self._txt_describe, string.format(UIUtil.get_text_by_id("Cook_FoodEffect1"), math.floor(power)))
    else
      UIUtil.set_text(self._txt_describe, item_data.ItemCfg.itemdescribe or "")
    end
  else
    UIUtil.set_text(self._txt_describe, codex_module.default_lock_info)
  end
  local sg = self._ui_state_group_lock or self._state_group_lock
  if not_null(sg) then
    sg:SetState(show_effect and 1 or 0)
  end
end

return M
