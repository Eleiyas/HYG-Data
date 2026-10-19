local M = G.Class("ActivitySignInDayCell", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:refresh(slot_data)
  if slot_data == nil then
    return
  end
  self._slot_data = slot_data
  UIUtil.set_text(self._text_count, tostring(slot_data.Day or 0))
  self:_refresh_reward()
  self._state:SetState(slot_data.State)
  if slot_data.State == activity_center_module.signin_slot_state.Signed then
    self._red_point:ShowRedPoint(RedPointType.GiftRP)
  else
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_refresh_reward()
  local reward = self:get_first_reward()
  if reward == nil or reward.ConfigId == 0 then
    return
  end
  local item_cfg = item_module:get_cfg_by_id(reward.ConfigId)
  if item_cfg and string.is_valid(item_cfg.icon) then
    UIUtil.set_image(self._icon, item_cfg.icon, self:get_load_proxy())
  end
  UIUtil.set_text(self._text_num, "x" .. tostring(reward.Count))
  self._state_quilty:SetState(item_cfg.rank or 0)
end

function M:get_all_rewards()
  if self._slot_data and self._slot_data.Rewards and self._slot_data.Rewards.Count > 0 then
    return list_to_table(self._slot_data.Rewards)
  end
  return {}
end

function M:get_first_reward()
  if self._slot_data and self._slot_data.Rewards and self._slot_data.Rewards.Count > 0 then
    return self._slot_data.Rewards[0]
  end
  return nil
end

function M:get_btn()
  return self._btn
end

function M:get_day()
  return self._slot_data.Day
end

return M
