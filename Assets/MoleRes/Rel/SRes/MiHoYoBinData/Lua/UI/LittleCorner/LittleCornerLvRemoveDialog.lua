local M = G.Class("LittleCornerLvRemoveDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerLvRemoveDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
end

function M:on_open()
  base.on_open(self)
  self:_refresh()
end

function M:_refresh()
  local extra = self:get_extra_data() or {}
  UIUtil.set_text(self._txt_last_lv, tostring(extra.before_level or 0))
  UIUtil.set_text(self._txt_current_lv, tostring(extra.after_level or 0))
  UIUtil.set_text(self._txt_last_lv_limit, tostring(extra.before_limit or 0))
  UIUtil.set_text(self._txt_current_lv_limit, tostring(extra.after_limit or 0))
end

return M
