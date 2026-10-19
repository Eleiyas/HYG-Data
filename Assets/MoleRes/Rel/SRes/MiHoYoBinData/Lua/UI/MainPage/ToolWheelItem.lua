local M = G.Class("ToolWheelItem", G.UIBase)
local base = G.UIBase
local ToolState = {
  Normal = 0,
  Select = 1,
  Lack = 2,
  Empty = 3,
  Hold = 4
}

function M:init()
  base.init(self)
  self.index = nil
  self.data = nil
  self.is_lock = false
  self.drag_origin_pos = nil
end

function M:on_create()
  base.on_create(self)
  self:_cache_components()
  self:_bind_interactions()
end

function M:_cache_components()
  self.ui_state_transition = UIUtil.find_cmpt(self.trans, nil, typeof(UITransitionGroup))
  self.button = UIUtil.find_cmpt(self.trans, nil, typeof(ButtonEx))
  self.img_bg = UIUtil.find_image(self.trans, "img_bg")
  self.img_empty = UIUtil.find_gameobject(self.trans, "img_empty")
  self.obj_equip = UIUtil.find_gameobject(self.trans, "obj_equip")
  self.img_icon = UIUtil.find_image(self.trans, "draggable/img_icon")
  self.draggable_ui = UIUtil.find_cmpt(self.trans, "draggable", typeof(DraggableUI))
  self.drop_target = UIUtil.find_cmpt(self.trans, "slot", typeof(DropTarget))
  self.red_dot = UIUtil.find_gameobject(self.trans, "RedDot")
  self.tutorial_marker = UIUtil.find_cmpt(self.trans, "", typeof(MonoTutorialUIElementMarker))
  self.txt_tool_name = UIUtil.find_text(self.trans, "txt_toolName") or UIUtil.find_text(self.trans, "draggable/txt_toolName")
end

function M:_bind_interactions()
  local binder = self.holder.binder
  self.holder:bind_callback(self.button, pack(self, M._on_button_click))
  binder:BindViewCallback(self.trans, EventTriggerType.PointerEnter, pack(self, M._on_pointer_enter))
  binder:BindViewCallback(self.trans, EventTriggerType.PointerExit, pack(self, M._on_pointer_exit))
  if not is_null(self.draggable_ui) then
    binder:AddClickCallback(self.draggable_ui, pack(self, M._on_draggable_click))
    binder:AddBeginDragCallback(self.draggable_ui, pack(self, M._on_begin_drag))
    binder:AddEndDragCallback(self.draggable_ui, pack(self, M._on_end_drag))
  end
  binder:BindViewCallback(self.drop_target, pack(self, M._on_drop))
end

function M:set_data(index, data, is_lock, display_equip_index, is_quick_farming, is_key_mouse)
  self.index = index
  self.data = data
  self.is_lock = is_lock
  local is_empty = is_null(data) or data.ConfigId == 0
  local is_bare_slot = not is_null(data) and data.BareSlot
  self:_set_can_drag(not is_empty or is_bare_slot, is_bare_slot, is_key_mouse)
  if is_empty and not is_bare_slot then
    self.ui_state_transition:SetState(ToolState.Empty)
    self.ui_state_transition:ResetState()
    UIUtil.set_active(self.red_dot, false)
    return
  end
  self:_refresh_tutorial(is_quick_farming)
  self:_refresh_state(display_equip_index)
  self:_refresh_durable()
  self:_refresh_content()
end

function M:_set_can_drag(has_tool, is_bare_slot, is_key_mouse)
  if is_null(self.draggable_ui) then
    return
  end
  local can_drag = has_tool and (not is_bare_slot or not not is_key_mouse)
  self.draggable_ui:SetCanDrag(can_drag)
end

function M:_refresh_tutorial(is_quick_farming)
  if is_quick_farming or is_null(self.tutorial_marker) then
    return
  end
  local dynamic_key = tutorial_module:check_tutorial_dynamic_key(GraphDynamicUIKeyType.ToolWheel, self.data.ConfigId)
  if dynamic_key and dynamic_key ~= 0 then
    self.tutorial_marker:ActiveDynamicTutorialKey(dynamic_key)
  else
    self.tutorial_marker:DeactiveDynamicTutorialKey()
  end
end

function M:_refresh_state(display_equip_index)
  if display_equip_index == self.index then
    self.ui_state_transition:SetState(ToolState.Hold)
  else
    self.ui_state_transition:SetState(ToolState.Normal)
  end
  self.ui_state_transition:ResetState()
end

function M:_refresh_durable()
  local color_a = 1
  if self.data.ItemGuid > 0 then
    local item_data = back_bag_module:get_item_by_make_id(self.data.ItemGuid)
    if self.is_lock or is_null(item_data) then
      color_a = 0.2
    end
  end
  self.img_icon:SetColorA(color_a)
end

function M:_refresh_content()
  local icon_path = "UISprite/Load/Common/system_10"
  local name
  if not self.data.BareSlot then
    local cfg = item_module:get_cfg_by_id(self.data.ConfigId)
    if not is_null(cfg) then
      name = cfg.name
      local tool_cfg = item_module:get_tool_and_perform_item_cfg_by_id(self.data.ConfigId)
      icon_path = not_null(tool_cfg) and tool_cfg.defaulticon or cfg.icon
    end
  end
  if self.data.BareSlot then
    UIUtil.set_text_by_id(self.txt_tool_name, "Tool_List_Empty_Handed")
  else
    UIUtil.set_text(self.txt_tool_name, name)
  end
  UIUtil.set_image(self.img_icon, icon_path, self:get_load_proxy())
  UIUtil.set_active(self.red_dot, item_module:is_tool(self.data.ConfigId) and not self.is_lock and not red_point_module:is_recorded_with_id(red_point_module.red_point_type.new_tool, self.data.ConfigId))
end

function M:_on_button_click()
  self:_notify("on_click")
end

function M:_on_draggable_click(event_data)
  self:_notify("on_click", event_data)
end

function M:_on_pointer_enter(event_data)
  self:_notify("on_pointer_enter", event_data)
end

function M:_on_pointer_exit(event_data)
  self:_notify("on_pointer_exit", event_data)
end

function M:_on_begin_drag(event_data)
  self.drag_origin_pos = self.draggable_ui.transform.anchoredPosition
  self.trans:SetAsLastSibling()
  self.draggable_ui.transform:SetAsLastSibling()
  self:_notify("on_begin_drag", event_data)
end

function M:_on_drop(event_data)
  self:_notify("on_drop", event_data)
end

function M:_on_end_drag(event_data)
  self:_restore_drag_visual()
  self:_notify("on_end_drag", event_data)
end

function M:_notify(callback_name, event_data)
  local callback = self._extra_data and self._extra_data[callback_name]
  if callback then
    callback(self, event_data)
  end
end

function M:_restore_drag_visual()
  if not is_null(self.drop_target) then
    self.drop_target.transform:SetAsLastSibling()
  end
  if not is_null(self.draggable_ui) then
    self.draggable_ui.transform.anchoredPosition = self.drag_origin_pos or Vector2.zero
  end
end

function M:set_selected(selected)
  self.button:SetSelect(selected)
end

function M:reset_transition_state()
  self.ui_state_transition:ResetState()
end

function M:set_drop_target_active(active)
  if not is_null(self.drop_target) then
    UIUtil.set_active(self.drop_target, active)
  end
end

function M:cancel_drag()
  if not is_null(self.draggable_ui) then
    self.draggable_ui:CancelDrag()
  end
  self:_restore_drag_visual()
end

return M
