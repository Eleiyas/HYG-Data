local M = G.Class("TeleportMapPanel", G.UIPanel)
local base = G.UIPanel
local anchor_class_name = "UI/Map/TeleportMap/TeleportAnchorPanel"
local other_player_name_prefab_path = "UI/Map/OtherPlayerIconPanel"
local other_player_name_class_name = "UI/Map/OtherPlayerIconPanel"
local task_tracking_prefab_path = "UI/Map/TaskTrackIconPanel"
local task_tracking_class_name = "UI/Map/TaskTrackIconPanel"

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._anchor_panels = {}
  self._handle_to_task_tracking_icon_panel = {}
  self._selected_anchor = nil
  UIUtil.set_active(self._trans_anchor_point, false)
end

function M:on_enable()
  base.on_enable(self)
  EventCenter.Broadcast(EventID.OnMapPageOpened)
  self._slider_zoom.minValue = 0
  self._slider_zoom.maxValue = 1
  self._slider_zoom.value = 0
  self._target_zoom = 0
  self._zoom_sen = CsAssetConfigManagerUtil.MainMapConfig.ZoomSpeed
  self._zoom_att = CsAssetConfigManagerUtil.MainMapConfig.ZoomAtt
  self._pinch_zoom_sensitivity = CsAssetConfigManagerUtil.MainMapConfig.ZoomSpeedPinch
  self._initial_yaw = CsAssetConfigManagerUtil.MainMapConfig.CamInitialYaw
  UIUtil.set_active(self._trans_btn_group, false)
end

function M:bind_callbacks()
  self:bind_callback(self._slider_zoom, pack(self, M._on_slider_zoom_value_changed))
  self:bind_callback(self._btn_reset, pack(self, M._reset_cam_axis))
  self:bind_callback(self._btn_add_zoom, function()
    self:_on_btn_add_zoom_clicked(true)
  end)
  self:bind_callback(self._btn_minus_zoom, function()
    self:_on_btn_add_zoom_clicked(false)
  end)
  self.binder:BindViewCallback(self._trans_minimodel_select_area, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  self.binder:BindViewCallback(self._trans_minimodel_select_area, EventTriggerType.Drag, pack(self, M._on_drag))
  self.binder:BindViewCallback(self._trans_minimodel_select_area, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  self:bind_callback(self._btn_teleport, pack(self, M._on_btn_teleport_click))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.MouseScroll, M._camera_zoom)
  self:bind_input_and_fun(ActionType.Act.Horizontal, M._look_target_horizontal_movement, ActionType.EType.InProgress)
  self:bind_input_and_fun(ActionType.Act.Vertical, M._look_target_vertical_movement, ActionType.EType.InProgress)
end

function M:_on_btn_teleport_click()
  if self._selected_anchor == nil then
    return
  end
  CsMap3DManagerUtil.DoTeleport(self._selected_anchor:get_handle(), function(success)
    if success then
      CsCoroutineManagerUtil.Invoke(0.3, function()
        self.holder:close_self()
      end)
    end
  end)
end

function M:_register_anchor(renderer)
  local handle = renderer.Handle
  if self._anchor_panels[handle.Value] then
    return
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_anchor_point, self._trans_anchor_root)
  local panel = self:add_panel(anchor_class_name, go.transform)
  self:bind_callback(panel:get_btn(), function()
    if not panel:is_unlock() then
      UIUtil.show_tips_by_text_id("SeasonStory_Transform_Unactive")
      return
    end
    self:_on_anchor_click(panel)
  end)
  panel:refresh(renderer)
  self._anchor_panels[handle.Value] = panel
  if self._extra_data and self._extra_data.select_guid > 0 and panel:get_guid() == self._extra_data.select_guid then
    panel:set_selected(true)
  end
  self:_refresh_anchor_tutorial_key()
end

