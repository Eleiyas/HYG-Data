local base_cls = require("UI/ThemeSeason/ThemeSeasonBpRewardPageBase")
local M = G.Class("ThemeSeasonBpRewardPage", base_cls)
local base = base_cls
local reward_item_cls = "UI/ThemeSeason/ThemeSeasonBpRewardItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonRewardPage"
  self._trans_add_group = nil
  self._item_list = nil
  self._item_panels = {}
end

function M:_refresh_content(info)
  local entries = {}
  local has_gift = info.gift_item_id and info.gift_item_id > 0
  if has_gift then
    entries[#entries + 1] = {
      item_id = info.gift_item_id,
      count = info.gift_item_count or 1,
      is_gift = true
    }
  end
  local instant_items = info.instant_items or {}
  for i = 1, #instant_items do
    entries[#entries + 1] = {
      item_id = instant_items[i].item_id,
      count = instant_items[i].count,
      is_gift = false
    }
  end
  self:_build_items(entries)
  self:_reposition_add_group(has_gift and 0 < #instant_items)
end

function M:_build_items(entries)
  for i = 1, #entries do
    local entry = entries[i]
    local panel = self._item_panels[i]
    if panel == nil then
      local obj = self._item_list:AddItem(0)
      if not_null(obj) then
        panel = self:add_panel(reward_item_cls, obj)
        self._item_panels[i] = panel
      end
    end
    if panel then
      panel:set_active(true)
      panel:set_item_data(entry.item_id, entry.count)
      panel:set_countdown_active(entry.is_gift)
      local item_id = entry.item_id
      local btn = panel:get_btn()
      if btn then
        self:bind_callback(btn, function()
          item_module:open_item_info_dialog(item_id, back_bag_module:get_coin_or_item_num(item_id))
        end)
      end
    end
  end
  for i = #entries + 1, #self._item_panels do
    local panel = self._item_panels[i]
    if panel then
      panel:set_active(false)
    end
  end
end

function M:_reposition_add_group(should_show)
  if is_null(self._trans_add_group) then
    return
  end
  UIUtil.set_active(self._trans_add_group, should_show)
  if should_show then
    self._trans_add_group:SetSiblingIndex(2)
  end
end

return M
