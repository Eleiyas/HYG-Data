local M = G.Class("PlayerControlInputElementBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.ctrl_mode_item_type = nil
  self.ui_ctrl_mode_active = false
  self.btn_type = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  local ctrl_mode_type_comp = UIUtil.find_cmpt(self.trans, nil, typeof(CtrlModeUIType))
  if ctrl_mode_type_comp then
    self.ctrl_mode_item_type = ctrl_mode_type_comp.type
  end
  self.canvas_group = UIUtil.find_cmpt(self.trans, nil, typeof(CanvasGroup))
  if InputManagerIns:is_touch() == false then
    self.high_light_display = UIUtil.find_cmpt(self.trans, nil, typeof(HighLightDisplay))
  else
    self._ui_state = UIUtil.find_cmpt(self.trans, nil, typeof(UITransitionGroup))
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
end

function M:refresh()
  if self.ui_ctrl_mode_active and self.is_active then
    self:inner_refresh()
  end
end

function M:inner_refresh()
end

function M:refresh_active()
  self.ui_ctrl_mode_active = player_controller_module:is_ctrl_ui_item_active(self.ctrl_mode_item_type)
  if self.is_active ~= self.ui_ctrl_mode_active then
    self:set_active(self.ui_ctrl_mode_active)
  end
  self.current_state = nil
end

function M:show()
  if InputManagerIns:is_touch() then
    if self._ui_state then
      self._ui_state:SetState(0)
    end
  else
    if self.canvas_group then
      self.canvas_group.alpha = 1
    end
    if self.is_active then
      UIUtil.set_active(self.game_obj, true)
    end
  end
end

function M:hide()
  if InputManagerIns:is_touch() == false and self.is_active then
    UIUtil.set_active(self.game_obj, false)
  end
end

function M:disable()
  if InputManagerIns:is_touch() then
    if self._ui_state then
      self._ui_state:SetState(1)
    end
  elseif self.canvas_group then
    self.canvas_group.alpha = 0.5
  end
end

function M:set_linked_btn_type(btn_type)
  self.btn_type = btn_type
end

function M:update_shortcut_pressed_state(common_btns)
  if InputManagerIns:is_touch() == false and self.high_light_display and self.btn_type then
    self.high_light_display:SetHighLightState(common_btns & self.btn_type == self.btn_type)
  end
end

function M:set_statues(state)
  if state == nil or not self.is_active then
    return
  end
  if self.current_state == state then
    return
  end
  if state == PlayerControlButtonState.Disabled then
    self:disable()
  elseif state == PlayerControlButtonState.Enabled then
    self:show()
  elseif state == PlayerControlButtonState.Hidden then
    if InputManagerIns:is_touch() then
      self:disable()
    else
      self:hide()
    end
  end
  self.current_state = state
end

function M:set_icon(sprite)
  if InputManagerIns:is_touch() then
    if self._icon then
      if string.is_valid(sprite) then
        UIUtil.set_active(self._icon, true)
        UIUtil.set_image(self._icon, sprite, self:get_load_proxy())
      else
        UIUtil.set_active(self._icon, false)
      end
    end
  elseif self._icon and sprite then
    UIUtil.set_active(self._icon, true)
    UIUtil.set_image(self._icon, sprite, self:get_load_proxy())
  end
end

return M