function M:_unregister_anchor(handle)
  local panel = self._anchor_panels[handle.Value]
  if panel then
    panel:deactive_tutorial_key()
    self._anchor_panels[handle.Value] = nil
    if self._selected_anchor == panel then
      panel:set_selected(false)
    else
      self:_refresh_anchor_tutorial_key()
    end
    if not_null(panel.trans) then
      UIUtil.destroy_go(panel.trans.gameObject)
      self:remove_panel(panel)
    end
  end
end

function M:_reset_anchors()
  for _, panel in pairs(self._anchor_panels) do
    if panel and not_null(panel.trans) then
      panel:set_selected(false)
    end
  end
end

function M:_on_anchor_click(anchor_panel)
  for _, panel in pairs(self._anchor_panels) do
    if panel:get_guid() ~= anchor_panel:get_guid() then
      panel:set_selected(false)
    end
  end
  anchor_panel:flip_selected()
end

function M:set_anchor_selected_by_guid(guid)
  for _, panel in pairs(self._anchor_panels) do
    if panel:get_guid() == guid then
      panel:set_selected(true)
      break
    end
  end
end

function M:_refresh_anchor_tutorial_key()
  local target = self._selected_anchor
  if target == nil then
    for _, panel in pairs(self._anchor_panels) do
      if panel:is_in_screen() and (target == nil or panel:get_guid() < target:get_guid()) then
        target = panel
      end
    end
  end
  for _, panel in pairs(self._anchor_panels) do
    if panel == target then
      panel:active_tutorial_key()
    else
      panel:deactive_tutorial_key()
    end
  end
end

function M:on_anchor_selected_change(anchor_panel)
  if anchor_panel == nil then
    return
  end
  local is_selected = anchor_panel:is_selected()
  UIUtil.set_active(self._trans_btn_group, is_selected)
  if is_selected then
    self._selected_anchor = anchor_panel
    UIUtil.set_active(self._trans_btn_group, true)
    CsMap3DManagerUtil.SelectIcon(anchor_panel:get_handle())
    UIUtil.set_text(self._txt_anchor_name, anchor_panel:get_name())
    UIUtil.set_text(self._txt_anchor_info, anchor_panel:get_description())
  else
    self._selected_anchor = nil
    if anchor_panel:get_handle() == CsMap3DManagerUtil.SelectedIconHandle then
      CsMap3DManagerUtil.UnselectCurrentIcon()
    end
  end
  self:_refresh_anchor_tutorial_key()
end

function M:_select_renderer()
  local renderer = CsMap3DManagerUtil.GetFirstRendererUnderMouse()
  if renderer then
    CsMap3DManagerUtil.ToggleMapIcon(renderer.Handle, renderer)
  end
end

function M:register_other_player_name(renderer)
  local handle = renderer.Handle
  if self._handle_to_player_name_panel and self._handle_to_player_name_panel[handle.Value] then
    return
  end
  if not self._handle_to_player_name_panel then
    self._handle_to_player_name_panel = {}
  end
  self.holder:load_prefab_async(other_player_name_prefab_path, function(obj)
    if not self.is_active then
      if obj then
        UIUtil.destroy_go(obj)
      end
      return
    end
    if not self._handle_to_player_name_panel or self._handle_to_player_name_panel[handle.Value] ~= nil then
      if obj then
        UIUtil.destroy_go(obj)
      end
      return
    end
    local panel = self:add_panel(other_player_name_class_name, obj, {
      renderer = renderer,
      trans_hot_zone = self._trans_map_2d_name_hot_zone
    })
    self._handle_to_player_name_panel[handle.Value] = panel
    panel:set_active(true)
  end, self._trans_map_2d_name_root, true)
end

function M:unregister_other_player_name(handle)
  if not self._handle_to_player_name_panel then
    return
  end
  local panel = self._handle_to_player_name_panel[handle.Value]
  if panel then
    if not_null(panel.trans) then
      UIUtil.destroy_go(panel.trans.gameObject)
      self:remove_panel(panel)
    end
    self._handle_to_player_name_panel[handle.Value] = nil
  end
