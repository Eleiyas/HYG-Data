local M = G.Class("QteGameActionItem", G.UIBase)
local base = G.UIBase
local ActionItemState = {
  Pressed = 0,
  Idle = 1,
  Wrong = 2,
  Current = 3
}
local ButtonIndexToPressTrigger = {
  [1] = "press_up",
  [2] = "press_left",
  [3] = "press_down",
  [4] = "press_right"
}

function M:init()
  base.init(self)
  self._node_id = nil
end

function M:on_create()
  base.on_create(self)
  self._animator_helper = UIUtil.find_cmpt(self.trans, nil, typeof(UIAnimatorHelper))
end

function M:set_node(node_id, view_data)
  self._node_id = node_id
  if not view_data or not string.is_valid(view_data.icon) then
    return
  end
  if self._img_icon_act_Nor then
    UIUtil.set_image(self._img_icon_act_Nor, view_data.icon, self:get_load_proxy())
  end
  if self._img_icon_act_Once then
    UIUtil.set_image(self._img_icon_act_Once, view_data.icon, self:get_load_proxy())
  end
  if self._img_icon_act_dynamic then
    UIUtil.set_image(self._img_icon_act_dynamic, view_data.icon, self:get_load_proxy())
  end
end

function M:set_state(state)
  if self._state_group_current then
    self._state_group_current:SetState(state or ActionItemState.Idle)
  end
end

function M:set_idle()
  self:set_state(ActionItemState.Idle)
end

function M:set_current()
  self:set_state(ActionItemState.Current)
end

function M:set_pressed()
  self:set_state(ActionItemState.Pressed)
end

function M:set_wrong()
  self:set_state(ActionItemState.Wrong)
end

function M:play_press_direction(button_index)
  if not self._animator_helper then
    return
  end
  local trigger = ButtonIndexToPressTrigger[button_index]
  if not trigger then
    return
  end
  self._animator_helper:SetTriggerWithCallback(trigger)
end

return M
