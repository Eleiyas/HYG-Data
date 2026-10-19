local M = G.Class("CurioEmporiumEntranceSeasonBpRewardItem", G.UIBase)
local base = G.UIBase
local quality_state = {grey = 0}
local empty_state = {normal = 0, empty = 1}
local item_type = {
  normal = 0,
  recipe = 1,
  appearance_card = 3
}

function M:on_create()
  base.on_create(self)
  self._item_id = 0
  if not is_null(self._btn) then
    self:bind_callback(self._btn, pack(self, M._on_btn_click))
  end
  if not is_null(self._trans_tracking_item) then
    UIUtil.set_active(self._trans_tracking_item, false)
  end
  if not is_null(self._txt_soldout) then
    UIUtil.set_active(self._txt_soldout, false)
  end
  if not is_null(self._btn_collection) then
    UIUtil.set_active(self._btn_collection, false)
  end
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(false)
    self._tog_select.interactable = false
  end
  if not is_null(self._trans_disable) then
    UIUtil.set_active(self._trans_disable, false)
  end
  if not is_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
  if not is_null(self._ui_state_group_style) then
    self._ui_state_group_style:SetState(0)
  end
end

function M:refresh(item_id, load_proxy)
  self._item_id = item_id or 0
  local is_valid = self._item_id > 0
  if not is_null(self._ui_state_group_state_empty) then
    self._ui_state_group_state_empty:SetState(is_valid and empty_state.normal or empty_state.empty)
  end
  if not is_valid then
    UIUtil.set_text(self._txt_label, "")
    return
  end
  item_module:set_item_icon(self._img_icon, self._item_id, nil, nil, load_proxy)
  UIUtil.set_text(self._txt_label, item_module:get_item_name_by_id(self._item_id) or "")
  self:_refresh_quality(self._item_id)
  self:_refresh_item_type(self._item_id)
end

function M:_on_btn_click()
  if self._item_id <= 0 then
    return
  end
  item_module:open_item_info_dialog(self._item_id)
end

function M:_refresh_quality(item_id)
  if is_null(self._ui_state_group_state_quilty) then
    return
  end
  local item_cfg = item_module:get_cfg_by_id(item_id)
  self._ui_state_group_state_quilty:SetState(item_cfg and item_cfg.rank or quality_state.grey)
end

function M:_refresh_item_type(item_id)
  if is_null(self._ui_state_group_state_item) then
    return
  end
  local state = item_type.normal
  if item_module:item_is_recipe(item_id) then
    state = item_type.recipe
  elseif item_module:is_unlock_appearance_card(item_id) then
    state = item_type.appearance_card
  end
  self._ui_state_group_state_item:SetState(state)
end

return M