end

function M:register_task_tracking_icon(renderer, is_exact)
  local handle = renderer.Handle
  if self._handle_to_task_tracking_icon_panel and self._handle_to_task_tracking_icon_panel[handle.Value] then
    return
  end
  if not self._handle_to_task_tracking_icon_panel then
    self._handle_to_task_tracking_icon_panel = {}
  end
  self.holder:load_prefab_async(task_tracking_prefab_path, function(obj)
    if not self.is_active then
      if obj then
        UIUtil.destroy_go(obj)
      end
      return
    end
    if not self._handle_to_task_tracking_icon_panel or self._handle_to_task_tracking_icon_panel[handle.Value] ~= nil then
      if obj then
        UIUtil.destroy_go(obj)
      end
      return
    end
    local panel = self:add_panel(task_tracking_class_name, obj, {renderer = renderer, is_exact = is_exact})
    self._handle_to_task_tracking_icon_panel[handle.Value] = panel
    panel:set_active(true)
  end, self._trans_map_icon_2d_root, true)
end

function M:unregister_task_tracking_icon(handle)
  if not self._handle_to_task_tracking_icon_panel then
    return
  end
  local panel = self._handle_to_task_tracking_icon_panel[handle.Value]
  if panel then
    if not_null(panel.trans) then
      UIUtil.destroy_go(panel.trans.gameObject)
      self:remove_panel(panel)
    end
    self._handle_to_task_tracking_icon_panel[handle.Value] = nil
  end
end

function M:_camera_zoom(action)
  local wheel_delta = InputManagerIns:get_axis(ActionType.Act.MouseScroll)
  if wheel_delta == 0 then
    return
  end
  self:_set_target_zoom(self._slider_zoom.value + (0 < wheel_delta and self._zoom_sen or -self._zoom_sen))
end

function M:_on_btn_add_zoom_clicked(is_add)
  self:_set_target_zoom(self._slider_zoom.value + (is_add and self._zoom_sen or -self._zoom_sen))
end

function M:_set_target_zoom(target_zoom)
  self._target_zoom = math.max(self._slider_zoom.minValue, math.min(target_zoom, self._slider_zoom.maxValue))
  self._is_lerping = true
end

function M:_on_slider_zoom_value_changed(value)
  CsMap3DManagerUtil.Zoom(value)
  if self._handle_to_task_tracking_icon_panel then
    for _, panel in pairs(self._handle_to_task_tracking_icon_panel) do
      if panel then
        panel:update_range_size_with_zoom(value)
      end
    end
  end
end

function M:_reset_cam_axis()
  CsMap3DManagerUtil.ResetCamera()
end

function M:_look_target_movement(action, axis)
  local move = InputManagerIns:get_axis(axis)
  if move ~= 0 then
    CsMap3DManagerUtil.MoveLookTarget(move, axis == ActionType.Act.Horizontal)
  end
end

function M:_look_target_horizontal_movement(action)
  self:_look_target_movement(action, ActionType.Act.Horizontal)
end

function M:_look_target_vertical_movement(action)
  self:_look_target_movement(action, ActionType.Act.Vertical)
end

function M:_on_pointer_down(evt)
  if evt.button == 0 and not self._is_pinching then
    self._is_dragging = false
    CsMap3DManagerUtil.RecordMouseWorldPos()
  end
end

function M:_on_drag(evt)
  if evt.button == 0 and not self._is_pinching then
    self._is_dragging = true
    CsMap3DManagerUtil.MoveLookTargetDuringDrag()
  end
end

function M:_on_pointer_up(evt)
  if evt.button == 0 and not self._is_pinching then
    if not self._is_dragging then
      self:_select_renderer()
    end
    self._is_dragging = false
  end
end

