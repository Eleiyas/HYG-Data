local M = G.Class("BattlePassDailyRewardPanel", G.UIPanel)
local base = G.UIPanel
local item_v2_panel_cls = "UI/Item/ItemV2Panel"
local warning_text_format = "<style=TextWarning_Dark>%s</style>"

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
  self:_refresh_reward_items(reward_data.ItemList)
end

function M:_refresh_left_time()
  local end_timestamp = tonumber(theme_season_module:get_end_timestamp()) or 0
  local left_days = curio_emporium_module:get_left_game_days(end_timestamp)
  local days_text = tostring(left_days)
  if left_days <= 7 then
    days_text = string.format(warning_text_format, days_text)
  end
  UIUtil.set_text_by_id(self._txt_left_time, "DailyReward_Left_Time", days_text)
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
