local M = G.Class("CommonCategoryUnlockMaxCountItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh()
  self:set_active(self._extra_data ~= nil)
  if self._extra_data == nil then
    return
  end
  local level = self._extra_data.level or 0
  UIUtil.set_text(self._txt_last_lv, TextMapFormatUtil.FormatInteger(level - 1))
  UIUtil.set_text(self._txt_curr_lv, TextMapFormatUtil.FormatInteger(level))
  UIUtil.set_text_by_id(self._txt_unlock_info, "StarExpress_Hud_LevelUp_Main")
end

return M
