local M = G.Class("FortuneWheelPanel", G.UIPanel)
local base = G.UIPanel
local num_count = 6
local angle_per_num = 60
local arrow_base_angle = 180

function M:init()
  base.init(self)
  self._wheel_items = {}
  self._cur_number = 1
  self._on_number_changed = nil
  self._is_dragging = false
  self._drag_start_angle = 0
  self._drag_start_rotation = 0
  self._drag_enabled = true
  self._is_animating = false
  self._anim_start_rotation = 0
  self._anim_diff = 0
  self._anim_duration = 0
  self._anim_elapsed = 0
  self._anim_target_rotation = 0
end

function M:on_create()
  base.on_create(self)
  self:_cache_center()
  self:_init_wheel_items()
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_selection()
end

function M:on_disable()
  base.on_disable(self)
  self._is_animating = false
end

function M:set_number_changed_callback(callback)
  self._on_number_changed = callback
end

function M:set_number(number, anim)
  if anim == nil then
    anim = false
  end
  number = math.max(1, math.min(num_count, number))
  if self._cur_number ~= number then
    self._cur_number = number
    self:_apply_rotation(anim)
    self:_refresh_selection()
    self:_notify_changed()
  end
end

function M:get_number()
  return self._cur_number
end

function M:set_drag_enabled(enabled)
  self._drag_enabled = enabled
end

function M:set_arrow_default()
  self._trans_arrow_1:SetLocalEulerAnglesZ(arrow_base_angle)
  self._trans_arrow_2:SetLocalEulerAnglesZ(arrow_base_angle)
  self._trans_arrow_3:SetLocalEulerAnglesZ(arrow_base_angle)
end

function M:set_arrow_to_num(nums)
  local wheel_rotation = self:_get_current_rotation()
  local arrows = {
    self._trans_arrow_1,
    self._trans_arrow_2,
    self._trans_arrow_3
  }
  for i = 1, 3 do
    local num = nums[i]
    if num then
      local arrow_z = arrow_base_angle - (num - 1) * angle_per_num + wheel_rotation
      UIUtil.set_active(arrows[i], true)
      arrows[i]:SetLocalEulerAnglesZ(arrow_z)
    else
      UIUtil.set_active(arrows[i], false)
    end
  end
end

function M:_init_wheel_items()
  for i = 1, num_count do
    local field_name = "_trans_wheel_item_" .. i
    local trans = self[field_name]
    local item = self:add_panel("UI/FortuneWheel/FortuneWheelChoose/FortuneWheelItem", trans)
    item:set_index(i)
    self._wheel_items[i] = item
    self:bind_callback(item:get_btn(), function()
      self:_on_number_btn_click(item:get_index())
    end)
  end
end

function M:_add_ui_listener()
  self.binder:BindViewCallback(self._trans_rotate, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  self.binder:BindViewCallback(self._trans_rotate, EventTriggerType.Drag, pack(self, M._on_drag))
  self.binder:BindViewCallback(self._trans_rotate, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
end

function M:_on_begin_drag(event_data)
  if not self._drag_enabled then
    return
  end
  self._is_dragging = true
  self._drag_start_angle = self:_get_pointer_angle(event_data)
  self._drag_start_rotation = self:_get_current_rotation()
end

function M:_on_drag(event_data)
  if not self._is_dragging then
    return
  end
  local cur_angle = self:_get_pointer_angle(event_data)
  local delta = cur_angle - self._drag_start_angle
  local wheel_rotation = self._drag_start_rotation + delta
  self:_set_rotation(wheel_rotation)
  self:_update_nearest_selection(wheel_rotation)
end

function M:_on_end_drag(event_data)
  if not self._is_dragging then
    return
  end
  self._is_dragging = false
  self:_snap_to_nearest()
end

function M:_cache_center()
  local corners = CsUIUtil.GetWorldCorners(self._trans_rotate)
  local world_center = (corners[0] + corners[2]) * 0.5
  local screen_pos = CsUIUtil.WorldToScreenPoint(UIManagerInstance.ui_camera, world_center)
  self._center_x = screen_pos.x
  self._center_y = screen_pos.y
end

function M:_get_pointer_angle(event_data)
  local pos = event_data.position
  local dx = pos.x - self._center_x
  local dy = pos.y - self._center_y
  return math.deg(math.atan(dy, dx))
end

function M:_get_current_rotation()
  return self._trans_rotate.localEulerAngles.z
end

function M:_set_rotation(wheel_rotation)
  self._trans_rotate:SetLocalEulerAnglesZ(wheel_rotation)
end

function M:_calc_nearest_number(wheel_rotation)
  wheel_rotation = wheel_rotation % 360
  if wheel_rotation < 0 then
    wheel_rotation = wheel_rotation + 360
  end
  local nearest = math.floor((wheel_rotation + angle_per_num / 2) / angle_per_num) % num_count + 1
  if nearest > num_count then
    nearest = 1
  end
  return nearest
end

function M:_update_nearest_selection(wheel_rotation)
  local nearest = self:_calc_nearest_number(wheel_rotation)
  if nearest ~= self._cur_number then
    self._cur_number = nearest
    self:_refresh_selection()
    self:_notify_changed()
  end
end

function M:_snap_to_nearest()
  local wheel_rotation = self:_get_current_rotation()
  self._cur_number = self:_calc_nearest_number(wheel_rotation)
  self:_apply_rotation(true)
  self:_refresh_selection()
  self:_notify_changed()
end

function M:_apply_rotation(animate)
  local target_rotation = (self._cur_number - 1) * angle_per_num
  if animate then
    self:_animate_to(target_rotation)
  else
    self:_set_rotation(target_rotation)
  end
end

function M:_animate_to(target_rotation)
  local start_rotation = self:_get_current_rotation()
  local diff = (target_rotation - start_rotation) % 360
  if 180 < diff then
    diff = diff - 360
  end
  if math.abs(diff) < 0.1 then
    self:_set_rotation(target_rotation)
    return
  end
  local speed = fortune_wheel_module.wheel_rotate_speed
  self._anim_start_rotation = start_rotation
  self._anim_diff = diff
  self._anim_duration = math.abs(diff) / speed
  self._anim_elapsed = 0
  self._anim_target_rotation = target_rotation
  self._is_animating = true
end

function M:update(dt)
  if not self._is_animating then
    return
  end
  self._anim_elapsed = self._anim_elapsed + dt
  local t = math.min(self._anim_elapsed / self._anim_duration, 1)
  local wheel_rotation = self._anim_start_rotation + self._anim_diff * t
  self:_set_rotation(wheel_rotation)
  if 1 <= t then
    self:_set_rotation(self._anim_target_rotation)
    self._is_animating = false
  end
end

function M:_refresh_selection()
  for i = 1, num_count do
    local item = self._wheel_items[i]
    if item then
      item:set_selected(i == self._cur_number)
    end
  end
end

function M:force_set_selection(num)
  for i = 1, num_count do
    local item = self._wheel_items[i]
    if item then
      item:set_selected(i == num)
    end
  end
end

function M:_notify_changed()
  if self._on_number_changed then
    self._on_number_changed(self._cur_number)
  end
end

function M:_on_number_btn_click(num)
  if not self._drag_enabled then
    return
  end
  self:set_number(num, true)
end

return M
