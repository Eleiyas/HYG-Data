local M = {}
local VOICE_STATE_NOT_DOWNLOADED = 0
local VOICE_STATE_DOWNLOADED = 1
local VOICE_STATE_DOWNLOADING = 2
local VOICE_STATE_MANAGER = 3
local PATH_STATE_GROUP = "state_group"
local PATH_DATA_NUM = "txt_data_num"

local function safe_find(trans, path)
  if is_null(trans) then
    return nil
  end
  local target = trans:Find(path)
  if is_null(target) then
    return nil
  end
  return target
end

function M:_refresh_voice_drop_down_entry(setting_entry, show_name, cur_index)
  if is_null(self._content_trans) then
    return
  end
  local item_go = self:_get_item_by_type(self.e_item_type.drop_down_voice, self._content_trans, show_name)
  if item_go == nil then
    Logger.LogWarning("SettingPageVoice: _drop_down_item_voice is not bound on SettingPage.prefab")
    return
  end
  self._voice_entry = setting_entry
  self._voice_row_trans = item_go.transform
  self._voice_current_index = cur_index
  self._voice_pending_index = nil
  self:_build_voice_options(setting_entry)
  self:_rebuild_voice_state_cache()
  local name_trans = UIUtil.find_trans(self._voice_row_trans, "Name")
  local has_loc = not is_null(UIUtil.find_cmpt(name_trans, nil, typeof(TextEx))) or not is_null(UIUtil.find_cmpt(name_trans, nil, typeof(MonoLocalizedText)))
  if not is_null(show_name) and show_name.textId ~= nil and string.is_valid(show_name.textId) and has_loc then
    UIUtil.set_text_by_id(name_trans, show_name.textId)
  elseif not is_null(show_name) and show_name.ToStringExplicit ~= nil then
    UIUtil.set_text(name_trans, show_name:ToStringExplicit())
  else
    UIUtil.set_text(name_trans, show_name)
  end
  local drop_down = UIUtil.find_cmpt(self._voice_row_trans, "Contral/Dropdown", typeof(Dropdown))
  if is_null(drop_down) then
    return
  end
  self._voice_drop_down = drop_down
  drop_down:ClearOptions()
  local drop_down_options = SettingPageUtils.s_get_entry_options(setting_entry)
  if drop_down_options ~= nil then
    for _, v in pairs(drop_down_options) do
      self:_add_drop_item(drop_down, v)
    end
  end
  self._voice_manager_index = drop_down.options.Count
  self:_add_drop_item(drop_down, UIUtil.get_text_by_id("Voice_Manager_Entry"))
  drop_down.value = cur_index
  drop_down:RefreshShownValue()
  self:bind_callback(drop_down, pack(self, M._on_voice_option_selected))
  if drop_down.onShowHide ~= nil then
    drop_down.onShowHide:AddListener(pack(self, M._on_voice_list_show_hide))
  end
  self:_refresh_voice_views()
end

function M:_build_voice_options(setting_entry)
  self._voice_options = {}
  local available_options = setting_entry.displayData.availableOptions
  if is_null(available_options) then
    return
  end
  for j = 0, available_options.Count - 1 do
    local option = available_options[j]
    if not is_null(option) and not is_null(option.config) and not is_null(option.config.value) then
      self._voice_options[j] = {
        folder = option.config.value.folderName
      }
    end
  end
end

function M:_rebuild_voice_state_cache()
  self._voice_state_cache = {}
  if self._voice_options == nil then
    return
  end
  for index, option in pairs(self._voice_options) do
    local cached = {
      state = VOICE_STATE_NOT_DOWNLOADED,
      remaining = 0,
      occupied = 0
    }
    if CsDownloadManagerUtil.RefreshVoiceDownloadQuery(option.folder) then
      cached.occupied = CsDownloadManagerUtil.GetVoiceDownloadedSize()
      if CsDownloadManagerUtil.IsVoiceDownloadComplete() then
        cached.state = VOICE_STATE_DOWNLOADED
      else
        cached.remaining = CsDownloadManagerUtil.GetVoiceDownloadRemainingSize()
      end
    end
    self._voice_state_cache[index] = cached
  end
end

function M:_query_voice_state(index)
  local option = self._voice_options and self._voice_options[index]
  if option == nil then
    return VOICE_STATE_NOT_DOWNLOADED, 0, 0, 0
  end
  if CsDownloadManagerUtil.IsVoiceDownloading() and CsDownloadManagerUtil.GetDownloadingVoiceLanguageFolder() == option.folder then
    return VOICE_STATE_DOWNLOADING, CsDownloadManagerUtil.GetCurrentProgress(), 0, 0
  end
  local cached = self._voice_state_cache and self._voice_state_cache[index]
  if cached == nil then
    return VOICE_STATE_NOT_DOWNLOADED, 0, 0, 0
  end
  if cached.state == VOICE_STATE_DOWNLOADED then
    return VOICE_STATE_DOWNLOADED, 1, 0, cached.occupied
  end
  return VOICE_STATE_NOT_DOWNLOADED, 0, cached.remaining, cached.occupied
end

