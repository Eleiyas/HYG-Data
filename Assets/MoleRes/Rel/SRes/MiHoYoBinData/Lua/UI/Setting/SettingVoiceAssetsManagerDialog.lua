local M = G.Class("SettingVoiceAssetsManagerDialog", G.UIWindow)
local base = G.UIWindow
local voice_item_cls = "UI/Setting/SettingVoiceAssetsItem"

local function format_size(size)
  size = math.max(0, size or 0)
  if size < 1024 then
    return size .. "B"
  elseif size < 1048576 then
    return string.format("%.1fKB", size / 1024)
  elseif size < 1073741824 then
    return string.format("%.1fMB", size / 1048576)
  end
  return string.format("%.2fGB", size / 1073741824)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Setting/SettingVoiceAssetsManagerDialog"
  self.config.type = EUIType.Dialog
  self._items = {}
  self._voice_list = {}
  self._checked = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  self:bind_close_btn(self._btn_close_area, true)
  self:bind_callback(self._btn_delete, pack(self, M._on_btn_delete))
  self:add_evt_listener(EventID.onUpdateDownloadingUI, pack(self, M._on_download_progress_update))
end

function M:on_enable()
  base.on_enable(self)
  UIUtil.set_light_active(self.trans, true)
  local data = self:get_extra_data()
  self._on_close = data ~= nil and data.on_close or nil
  self._checked = {}
  self:_refresh_data()
  self:_refresh_ui()
end

function M:on_close()
  if self._on_close ~= nil then
    local callback = self._on_close
    self._on_close = nil
    callback()
  end
  base.on_close(self)
end

function M:on_destroy()
  self._items = {}
  self._voice_list = {}
  self._checked = {}
  self._on_close = nil
  base.on_destroy(self)
end

function M:_refresh_data()
  self._voice_list = {}
  local configs = LocManagerIns:get_all_voice_lan_config()
  if is_null(configs) then
    return
  end
  local cur_config = LocManagerIns:get_cur_voice_lan_config()
  local cur_folder = ""
  if not is_null(cur_config) then
    cur_folder = cur_config.folderName
  end
  if not string.is_valid(cur_folder) then
    Logger.LogWarning("SettingVoiceAssetsManagerDialog: current voice language config is missing")
  end
  for i = 0, configs.Count - 1 do
    local config = configs[i]
    if not is_null(config) then
      local data = self:_build_voice_data(config, cur_folder)
      if data.is_in_use or data.is_downloading or 0 < data.occupied then
        table.insert(self._voice_list, data)
      end
    end
  end
end

function M:_build_voice_data(config, cur_folder)
  local data = {
    folder = config.folderName,
    display_name = LocManagerIns:get_voice_lan_display_name(config),
    is_in_use = config.folderName == cur_folder,
    occupied = 0
  }
  if CsDownloadManagerUtil.IsVoiceDownloading() and CsDownloadManagerUtil.GetDownloadingVoiceLanguageFolder() == data.folder then
    data.is_downloading = true
  elseif CsDownloadManagerUtil.RefreshVoiceDownloadQuery(data.folder) then
    data.occupied = CsDownloadManagerUtil.GetVoiceDownloadedSize()
  end
  data.can_delete = not data.is_in_use and not data.is_downloading and data.occupied > 0
  data.state_text = self:_build_state_text(data)
  return data
end

function M:_build_state_text(data)
  if data.is_in_use then
    return UIUtil.get_text_by_id("Voice_Manager_State_InUse")
  end
  if data.is_downloading then
    return string.format(UIUtil.get_text_by_id("Voice_Manager_State_Downloading"), math.floor(CsDownloadManagerUtil.GetCurrentProgress() * 100))
  end
  if data.occupied > 0 then
    return string.format(UIUtil.get_text_by_id("Voice_Manager_State_Downloaded"), format_size(data.occupied))
  end
  return UIUtil.get_text_by_id("Voice_Manager_State_NotDownloaded")
end

function M:_refresh_ui()
  self:_ensure_items(#self._voice_list)
  for i = 1, #self._items do
    self:_render_item(i, self._voice_list[i])
  end
  self:_refresh_delete_btn_state()
end

function M:_collect_delete_targets()
  local targets = {}
  local total_size = 0
  for _, data in ipairs(self._voice_list) do
    if self._checked[data.folder] and data.can_delete then
      table.insert(targets, data)
      total_size = total_size + data.occupied
    end
  end
  return targets, total_size
end

function M:_refresh_delete_btn_state()
  if is_null(self._btn_delete) then
    return
  end
  local targets = self:_collect_delete_targets()
  self._btn_delete.interactable = 0 < #targets
end

function M:_render_item(index, data)
  local item = self._items[index]
  if item == nil then
    return
  end
  if data == nil then
    item:render(nil, nil)
    return
  end
  local folder = data.folder
  data.is_checked = self._checked[folder] == true
  item:render(data, function(is_on)
    self:_on_item_check_changed(folder, is_on)
  end, function()
    self:_on_uncheckable_item_clicked()
  end)
end

function M:_on_uncheckable_item_clicked()
  local targets = self:_collect_delete_targets()
  if #targets == 0 then
    return
  end
  self._checked = {}
  self:_refresh_ui()
end

function M:_on_download_progress_update(msg)
  if not msg or not msg.isVoiceTopUp then
    return
  end
  if msg.allComplete then
    self:_refresh_data()
    self:_refresh_ui()
    return
  end
  self:_refresh_downloading_item(msg)
end

function M:_refresh_downloading_item(msg)
  local folder = msg.voiceLanguageFolder
  if not string.is_valid(folder) then
    return
  end
  for i, data in ipairs(self._voice_list) do
    if data.folder == folder then
      if not data.is_downloading then
        data.is_downloading = true
        data.can_delete = false
        self._checked[folder] = nil
        self:_refresh_delete_btn_state()
      end
      data.state_text = string.format(UIUtil.get_text_by_id("Voice_Manager_State_Downloading"), math.floor((msg.process or 0) * 100))
      self:_render_item(i, data)
      return
    end
  end
end

function M:_ensure_items(count)
  for i = #self._items + 1, count do
    local trans = self._list_voice:AddItem(0, true)
    self._items[i] = self:add_panel(voice_item_cls, trans)
  end
end

function M:_on_item_check_changed(folder, is_on)
  self._checked[folder] = is_on == true
  self:_refresh_delete_btn_state()
end

function M:_on_btn_delete()
  local targets, total_size = self:_collect_delete_targets()
  if #targets == 0 then
    UIUtil.show_tips_by_text_id("Voice_Manager_Delete_None")
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.NormalWithoutClose)
  popup:set_texts(string.format(UIUtil.get_text_by_id("Voice_Manager_Delete_Confirm"), format_size(total_size)), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    for _, data in ipairs(targets) do
      CsDownloadManagerUtil.DeleteVoiceByFolder(data.folder)
    end
    self._checked = {}
    self:_refresh_data()
    self:_refresh_ui()
  end, nil, nil)
  popup:show()
end

return M
