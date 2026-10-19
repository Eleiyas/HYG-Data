local M = G.Class("GeLianFoodMarketBoardDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GeLianFoodMarket/GeLianFoodMarketBoardDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_bg)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
end

function M:_refresh_view()
  local entries = (self:get_extra_data() or {}).entries or {}
  UIUtil.set_text(self._txt_tips, self:_get_broadcast_text(entries))
  UIUtil.set_text(self._txt_time, self:_get_broadcast_time())
end

function M:_get_broadcast_text(entries)
  if 2 <= #entries then
    if self:_is_ratio_no_change(entries) then
      return UIUtil.get_text_by_id("CropTrading_News_Nothing")
    end
    local min_entry, max_entry = self:_get_min_max_entries(entries)
    if min_entry.display_multiplier >= 100 or max_entry.display_multiplier <= 100 then
      local representative = max_entry.display_multiplier > 100 and max_entry or min_entry
      return self:_get_single_entry_text(representative)
    end
    return UIUtil.get_text_by_id("CropTrading_News_MoreCrops", TagUtil.get_tag_name_in_game_by_string(min_entry.tag), TextMapFormatUtil.FormatPercent((100 - min_entry.display_multiplier) / 100, 0), TagUtil.get_tag_name_in_game_by_string(max_entry.tag), TextMapFormatUtil.FormatPercent((max_entry.display_multiplier - 100) / 100, 0))
  end
  local entry = entries[1]
  if entry == nil then
    return UIUtil.get_text_by_id("CropTrading_News_Nothing")
  end
  return self:_get_single_entry_text(entry)
end

function M:_get_single_entry_text(entry)
  if entry.display_multiplier == 100 then
    return UIUtil.get_text_by_id("CropTrading_News_Nothing")
  end
  local text_id = entry.display_multiplier > 100 and "CropTrading_News_OneCrop_Rise" or "CropTrading_News_OneCrop_Decline"
  return UIUtil.get_text_by_id(text_id, TagUtil.get_tag_name_in_game_by_string(entry.tag), TextMapFormatUtil.FormatPercent(math.abs(entry.display_multiplier - 100) / 100, 0))
end

function M:_is_ratio_no_change(entries)
  for i = 1, #entries do
    if entries[i].display_multiplier ~= 100 then
      return false
    end
  end
  return true
end

function M:_get_min_max_entries(entries)
  local min_entry = entries[1]
  local max_entry = entries[1]
  for i = 2, #entries do
    local entry = entries[i]
    if entry.display_multiplier < min_entry.display_multiplier then
      min_entry = entry
    end
    if entry.display_multiplier > max_entry.display_multiplier then
      max_entry = entry
    end
  end
  return min_entry, max_entry
end

function M:_get_broadcast_time()
  local end_time = TimeUtil.ServerUtcTimeSeconds or 0
  if end_time <= 0 then
    return ""
  end
  local local_end_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(end_time)
  return TextMapFormatUtil.FormatDateMD(local_end_time)
end

return M
