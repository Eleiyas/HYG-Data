local M = G.Class("OutsideClickHandler")

function M:__ctor()
  self._enabled = true
  self._callback = nil
  self._should_listen = nil
  self._protected_transforms = nil
  self._protected_provider = nil
  self._arm_frame = 0
  self._pending_frame = 0
  self._release_suppress_frame = 0
  self._is_suppressing = false
end

function M:set_callback(callback)
  self._callback = callback
end

function M:set_enabled(is_enabled)
  self._enabled = is_enabled ~= false
  if self._enabled == false then
    self:reset()
  end
end

function M:set_should_listen(provider)
  self._should_listen = provider
end

function M:set_protected_transforms(protected_transforms)
  if protected_transforms == nil then
    self._protected_transforms = nil
    return
  end
  self._protected_transforms = {}
  for _, protected_transform in pairs(protected_transforms) do
    M.append_protected_transform(self._protected_transforms, protected_transform)
  end
end

function M:add_protected_transform(protected_transform)
  if is_null(protected_transform) then
    return
  end
  if self._protected_transforms == nil then
    local defaults = self:_resolve_protected_transforms()
    self._protected_transforms = {}
    for _, target in ipairs(defaults) do
      table.insert(self._protected_transforms, target)
    end
  end
  table.insert(self._protected_transforms, protected_transform)
end

function M:reset_protected_transforms()
  self._protected_transforms = nil
end

function M:set_protected_provider(provider)
  self._protected_provider = provider
end

function M:arm()
  self._arm_frame = Time.frameCount + 1
end

function M:reset()
  self._pending_frame = 0
  self._release_suppress_frame = 0
  self._is_suppressing = false
end

function M:tick()
  if self._enabled == false then
    return
  end
  self:_handle_pending()
  self:_refresh_suppress()
  if self._should_listen and not self._should_listen() then
    return
  end
  if Time.frameCount <= self._arm_frame then
    return
  end
  if self._pending_frame > 0 then
    return
  end
  local screen_position = M.get_pointer_down_position()
  if screen_position == nil then
    return
  end
  if self:is_position_in_protected_area(screen_position) then
    self._is_suppressing = false
    return
  end
  self._is_suppressing = true
  self._pending_frame = Time.frameCount
end

function M:is_pending()
  return self._pending_frame > 0
end

function M:is_in_release_suppress()
  return Time.frameCount <= self._release_suppress_frame
end

function M:is_suppressing()
  return self._is_suppressing == true
end

function M:should_ignore_interact()
  return self:is_pending() or self:is_in_release_suppress()
end

function M:is_position_in_protected_area(screen_position)
  local protected_transforms = self:_resolve_protected_transforms()
  for _, protected_trans in ipairs(protected_transforms) do
    if M.is_screen_position_in_target(screen_position, protected_trans) then
      return true
    end
  end
  return false
end

function M:_resolve_protected_transforms()
  if self._protected_transforms ~= nil then
    return self._protected_transforms
  end
  if self._protected_provider then
    return self._protected_provider() or {}
  end
  return {}
end

function M:_handle_pending()
  if self._pending_frame <= 0 then
    return
  end
  if M.is_pointer_pressed() then
    return
  end
  if self._enabled == false or self._should_listen and not self._should_listen() then
    self:reset()
    return
  end
  self._pending_frame = 0
  self._release_suppress_frame = Time.frameCount + 1
  if self._callback then
    self._callback()
  end
end

function M:_refresh_suppress()
  if self._pending_frame > 0 then
    return
  end
  if Time.frameCount <= self._release_suppress_frame then
    return
  end
  if not M.is_pointer_pressed() then
    self._is_suppressing = false
  end
end

function M.append_protected_transform(protected_transforms, protected_transform)
  if protected_transforms == nil or is_null(protected_transform) then
    return
  end
  table.insert(protected_transforms, protected_transform)
end

function M.to_screen_point(position)
  if position == nil then
    return nil
  end
  return Vector2(position.x, position.y)
end

function M.get_pointer_down_position()
  if Input.GetMouseButtonDown(0) then
    return M.to_screen_point(Input.mousePosition)
  end
  if 0 < Input.touchCount then
    local touch = Input.GetTouch(0)
    if touch.phase == TouchPhase.Began then
      return M.to_screen_point(touch.position)
    end
  end
  return nil
end

function M.get_current_pointer_position()
  if Input.touchCount > 0 then
    local touch = Input.GetTouch(0)
    return M.to_screen_point(touch.position)
  end
  return M.to_screen_point(Input.mousePosition)
end

function M.is_pointer_pressed()
  return Input.GetMouseButton(0) or 0 < Input.touchCount
end

function M.get_target_transform(target)
  if is_null(target) then
    return nil
  end
  local ok, target_trans = pcall(function()
    return target.transform
  end)
  if ok and not_null(target_trans) then
    return target_trans
  end
  return target
end

function M.is_target_active(target)
  local target_trans = M.get_target_transform(target)
  return not_null(target_trans) and not_null(target_trans.gameObject) and target_trans.gameObject.activeInHierarchy
end

function M.get_rect_transform(target)
  local target_trans = M.get_target_transform(target)
  if is_null(target_trans) or is_null(target_trans.gameObject) or not target_trans.gameObject.activeInHierarchy then
    return nil
  end
  local rect_trans = target_trans:GetComponent(typeof(RectTransform))
  if not_null(rect_trans) then
    return rect_trans
  end
  return UIUtil.find_rect_trans(target_trans)
end

function M.is_screen_position_in_target(screen_position, target)
  local rect_trans = M.get_rect_transform(target)
  if is_null(rect_trans) then
    return false
  end
  local camera = UIManagerInstance and UIManagerInstance.ui_camera or nil
  local canvas = rect_trans:GetComponentInParent(typeof(Canvas))
  if not_null(canvas) and not_null(canvas.worldCamera) then
    camera = canvas.worldCamera
  end
  return RectTransformUtility.RectangleContainsScreenPoint(rect_trans, screen_position, camera)
end

return M
