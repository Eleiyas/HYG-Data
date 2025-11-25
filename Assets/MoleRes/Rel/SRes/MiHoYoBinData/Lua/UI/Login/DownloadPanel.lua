local M = G.Class("DownloadPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  UIUtil.set_text(self._txt_info, "")
  self._progress_bar.value = 0
  self:_show_process_bar(false)
  UIUtil.set_text(self._txt_percent, "")
  self:bind_callback(self._btn_enter_game, pack(self, M._on_click_enter))
  self:bind_callback(self._btn_background, pack(self, M._on_click_enter))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_complete()
  InputManagerIns:unlock_input(input_lock_from.Common)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.onUpdateDownloadingUI, pack(self, M._on_update_ui))
end

function M:_show_process_bar(is_show)
  self._show_process = is_show
  UIUtil.set_active(self.trans, self._show_process)
end

function M:_on_update_ui(msg)
  self._b_all_complete = msg.allComplete
  if msg.allComplete then
    self:_refresh_complete()
    return
  end
  if self._show_process ~= msg.showProcessBar then
    self:_show_process_bar(msg.showProcessBar)
  end
  if msg.totalSize > 0 then
    UIUtil.set_text(self._txt_info, string.format("%s %s/%s %s/s", msg.desc, self:_adaptive_size(msg.downloadedSize), self:_adaptive_size(msg.totalSize), self:_adaptive_size(msg.downloadSpeed)))
    self._progress_bar.size = msg.process
    UIUtil.set_text(self._txt_percent, math.floor(msg.process * 100) .. "%")
  else
    UIUtil.set_text(self._txt_info, msg.desc)
    self._progress_bar.size = msg.process
    UIUtil.set_text(self._txt_percent, math.floor(msg.process * 100) .. "%")
  end
end

function M:reset_complete()
  self._b_all_complete = false
end

function M:is_complete()
  return self._b_all_complete
end

function M:_refresh_complete()
  if self._b_all_complete then
    self:_on_all_complete()
  else
    UIUtil.set_active(self._obj_progress_bar, true)
    UIUtil.set_active(self._btn_enter_game, false)
    UIUtil.set_active(self._btn_background, false)
  end
end

function M:_on_all_complete()
  UIUtil.set_active(self._obj_progress_bar, false)
  UIUtil.set_active(self._btn_enter_game, true)
  UIUtil.set_active(self._btn_background, true)
  self.holder:on_download_finish()
end

function M:_on_click_enter()
  self:_do_click_enter()
end

function M:_do_click_enter()
  EventCenter.Broadcast(EventID.ClickToEnter, nil)
end

function M:_adaptive_size(size)
  if size < 1024 then
    return size .. "B"
  elseif size < 1048576 then
    return string.format("%.1fKB", size / 1024)
  else
    return string.format("%.1fMB", size / 1048576)
  end
end

return M