function M:_apply_voice_item_view(trans, index)
  if is_null(trans) then
    return
  end
  local state_group_trans = safe_find(trans, PATH_STATE_GROUP)
  local data_num_trans = safe_find(trans, PATH_DATA_NUM)
  if not self._voice_node_warned and (state_group_trans == nil or data_num_trans == nil) then
    self._voice_node_warned = true
    Logger.LogWarning(string.format("SettingPageVoice: item node missing, %s=%s %s=%s", PATH_STATE_GROUP, tostring(state_group_trans ~= nil), PATH_DATA_NUM, tostring(data_num_trans ~= nil)))
  end
  local state, progress, remaining, occupied
  if index == self._voice_manager_index then
    state, progress, remaining, occupied = VOICE_STATE_MANAGER, 0, 0, 0
  else
    state, progress, remaining, occupied = self:_query_voice_state(index)
  end
  if state_group_trans ~= nil then
    local state_group = UIUtil.find_ui_state_group(state_group_trans, nil)
    if not is_null(state_group) then
      state_group:SetState(state)
    end
  end
  if data_num_trans ~= nil then
    UIUtil.set_text(data_num_trans, self:_voice_data_num_text(index, state, progress, remaining, occupied))
  end
end

function M:_voice_data_num_text(index, state, progress, remaining, occupied)
  if state == VOICE_STATE_DOWNLOADING then
    return string.format("%d%%", math.floor(progress * 100))
  end
  if state == VOICE_STATE_DOWNLOADED then
    if index == self._voice_current_index or occupied <= 0 then
      return ""
    end
    return self:_format_download_size(occupied)
  end
  if state == VOICE_STATE_NOT_DOWNLOADED and 0 < remaining then
    return self:_format_download_size(remaining)
  end
  return ""
end

function M:_refresh_voice_views()
  self:_refresh_voice_list_items()
end

function M:_refresh_voice_list_items()
  if is_null(self._voice_drop_down) then
    return
  end
  local scroll_rect = self._voice_drop_down:GetComponentInChildren(typeof(ScrollRect))
  if is_null(scroll_rect) or is_null(scroll_rect.content) then
    return
  end
  local content = scroll_rect.content
  local option_index = 0
  for i = 0, content.childCount - 1 do
    local child = content:GetChild(i)
    if not is_null(child) and child.gameObject.activeSelf then
      self:_apply_voice_item_view(child, option_index)
      option_index = option_index + 1
    end
  end
end

function M:_on_voice_list_show_hide(is_show)
  if not is_show then
    return
  end
  self:_rebuild_voice_state_cache()
  self:_refresh_voice_list_items()
end

function M:_on_voice_option_selected(index)
  if self._voice_suppress_callback then
    return
  end
  if index == self._voice_manager_index then
    self:_set_voice_value(self._voice_current_index)
    self:_open_voice_assets_manager()
    return
  end
  local option = self._voice_options and self._voice_options[index]
  if option == nil then
    return
  end
  local state, _, remaining = self:_query_voice_state(index)
  if state == VOICE_STATE_DOWNLOADED then
    self:_apply_voice_language(index)
    return
  end
  if state == VOICE_STATE_DOWNLOADING then
    self:_set_voice_value(self._voice_current_index)
    self:_pause_voice_download()
    return
  end
  self:_show_voice_download_confirm(index, remaining)
end

function M:_pause_voice_download()
  if not CsDownloadManagerUtil.PauseVoiceDownload() then
    return
  end
  self._voice_pending_index = nil
  self:_rebuild_voice_state_cache()
  self:_refresh_voice_views()
end

function M:_set_voice_value(index)
  if is_null(self._voice_drop_down) or index == nil then
    return
  end
  self._voice_suppress_callback = true
  self._voice_drop_down.value = index
  self._voice_drop_down:RefreshShownValue()
  self._voice_suppress_callback = false
end

function M:_apply_voice_language(index)
  self._voice_current_index = index
  self._voice_pending_index = nil
  self:_apply_setting_entry(self._voice_entry, index)
  self:_refresh_voice_views()
end

function M:_show_voice_download_confirm(index, size)
  local option = self._voice_options and self._voice_options[index]
  if option == nil then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.NormalWithoutClose)
  popup:set_texts(string.format(UIUtil.get_text_by_id("Voice_Download_Size_Confirm"), self:_format_download_size(size)), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self._voice_pending_index = index
    if not CsDownloadManagerUtil.StartVoiceDownloadByFolder(option.folder) then
      self._voice_pending_index = nil
      UIUtil.show_tips_by_text_id("Voice_Download_Start_Failed")
    end
    self:_set_voice_value(self._voice_current_index)
    self:_refresh_voice_views()
  end, function()
    self:_set_voice_value(self._voice_current_index)
  end, function()
    self:_set_voice_value(self._voice_current_index)
  end)
  popup:show()
end

function M:_open_voice_assets_manager()
  UIManagerInstance:open("UI/Setting/SettingVoiceAssetsManagerDialog", {
    on_close = pack(self, M._on_voice_assets_manager_closed)
  })
end

function M:_on_voice_assets_manager_closed()
  self:_rebuild_voice_state_cache()
  self:_refresh_voice_views()
end

function M:_on_voice_dl_progress_update(msg)
  if not msg or not msg.isVoiceTopUp then
    return
  end
  if self._select_tab_index ~= self._multi_lang_tab_index then
    return
  end
  if is_null(self._voice_drop_down) then
    return
  end
  if msg.allComplete then
    self:_rebuild_voice_state_cache()
    if self._voice_pending_index ~= nil then
      local pending_index = self._voice_pending_index
      self._voice_pending_index = nil
      self:_set_voice_value(pending_index)
      self:_apply_voice_language(pending_index)
      return
    end
  end
  self:_refresh_voice_views()
end

return M
