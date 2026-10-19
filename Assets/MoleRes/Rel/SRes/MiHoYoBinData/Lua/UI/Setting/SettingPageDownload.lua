local M = {}
local DL_STATE_DOWNLOADING = 0
local DL_STATE_PAUSED = 1
local DL_STATE_COMPLETE = 2
local DL_STATE_SPACE_LOW = 3
local DL_STATE_NOT_STARTED = 4
local DL_STATE_QUEUED = 5

function M:_refresh_download()
  self:_reset_content()
  self:_init_download_list()
  if is_null(self._list_download_trans) then
    return
  end
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, CsDownloadManagerUtil.GetPreDownloadVersion() .. UIUtil.get_text_by_id("Pre_Download_Tips_03"))
  end
  self:_update_download_state()
end

function M:_init_download_list()
  local item_go = self:_get_item_by_type(self._predownload_item_type, self._content_trans, "List_Download")
  if is_null(item_go) then
    return
  end
  self._list_download_trans = item_go.transform
  if is_null(self._list_download_trans) then
    return
  end
  self._dl_state_group = UIUtil.find_ui_state_group(self._list_download_trans, "state_group")
  self._txt_name = UIUtil.find_text(self._list_download_trans, "txt_name")
  self._txt_info = UIUtil.find_text(self._list_download_trans, "txt_info")
  self._slider_progress = UIUtil.find_slider(self._list_download_trans, "progress")
  self._dl_btn_start = UIUtil.find_button_ex(self._list_download_trans, "Contral/btn_start")
  self._dl_btn_resume = UIUtil.find_button_ex(self._list_download_trans, "Contral/btn_resume")
  self._dl_btn_paused = UIUtil.find_button_ex(self._list_download_trans, "Contral/btn_paused")
  self._dl_btn_del = UIUtil.find_button_ex(self._list_download_trans, "Contral/btn_del")
  if not_null(self._dl_btn_start) then
    self:bind_callback(self._dl_btn_start, pack(self, M._on_dl_start))
  end
  if not_null(self._dl_btn_resume) then
    self:bind_callback(self._dl_btn_resume, pack(self, M._on_dl_resume))
  end
  if not_null(self._dl_btn_paused) then
    self:bind_callback(self._dl_btn_paused, pack(self, M._on_dl_pause))
  end
  if not_null(self._dl_btn_del) then
    self:bind_callback(self._dl_btn_del, pack(self, M._on_dl_delete))
  end
end

function M:_update_download_state()
  if is_null(self._dl_state_group) then
    return
  end
  if not CsDownloadManagerUtil.HasPreDownloadInfo() then
    UIUtil.set_active(self._list_download_trans.gameObject, false)
    return
  end
  if CsDownloadManagerUtil.IsPreDownloadComplete() then
    self:_set_download_state(DL_STATE_COMPLETE)
  elseif CsDownloadManagerUtil.IsPreDownloading() then
    self:_set_download_state(DL_STATE_DOWNLOADING)
  elseif CsDownloadManagerUtil.IsPreDownloadPaused() then
    self:_set_download_state(DL_STATE_PAUSED)
  else
    self:_set_download_state(DL_STATE_NOT_STARTED)
  end
  self:_refresh_download_info(CsDownloadManagerUtil.GetCurrentProgress(), CsDownloadManagerUtil.GetCurrentDownloadedSize(), CsDownloadManagerUtil.GetCurrentTotalSize())
end

function M:_on_dl_start()
  if CsDownloadManagerUtil.IsPreDownloading() then
    return
  end
  CsDownloadManagerUtil.StartPreDownload()
  self:_set_download_state(DL_STATE_DOWNLOADING)
  self:_refresh_download_info(0, 0, 0)
end

function M:_on_dl_pause()
  if not CsDownloadManagerUtil.IsPreDownloading() then
    return
  end
  CsDownloadManagerUtil.PausePreDownload()
  self:_set_download_state(DL_STATE_PAUSED)
  self:_refresh_download_info(CsDownloadManagerUtil.GetCurrentProgress(), CsDownloadManagerUtil.GetCurrentDownloadedSize(), CsDownloadManagerUtil.GetCurrentTotalSize())
