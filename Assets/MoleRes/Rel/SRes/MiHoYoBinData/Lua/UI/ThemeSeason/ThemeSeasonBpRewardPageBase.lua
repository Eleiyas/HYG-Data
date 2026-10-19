local M = G.Class("ThemeSeasonBpRewardPageBase", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.type = EUIType.Dialog
  self._txt_bp_name = nil
  self._btn_close = nil
  self._info = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self._info = data and data.info or nil
  self:_refresh()
end

function M:on_close()
  base.on_close(self)
  self._info = nil
end

function M:_refresh()
  if self._info == nil then
    return
  end
  UIUtil.set_text(self._txt_bp_name, self._info.bp_name or "")
  self:_refresh_content(self._info)
end

function M:_refresh_content(info)
end

return M
