local lock_state = {
  locked = 0,
  unlocked_not_owned = 1,
  unlocked_owned = 2
}
local M = G.Class("CodexSearchResultItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_content) then
    self:bind_callback(self._btn_content, pack(self, M._on_btn_click))
  end
end

function M:_on_btn_click()
  if not self._codex_data then
    return
  end
  local strategy = codex_module:get_type_view_strategy(self._codex_data.Type)
  UIManagerInstance:open(strategy:get_detail_page_class(), {
    item_id = self._codex_data.IdCfg.id,
    enter_type = codex_module.codex_page_enter_type.codex_search
  })
end

function M:refresh(data)
  self._codex_data = data.data
  local id_cfg = self._codex_data.IdCfg
  self:set_active(true)
  if not_null(self._img_icon_dynamic) then
    item_module:set_item_big_icon(self._img_icon_dynamic, 0, item_module:get_cfg_by_id(id_cfg.id), self:get_load_proxy())
  end
  local is_unlocked = self._codex_data.IsUnlocked
  local t = self._codex_data.Type
  local skip_grey = t == CodexDataType.Furniture or t == CodexDataType.Cloth
  if is_unlocked then
    if not_null(self._ui_state_group_lock) then
      self._ui_state_group_lock:SetState(lock_state.unlocked_owned)
    end
    if not_null(self._txt_name) then
      UIUtil.set_text(self._txt_name, id_cfg.name)
    end
    local rank = not_null(self._codex_data.ItemCfg) and self._codex_data.ItemCfg.rank or 0
    if not_null(self._ui_state_group_quality) then
      self._ui_state_group_quality:SetState(rank)
    end
  else
    if not_null(self._ui_state_group_lock) then
      self._ui_state_group_lock:SetState(skip_grey and lock_state.unlocked_not_owned or lock_state.locked)
    end
    if not_null(self._txt_name) then
      UIUtil.set_text(self._txt_name, skip_grey and id_cfg.name or codex_module.default_lock_info)
    end
    if not_null(self._ui_state_group_quality) then
      self._ui_state_group_quality:SetState(skip_grey and (not_null(self._codex_data.ItemCfg) and self._codex_data.ItemCfg.rank or 0) or 0)
    end
  end
end

return M
