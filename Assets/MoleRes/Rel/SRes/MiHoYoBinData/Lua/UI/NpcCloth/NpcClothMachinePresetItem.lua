local M = G.Class("NpcClothMachinePresetItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
  self._item_cls = item_module:init_lite_item_cls(self.trans)
  self._toggle = UIUtil.find_toggle_ex(self.trans, "")
  self._obj_choose_multiple = UIUtil.find_gameobject(self.trans, "Icon_Choose_Multiple")
  self._state_group_npc = UIUtil.find_ui_state_group(self.trans, "state_group_npc")
  self._state_group_empty = UIUtil.find_ui_state_group(self.trans, "state_group_empty")
  if self._toggle then
    self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
  else
    Logger.LogError("[NpcClothMachinePresetItem] missing root ToggleEx")
  end
end

function M:refresh(item_data, context)
  self._item_data = item_data
  self._context = context or {}
  local item_id = item_data and item_data.item_id or 0
  local is_empty = item_id <= 0
  self:set_active(true)
  if self._state_group_empty then
    self._state_group_empty:SetState(is_empty and 1 or 0)
  end
  if self._toggle then
    self._toggle.interactable = not is_empty
    if self._toggle.SetIsOnWithoutNotify then
      self._toggle:SetIsOnWithoutNotify(false)
    end
  end
  if is_empty then
    UIUtil.set_active(self._obj_choose_multiple, false)
    return
  end
  local count = item_data.count or 1
  item_module:set_item_cls(self._item_cls, item_id, count, self:get_load_proxy(), nil, false)
  if self._item_cls.state_group_interactable then
    self._item_cls.state_group_interactable:SetState(1)
  end
  if self._state_group_npc then
    self._state_group_npc:SetState(1)
  end
  self:_refresh_selected_state()
end

function M:is_active_in_hierarchy()
  return self.game_obj and self.game_obj.activeInHierarchy
end

function M:refresh_selected(context)
  self._context = context or self._context or {}
  if is_null(self._item_data) or (self._item_data.item_id or 0) <= 0 then
    UIUtil.set_active(self._obj_choose_multiple, false)
    return
  end
  self:_refresh_selected_state()
end

function M:_refresh_selected_state()
  local selected_map = self._context.selected_item_key_map or {}
  UIUtil.set_active(self._obj_choose_multiple, selected_map[self._item_data.key] == true)
end

function M:_on_toggle_changed(is_on)
  if is_on == false then
    return
  end
  if self._toggle and self._toggle.SetIsOnWithoutNotify then
    self._toggle:SetIsOnWithoutNotify(false)
  end
  if self._context and self._context.on_click_item and not is_null(self._item_data) and 0 < (self._item_data.item_id or 0) then
    self._context.on_click_item(self._item_data)
  end
end

return M
