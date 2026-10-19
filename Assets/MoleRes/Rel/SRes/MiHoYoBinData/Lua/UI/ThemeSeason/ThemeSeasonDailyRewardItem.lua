local item_v2_cls = item_module.item_v2_panel_cls_name
local M = G.Class("ThemeSeasonDailyRewardItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._reward_panel = nil
  self._state_group = nil
  self._obj_reward = nil
end

function M:on_create()
  base.on_create(self)
  if is_null(self._obj_reward) then
    return
  end
  self._reward_panel = self:add_panel(item_v2_cls, self._obj_reward)
end

function M:refresh(reward, state)
  if not_null(self._state_group) then
    self._state_group:SetState(state)
  end
  if self._reward_panel ~= nil then
    self._reward_panel:set_item_data(reward.item_id, reward.count)
    self._reward_panel:bind_item_info_btn(reward.item_id)
  end
end

return M
