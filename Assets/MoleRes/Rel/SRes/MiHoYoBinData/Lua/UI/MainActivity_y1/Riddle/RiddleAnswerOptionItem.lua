local ANIMATOR_TRIGGERS = {
  "normal",
  "right",
  "wrong",
  "in"
}
local M = G.Class("RiddleAnswerOptionItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._animator = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self.game_obj) then
    self._animator = self.game_obj:GetComponent(typeof(CS.UnityEngine.Animator))
  end
end

function M:set_option(label, content_text)
  if self._txt_option_dynamic then
    UIUtil.set_text(self._txt_option_dynamic, label)
  end
  if self._txt_content_dynamic then
    UIUtil.set_text(self._txt_content_dynamic, content_text)
  end
end

function M:_reset_all_animator_triggers()
  if is_null(self._animator) then
    return
  end
  for _, trigger_name in ipairs(ANIMATOR_TRIGGERS) do
    self._animator:ResetTrigger(trigger_name)
  end
end

function M:set_state(state)
  self:_reset_all_animator_triggers()
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
