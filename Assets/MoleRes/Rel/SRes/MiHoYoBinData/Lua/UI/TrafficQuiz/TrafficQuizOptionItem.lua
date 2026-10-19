local M = G.Class("TrafficQuizOptionItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:set_option(label, content_text)
  if self._txt_option_dynamic then
    UIUtil.set_text(self._txt_option_dynamic, label)
  end
  if self._txt_content_dynamic then
    UIUtil.set_text(self._txt_content_dynamic, content_text)
  end
end

function M:set_state(state)
  if self._state_group_option then
    self._state_group_option:SetState(state)
  end
end

function M:reset_toggle()
  if self._tog_option then
    self._tog_option.isOn = false
  end
end

function M:set_interactable(interactable)
  if self._tog_option then
    self._tog_option.interactable = interactable
  end
end

function M:get_toggle()
  return self._tog_option
end

return M
