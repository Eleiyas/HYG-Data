local M = G.Class("CurioEmporiumItemDetailsItem", G.UIBase)
local base = G.UIBase
local quality_state = {
  Grey = 0,
  Green = 1,
  Purple = 2,
  Gold = 3
}
local item_type = {
  Normal = 0,
  Recipe = 1,
  Cookbook = 2,
  AppearanceCard = 3
}
local slot_state = {Normal = 0, Empty = 1}

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_click))
  end
end

function M:refresh(cfg, on_selected, load_proxy)
  self._cfg = cfg
  self._on_selected = on_selected
  local item_id = cfg and cfg.itemid or 0
  self:_refresh_icon(item_id, load_proxy)
  self:_refresh_label(item_id)
  self:_refresh_quality(item_id)
  self:_refresh_item_type(item_id)
  self:_refresh_slot_state()
end

function M:_refresh_icon(item_id, load_proxy)
  if is_null(self._img_icon) then
    return
  end
  item_module:set_item_icon(self._img_icon, item_id, nil, nil, load_proxy)
end

function M:_refresh_label(item_id)
  if is_null(self._txt_label) then
    return
  end
  UIUtil.set_text(self._txt_label, item_module:get_item_name_by_id(item_id) or "")
end

function M:_refresh_quality(item_id)
  if is_null(self._ui_state_group_state_quilty) then
    return
  end
  if not item_id or item_id <= 0 then
    self._ui_state_group_state_quilty:SetState(quality_state.Grey)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._ui_state_group_state_quilty:SetState(quality_state.Grey)
    return
  end
  self._ui_state_group_state_quilty:SetState(cfg.rank or 0)
end

function M:_refresh_item_type(item_id)
  if is_null(self._ui_state_group_state_item) then
    return
  end
  if not item_id or item_id <= 0 then
    self._ui_state_group_state_item:SetState(item_type.Normal)
    return
  end
  if item_module:item_is_recipe(item_id) then
    self._ui_state_group_state_item:SetState(item_type.Recipe)
  elseif item_module:is_unlock_appearance_card(item_id) then
    self._ui_state_group_state_item:SetState(item_type.AppearanceCard)
  else
    self._ui_state_group_state_item:SetState(item_type.Normal)
  end
end

function M:_refresh_slot_state()
  if is_null(self._ui_state_group_state_empty) then
    return
  end
  self._ui_state_group_state_empty:SetState(slot_state.Normal)
end

function M:set_empty()
  self._cfg = nil
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(false)
  end
  if not is_null(self._ui_state_group_state_empty) then
    self._ui_state_group_state_empty:SetState(slot_state.Empty)
  end
end

function M:_on_click(is_on)
  if not is_on then
    return
  end
  if self._on_selected and self._cfg then
    self._on_selected(self._cfg, self)
  end
end

function M:set_select(select)
  if not is_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(select)
  end
end

return M
