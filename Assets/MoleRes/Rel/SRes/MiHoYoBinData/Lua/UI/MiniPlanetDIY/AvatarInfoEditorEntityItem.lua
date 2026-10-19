local M = G.Class("AvatarInfoEditorEntityItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._is_pointer_down = false
  self._runtime_flags = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  local binder = self.binder
  if binder == nil then
    return
  end
  binder:BindViewCallback(self.trans, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  binder:BindViewCallback(self.trans, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  binder:BindViewCallback(self.trans, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  binder:BindViewCallback(self.trans, EventTriggerType.Drag, pack(self, M._on_drag))
  binder:BindViewCallback(self.trans, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
  binder:BindViewCallback(self.trans, EventTriggerType.Scroll, pack(self, M._on_scroll))
end

function M:refresh_view()
  self:set_active(self._extra_data ~= nil)
  if not self._extra_data then
    return
  end
  local item_type = self._extra_data.item_type or avatar_info_editor_module.entity_item_type.decoration
  if not is_null(self._state_group) then
    self._state_group:SetState(item_type == avatar_info_editor_module.entity_item_type.action and 1 or 0)
  end
  self:refresh_placement_limit_state()
  if item_type == avatar_info_editor_module.entity_item_type.action then
    return
  end
  local config_id = self._extra_data.config_id or 0
  if config_id <= 0 then
    return
  end
  item_module:set_item_icon(self._icon, config_id, nil, nil, self:get_load_proxy())
  if not is_null(self._txt_num) then
    UIUtil.set_text(self._txt_num, "")
    UIUtil.set_active(self._txt_num.gameObject, false)
  end
end

function M:refresh_placement_limit_state()
  local config_id = 0
  if self:_is_decoration_item() then
    config_id = self._extra_data.config_id or 0
  end
  local max_count = 0
  if 0 < config_id and not is_null(self.holder) then
    max_count = self.holder:get_placement_max_count(config_id)
  end
  local has_limit = 0 < max_count
  if not is_null(self._state_group_limit) then
    self._state_group_limit:SetState(has_limit and 1 or 0)
  end
  if not has_limit then
    if not is_null(self._state_group_disable) then
      self._state_group_disable:SetState(0)
    end
    return
  end
  local remain_count = self.holder:get_placement_remain_count(config_id)
  if not is_null(self._txt_limit_num) then
    UIUtil.set_text(self._txt_limit_num, tostring(remain_count))
  end
  if not is_null(self._state_group_disable) then
    self._state_group_disable:SetState(remain_count <= 0 and 1 or 0)
  end
end

function M:_on_pointer_down(evt)
  if evt.button ~= 0 then
    return
  end
  self._is_pointer_down = true
  self._runtime_flags.dragged = false
  self._runtime_flags.created = false
end

function M:_on_begin_drag(evt)
  if evt.button ~= 0 then
    return
  end
  if not self:_is_decoration_item() then
    return
  end
  self._runtime_flags.dragged = true
  self.holder:on_entity_item_begin_drag(evt)
end

function M:_on_drag(evt)
  if evt.button ~= 0 then
    return
  end
  if not self:_is_decoration_item() then
    return
  end
  if self._runtime_flags.created == true then
    return
  end
  self.holder:on_entity_item_drag(evt)
  local check_area = self.holder:get_check_drag_area_trans()
  if not RectTransformUtility.RectangleContainsScreenPoint(check_area, evt.position, UIManagerInstance.ui_camera) then
    self._runtime_flags.created = true
    self.holder:set_pending_pointer_screen_pos(evt.position)
    self.holder:on_entity_item_try_create_decoration(self._extra_data, true)
    self.holder:on_entity_item_end_drag(evt)
    return
  end
end

function M:_on_pointer_up(evt)
  if evt.button ~= 0 then
    return
  end
  self._is_pointer_down = false
  if not self:_is_decoration_item() then
    return
  end
  if self._runtime_flags.created == true then
    self._runtime_flags.dragged = false
    self._runtime_flags.created = false
    return
  end
  if self._runtime_flags.dragged ~= true then
    self.holder:set_pending_pointer_screen_pos(evt.position)
    self.holder:on_entity_item_try_create_decoration(self._extra_data, false)
  end
  self._runtime_flags.dragged = false
  self._runtime_flags.created = false
end

function M:_on_end_drag(evt)
  if evt.button ~= 0 then
    return
  end
  if not self:_is_decoration_item() then
    return
  end
  self.holder:on_entity_item_end_drag(evt)
  self._runtime_flags.dragged = false
end

function M:_on_scroll(evt)
  self.holder:on_entity_item_scroll(evt)
end

function M:_is_decoration_item()
  if not self._extra_data then
    return false
  end
  local item_type = self._extra_data.item_type or avatar_info_editor_module.entity_item_type.decoration
  return item_type == avatar_info_editor_module.entity_item_type.decoration
end

return M