end

function M:_on_dl_resume()
  if CsDownloadManagerUtil.IsPreDownloading() then
    return
  end
  CsDownloadManagerUtil.StartPreDownload()
  self:_set_download_state(DL_STATE_DOWNLOADING)
  self:_refresh_download_info(CsDownloadManagerUtil.GetCurrentProgress(), CsDownloadManagerUtil.GetCurrentDownloadedSize(), CsDownloadManagerUtil.GetCurrentTotalSize())
end

function M:_on_dl_delete()
  if not CsDownloadManagerUtil.DeletePreDownloadFiles() then
    return
  end
  self:_set_download_state(DL_STATE_NOT_STARTED)
  self:_refresh_download_info(0, 0, 0)
end

function M:_on_dl_progress_update(msg)
  if not msg or not msg.isPreDownload then
    return
  end
  if msg.awaitingConfirmation then
    if self._select_tab_index ~= self._download_tab_index then
      return
    end
    if self._predownload_confirm_popup_open then
      return
    end
    self._predownload_confirm_popup_open = true
    self:_refresh_download_info(msg.process, msg.downloadedSize, msg.totalSize)
    local pending_size = math.max(0, msg.totalSize - msg.downloadedSize)
    self:_show_download_confirm(pending_size)
    return
  end
  if self._select_tab_index ~= self._download_tab_index then
    return
  end
  if is_null(self._dl_state_group) then
    return
  end
  if msg.allComplete then
    self:_set_download_state(DL_STATE_COMPLETE)
  elseif CsDownloadManagerUtil.IsPreDownloading() then
    self:_set_download_state(DL_STATE_DOWNLOADING)
  end
  self:_refresh_download_info(msg.process, msg.downloadedSize, msg.totalSize)
end

function M:_set_download_state(state)
  self._download_state = state
  if not_null(self._dl_state_group) then
    self._dl_state_group:SetState(state)
  end
end

function M:_refresh_download_info(process, downloaded_size, total_size)
  process = math.max(0, math.min(1, process or 0))
  downloaded_size = math.max(0, downloaded_size or 0)
  total_size = math.max(0, total_size or 0)
  if not_null(self._slider_progress) then
    self._slider_progress.value = process
  end
  if is_null(self._txt_info) then
    return
  end
  if self._download_state == DL_STATE_COMPLETE then
    UIUtil.set_text(self._txt_info, self:_format_download_mb(total_size))
  elseif self._download_state == DL_STATE_DOWNLOADING or self._download_state == DL_STATE_PAUSED then
    if 0 < total_size then
      UIUtil.set_text(self._txt_info, string.format("%s/%s", self:_format_download_mb(downloaded_size), self:_format_download_mb(total_size)))
    else
      UIUtil.set_text(self._txt_info, "")
    end
  else
    UIUtil.set_text(self._txt_info, "")
  end
end

function M:_format_download_mb(size)
  return string.format("%.1fMB", math.max(0, size or 0) / 1048576)
end

function M:_format_download_size(size)
  if size < 1024 then
    return size .. "B"
  elseif size < 1048576 then
    return string.format("%.1fKB", size / 1024)
  elseif size < 1073741824 then
    return string.format("%.1fMB", size / 1048576)
  end
  return string.format("%.2fGB", size / 1073741824)
end

function M:_show_download_confirm(total_size)
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.NormalWithoutClose)
  popup:set_texts(string.format(UIUtil.get_text_by_id("Download_Size_Confirm"), self:_format_download_size(total_size)), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self._predownload_confirm_popup_open = false
    CsDownloadManagerUtil.ConfirmPreDownload()
  end, function()
    self._predownload_confirm_popup_open = false
    EventCenter.Broadcast(EventID.onCancelPreDownload)
    self:_set_download_state(DL_STATE_NOT_STARTED)
    self:_refresh_download_info(0, 0, 0)
  end, function()
    self._predownload_confirm_popup_open = false
  end)
  popup:show()
end

return M
