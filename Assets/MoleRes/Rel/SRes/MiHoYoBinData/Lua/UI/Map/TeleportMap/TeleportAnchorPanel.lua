local M = G.Class("TeleportAnchorPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._renderer = nil
  self._guid = 0
  self._config_id = 0
  self._is_unlock = false
  self._is_selected = false
end

function M:refresh(renderer)
  if renderer == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._renderer = renderer
  self._guid = renderer.EntityGuid
  self._config_id = renderer.ConfigId
  self._is_unlock = renderer:IsUnlock()
  self:_update_position()
  self:refresh_state()
end

function M:is_in_screen()
  if is_null(self._renderer) then
    return false
  end
  local root_canvas = CsUIUtil.uiCanvas
  if is_null(root_canvas) then
    return false
  end
  local camera = root_canvas.worldCamera
  if is_null(camera) then
    return false
  end
  local vp = camera:WorldToViewportPoint(self.trans.position)
  return vp.z > 0 and 0 <= vp.x and vp.x <= 1 and 0 <= vp.y and 1 >= vp.y
end

function M:active_tutorial_key()
  if not is_null(self._tutorial_marker) then
    self._tutorial_marker:ActiveDynamicTutorialKey(TutorialUIKey.Season_TeleportAnchorPoint)
  end
end

function M:deactive_tutorial_key()
  if not is_null(self._tutorial_marker) then
    self._tutorial_marker:DeactiveDynamicTutorialKey()
  end
end

function M:get_btn()
  return self._btn
end

function M:refresh_state()
  if self._is_unlock then
    if self._is_selected then
      self._state_group:SetState(1)
    else
      self._state_group:SetState(0)
    end
  else
    self._state_group:SetState(2)
  end
end

function M:flip_selected()
  self._is_selected = not self._is_selected
  self:refresh_state()
  self.holder:on_anchor_selected_change(self)
end

function M:set_selected(selected)
  if self._is_selected == selected then
    return
  end
  self._is_selected = selected
  self:refresh_state()
  self.holder:on_anchor_selected_change(self)
end

function M:is_selected()
  return self._is_selected
end

function M:get_guid()
  return self._guid
end

function M:get_config_id()
  return self._config_id
end

function M:is_unlock()
  return self._is_unlock
end

function M:get_handle()
  return self._renderer.Handle
end

function M:get_name()
  return self._renderer.TeleportName or ""
end

function M:get_description()
  return self._renderer.TeleportDescription or ""
end

function M:late_update(delta_time)
  base.late_update(self, delta_time)
  self:_update_position()
end

function M:_update_position()
  if not self._renderer or not self.trans then
    return
  end
  local pos_x = self._renderer:GetScreenPositionX()
  local pos_y = self._renderer:GetScreenPositionY()
  self.trans:SetLocalPosition(pos_x, pos_y, 0)
end

return M
