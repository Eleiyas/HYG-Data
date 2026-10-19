local M = G.Class("FruitKingColorTabItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._option_id = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_cell, pack(self, M._on_toggle))
end

function M:_on_toggle(is_on)
  if not is_on or self._option_id <= 0 then
    return
  end
  if self.holder and self.holder.on_fruit_king_color_tab_selected then
    self.holder:on_fruit_king_color_tab_selected(self._option_id)
  end
end

function M:refresh(option, is_selected)
  self._option_id = option.OptionId
  local display_data
  if option.CodexItemId > 0 then
    display_data = codex_module:get_data_by_id(option.CodexItemId)
  end
  if is_null(display_data) then
    display_data = option.DisplayData
  end
  local icon_path = display_data and display_data.ItemCfg and display_data.ItemCfg.icon or ""
  if string.is_valid(icon_path) then
    UIUtil.set_image(self._img_icon_dynamic, icon_path, self:get_load_proxy())
  end
  self._ui_state_group_lock:SetState(option.IsUnlocked and 1 or 0)
  self:refresh_red_point(option)
  self:set_selected(is_selected)
end

function M:set_selected(is_selected)
  if self._tog_cell.SetIsOnWithoutNotify ~= nil then
    self._tog_cell:SetIsOnWithoutNotify(is_selected == true)
  else
    self._tog_cell.isOn = is_selected == true
  end
end

function M:refresh_red_point(option)
  local is_new = option ~= nil and option.IsUnlocked and option.CodexItemId > 0 and codex_module:is_new_item(option.CodexItemId)
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(is_new and RedPointType.NewRp or RedPointType.None)
  end
end

function M:get_option_id()
  return self._option_id
end

return M
