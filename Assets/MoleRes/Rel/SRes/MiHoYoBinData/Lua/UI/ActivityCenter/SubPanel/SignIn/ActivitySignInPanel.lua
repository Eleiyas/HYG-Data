local M = G.Class("ActivitySignInPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local CELL_CLS = "UI/ActivityCenter/SubPanel/SignIn/ActivitySignInDayCell"
local TOTAL_DAYS = 7

function M:init()
  base.init(self)
  self._small_cells = {}
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._tog_7day_l) then
    self._big_cell = self:add_panel(CELL_CLS, self._tog_7day_l)
    self:bind_callback(self._big_cell:get_btn(), function()
      self:_on_day_clicked(TOTAL_DAYS, self._big_cell:get_all_rewards())
    end)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnSignInActivityDataChanged, function()
    self:refresh()
  end)
end

function M:refresh()
  base.refresh(self)
  local data = self:get_activity_data()
  if data == nil then
    return
  end
  for d = 1, TOTAL_DAYS - 1 do
    local cls = self._small_cells[d]
    if cls == nil then
      local obj = self._first_6day_item_binder:AddItem(0)
      cls = self:add_panel(CELL_CLS, obj)
      self._small_cells[d] = cls
      self:bind_callback(cls:get_btn(), function()
        self:_on_day_clicked(cls:get_day(), cls:get_all_rewards())
      end)
    end
    cls:refresh(data:GetSlotData(d))
  end
  if self._big_cell ~= nil then
    self._big_cell:refresh(data:GetSlotData(TOTAL_DAYS))
  end
end

function M:_on_day_clicked(day_idx, rewards)
  local data = activity_center_module:get_activity_by_id(self._activity_id)
  if data == nil then
    return
  end
  local slot_data = data:GetSlotData(day_idx)
  if not slot_data then
    return
  end
  if slot_data.State ~= activity_center_module.signin_slot_state.Signed then
    local first = rewards and rewards[1]
    if first ~= nil then
      item_module:open_item_info_dialog(first.ConfigId, first.Count)
    end
    return
  end
  if data:IsClaiming() then
    return
  end
  data:RequestClaim(day_idx, function()
    self:_show_reward_dialog(data)
  end, true)
end

function M:_show_reward_dialog(data)
  local count = data.ClaimRewardCount or 0
  local items = {}
  for i = 0, count - 1 do
    table.insert(items, {
      id = data:GetClaimRewardItemId(i),
      num = data:GetClaimRewardItemCount(i)
    })
  end
  data:ClearLastClaimRewards()
  if #items <= 0 then
    return
  end
  common_ui_module:show_reward_dialog(nil, nil, items)
end

return M
