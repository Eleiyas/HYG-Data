local M = G.Class("MenuWheelItem", G.UIBase)
local base = G.UIBase
require("UI/MainPage/MenuWheelCfg")
local transition_group_state = {
  Normal = 0,
  HighLighted = 1,
  Disabled = 4
}

function M:init()
  base.init(self)
  self.index = nil
  self.entry = nil
end

function M.create(template, parent, holder, callbacks)
  local go = GameObject.Instantiate(template, parent)
  UIUtil.set_active(go, true)
  return holder:add_panel("UI/MainPage/MenuWheelItem", go.transform, callbacks)
end

function M:set_slot(index, count)
  local angle = (index + menu_wheel_module.INDEX_START_OFFSET - 1) * 360 / count
  self.trans:SetLocalEulerAnglesZ(-angle)
  if not is_null(self._trans_content) then
    self._trans_content:SetLocalEulerAnglesZ(angle)
  end
  if not is_null(self._trans_bg) then
    self._trans_bg:SetLocalEulerAnglesZ(-angle)
  end
end

function M:set_data(index, entry, is_selected, icon_path, redpoint_func)
  self.index = index
  self.entry = entry
  self:_refresh_red_point(redpoint_func)
  if entry.is_placeholder then
    self:_do_state_transition(transition_group_state.Disabled)
    self._btn_cell_wheel.interactable = false
    self._img_icon:SetColorA(0)
    return
  end
  self:set_selected(is_selected)
  if string.is_valid(icon_path) then
    UIUtil.set_image(self._img_icon, icon_path, self:get_load_proxy())
  end
  self._btn_cell_wheel.interactable = true
  self._img_icon:SetColorA(1)
end

function M:_refresh_red_point(redpoint_func)
  if is_null(self._red_dot_container) then
    return
  end
  if redpoint_func == nil then
    self._red_dot_container:ShowRedPoint(RedPointType.None)
    return
  end
  redpoint_func(self._red_dot_container)
end

function M:_do_state_transition(state)
  if is_null(self._ui_state_transition_cell_wheel) then
    return
  end
  self._ui_state_transition_cell_wheel:DoStateTransition(state)
end

function M:set_selected(is_selected)
  self:_do_state_transition(is_selected and transition_group_state.HighLighted or transition_group_state.Normal)
end

return M
