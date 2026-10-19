local M = G.Class("MonthlyPassDailyRewardPanel", G.UIPanel)
local base = G.UIPanel
local item_v2_panel_cls = "UI/Item/ItemV2Panel"

function M:init()
  base.init(self)
  self._item_entries = {}
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  self._item_entries = {}
  base.on_destroy(self)
end

function M:refresh(reward_data)
  if is_null(reward_data) then
    return
  end
  self:_refresh_left_time()
  self:_refresh_reward_days_tip(reward_data.RewardDays)
  self:_refresh_reward_items(reward_data.ItemList)
end

function M:_refresh_left_time()
  local _, left_days = curio_emporium_module:get_month_card_state()
  local days_text = curio_emporium_module:get_month_card_left_days_text(left_days)
  UIUtil.set_text_by_id(self._txt_left_time, "DailyReward_Left_Time", days_text)
end

function M:_refresh_reward_days_tip(reward_days)
  reward_days = tonumber(reward_days) or 0
  UIUtil.set_active(self._obj_lay_tips, 1 < reward_days)
  if reward_days <= 0 then
    UIUtil.set_active(self._txt_tips, false)
    return
  end
  UIUtil.set_text_by_id(self._txt_tips, "DailyReward_Monthly_Reward_Days_Tip", reward_days)
  UIUtil.set_active(self._txt_tips, true)
end

function M:_refresh_reward_items(item_list)
  local item_count = is_null(item_list) and 0 or item_list.Count
  for index = 1, item_count do
    local entry = self._item_entries[index]
    if not entry then
      local obj = self._list_item_binder_content:AddItem(0)
      if not_null(obj) then
        entry = {
          obj = obj,
          panel = self:add_panel(item_v2_panel_cls, obj)
        }
        self._item_entries[index] = entry
      end
    end
    if entry then
      local item = item_list[index - 1]
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_item_data(item.ItemId, item.ItemCount)
      entry.panel:bind_item_info_btn(item.ItemId)
    end
  end
  for index = item_count + 1, #self._item_entries do
    UIUtil.set_active(self._item_entries[index].obj, false)
  end
end

return M
