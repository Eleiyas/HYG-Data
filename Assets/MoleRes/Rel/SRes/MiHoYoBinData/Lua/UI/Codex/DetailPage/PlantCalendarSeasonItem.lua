local M = G.Class("PlantCalendarSeasonItem", G.UIBase)
local base = G.UIBase
local season_name_text_ids = {
  [1] = "TagDisplayName_Spring",
  [2] = "TagDisplayName_Summer",
  [3] = "TagDisplayName_Autumn",
  [4] = "TagDisplayName_Winter"
}

function M:init()
  base.init(self)
  self._option_id = 0
  self._is_unlocked = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_cell, pack(self, M._on_toggle))
end

function M:_on_toggle(is_on)
  if not is_on or self._option_id <= 0 then
    return
  end
  if self.holder and self.holder.on_plant_calendar_season_selected then
    self.holder:on_plant_calendar_season_selected(self._option_id)
  end
end

function M:refresh(option, is_selected)
  self._option_id = option.OptionId
  self._is_unlocked = option.IsUnlocked
  local name = option.Name
  if not string.is_valid(name) then
    local text_id = season_name_text_ids[self._option_id]
    name = text_id and UIUtil.get_text_by_id(text_id) or ""
  end
  UIUtil.set_text(self._txt_season_name, name or "")
  self:set_selected(is_selected)
end

function M:set_selected(is_selected)
  if self._tog_cell.SetIsOnWithoutNotify ~= nil then
    self._tog_cell:SetIsOnWithoutNotify(is_selected == true)
  else
    self._tog_cell.isOn = is_selected == true
  end
end

function M:get_option_id()
  return self._option_id
end

return M
