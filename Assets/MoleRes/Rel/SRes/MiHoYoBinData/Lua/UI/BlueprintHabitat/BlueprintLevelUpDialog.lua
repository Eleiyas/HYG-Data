local M = G.Class("BlueprintLevelUpDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintLevelUpDialog"
  self.config.type = EUIType.Dialog
  self._level = 0
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:on_open()
  base.on_open(self)
  self._level = self._extra_data and self._extra_data.level or 0
  self:_refresh()
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close)
end

function M:_refresh()
  if not_null(self._txt_lv) then
    UIUtil.set_text_by_id(self._txt_lv, "Habitat_CurrentLevel", self._level)
  end
  if not_null(self._txt_info) then
    local cfg = ExcelDataUtil.get_value(typeof(BHabitatLevelCfg), self._level)
    UIUtil.set_text(self._txt_info, cfg and cfg.leveldescribe or "")
  end
end

return M