function M:_handle_pinch_zoom()
  if Input.touchCount == 2 then
    local touch0 = Input.GetTouch(0)
    local touch1 = Input.GetTouch(1)
    if touch0.phase == TouchPhase.Began or touch1.phase == TouchPhase.Began then
      self._prev_pinch_dist = Vector2.Distance(touch0.position, touch1.position)
      self._is_pinching = true
    elseif self._is_pinching and (touch0.phase == TouchPhase.Moved or touch1.phase == TouchPhase.Moved) then
      if touch0.fingerId == -1 or touch1.fingerId == -1 then
        self._is_pinching = false
        return
      end
      local current_pinch_dist = Vector2.Distance(touch0.position, touch1.position)
      if self._prev_pinch_dist == 0 then
        self._prev_pinch_dist = current_pinch_dist
        return
      end
      local delta_dist = current_pinch_dist - self._prev_pinch_dist
      local zoom_amount = delta_dist * self._pinch_zoom_sensitivity
      if math.abs(zoom_amount) > 1.0E-5 then
        self:_set_target_zoom(self._slider_zoom.value + zoom_amount)
      end
      self._prev_pinch_dist = current_pinch_dist
    elseif touch0.phase == TouchPhase.Ended or touch1.phase == TouchPhase.Ended then
      self._is_pinching = false
    end
  else
    self._is_pinching = false
  end
end

function M:update(delta_time)
  base.update(self, delta_time)
  self:_handle_pinch_zoom()
  if self._is_lerping then
    local zoom_diff = math.abs(self._target_zoom - self._slider_zoom.value)
    if zoom_diff < 0.01 then
      self._slider_zoom.value = self._target_zoom
      self._is_lerping = false
    else
      self._slider_zoom.value = self._slider_zoom.value + (self._target_zoom - self._slider_zoom.value) * self._zoom_att
    end
  end
end

function M:on_disable()
  self:set_extra_data(nil)
  self:_reset_anchors()
  if self._handle_to_player_name_panel then
    for _, panel in pairs(self._handle_to_player_name_panel) do
      if panel and not_null(panel.trans) then
        UIUtil.destroy_go(panel.trans.gameObject)
        self:remove_panel(panel)
      end
    end
    self._handle_to_player_name_panel = nil
  end
  if self._handle_to_task_tracking_icon_panel then
    for _, panel in pairs(self._handle_to_task_tracking_icon_panel) do
      if panel and not_null(panel.trans) then
        UIUtil.destroy_go(panel.trans.gameObject)
        self:remove_panel(panel)
      end
    end
    self._handle_to_task_tracking_icon_panel = {}
  end
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaRegisterTeleportIcon, function(renderer)
    self:_register_anchor(renderer)
  end)
  self:add_evt_listener(EventID.LuaUnRegisterTeleportIcon, function(handle)
    self:_unregister_anchor(handle)
  end)
  self:add_evt_listener(EventID.LuaRegisterOtherPlayerName, function(renderer)
    self:register_other_player_name(renderer)
  end)
  self:add_evt_listener(EventID.LuaUnRegisterOtherPlayerName, function(handle)
    self:unregister_other_player_name(handle)
  end)
  self:add_evt_listener(EventID.LuaRegisterBlurryTrackingIcon, function(renderer)
    self:register_task_tracking_icon(renderer, false)
  end)
  self:add_evt_listener(EventID.LuaUnRegisterBlurryTrackingIcon, function(handle)
    self:unregister_task_tracking_icon(handle)
  end)
  self:add_evt_listener(EventID.LuaRegisterExactTrackingIcon, function(renderer)
    self:register_task_tracking_icon(renderer, true)
  end)
  self:add_evt_listener(EventID.LuaUnRegisterExactTrackingIcon, function(handle)
    self:unregister_task_tracking_icon(handle)
  end)
  self:add_evt_listener(EventID.Tutorial.OnTutorialStart, function()
    self:_refresh_anchor_tutorial_key()
  end)
end

return M
