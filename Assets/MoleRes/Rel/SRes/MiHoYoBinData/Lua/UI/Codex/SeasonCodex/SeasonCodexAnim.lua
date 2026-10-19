local M = {}
local ANIMATOR_PARAMETER_TYPE_TRIGGER = CS.UnityEngine.AnimatorControllerParameterType.Trigger
M.giftpack = {idle = "none", claimable = "reward"}
M.item = {locked = "lock", unlocked = "unlock"}
M.reward = {idle = "normal", claimable = "reward"}
M.reward_special = {idle = "normal2", claimable = "reward2"}

function M.play(helper, group, key, on_complete)
  local target = group[key]
  if target == nil then
    return
  end
  local animator = helper:GetAnimator()
  for i = 0, animator.parameterCount - 1 do
    local parameter = animator:GetParameter(i)
    if parameter.type == ANIMATOR_PARAMETER_TYPE_TRIGGER then
      animator:ResetTrigger(parameter.nameHash)
    end
  end
  helper:SetTriggerWithCallback(target, on_complete, false)
  if on_complete == nil then
    helper:ClearCallback()
  end
end

return M
