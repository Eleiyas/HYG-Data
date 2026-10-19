local M = G.Class("StarExploreLoadingPanel", G.LoadingPanelBase)
local base = G.LoadingPanelBase

function M:init()
  base.init(self)
  self._last_display_percent = -1
  self._desc = ""
  self._is_auto_loading = false
end

function M:on_enable()
  base.on_enable(self)
end

function M:init_data()
  base.init_data(self)
  self._last_display_percent = -1
  self._desc = ""
  self._is_auto_loading = false
end

function M:refresh()
  base.refresh(self)
  if self._extra_data then
    local show_progress = self._extra_data.showProgress ~= false
    if not is_null(self._progressbar) then
      UIUtil.set_active(self._progressbar, show_progress)
    end
    if not is_null(self._percentage) then
      UIUtil.set_active(self._percentage, show_progress)
    end
    self._desc = self._extra_data.desc or ""
    self._is_auto_loading = self:_is_auto_progress_mode()
  end
  self:update_percent(self.cur_percent or 0)
end

function M:update_percent(percent)
  base.update_percent(self, percent)
  if self._progressbar ~= nil then
    self._progressbar.value = self.cur_percent
  end
  local display_percent = math.ceil(self.cur_percent * 100)
  if self._last_display_percent ~= display_percent then
    self._last_display_percent = display_percent
    local sb = UIUtil.StringBuffer.new()
    sb:append_all(display_percent, "%")
    UIUtil.set_text(self._percentage, sb:to_string())
  end
end

function M:on_progress_changed(percent, desc)
  self._desc = desc or self._desc
  self:update_percent(percent)
end

function M:set_progressbar_active(active)
  if not is_null(self._progressbar) then
    UIUtil.set_active(self._progressbar, active)
  end
  if not is_null(self._percentage) then
    UIUtil.set_active(self._percentage, active)
  end
end

function M:_is_auto_progress_mode()
  if is_null(self._extra_data) then
    return false
  end
  if self._extra_data.progressMode == common_ui_module.loading_progress_mode.auto then
    return true
  end
  return self._extra_data.duration ~= nil and self._extra_data.duration > 0
end

function M:should_snap_progress(progress_data)
  if self:_is_auto_progress_mode() then
    return false
  end
  progress_data = progress_data or {}
  local extra_data = progress_data.extra_data
  return extra_data ~= nil and extra_data.duration ~= nil and extra_data.duration <= 0
end

function M:on_show_by_mode()
end

return M
