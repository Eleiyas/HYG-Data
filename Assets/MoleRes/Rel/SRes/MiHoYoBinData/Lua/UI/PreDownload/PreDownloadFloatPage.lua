local M = G.Class("PreDownloadFloatPage", G.UIWindow)
local base = G.UIWindow
local InterActType = {Down = 1, Up = 2}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PreDownload/PreDownloadFloatPage"
  self.config.type = EUIType.Top
  self.config.input_penetrate = true
  self.config.destroy_when_clear_ui = false
  self.config.is_always_cache = true
  self._ui_drag = nil
  self._downloaded_size = 0
  self._total_size = 0
end

function M:on_create()
  base.on_create(self)
  self._ui_drag = UIUtil.find_cmpt(self.trans, nil, typeof(GMBtnDrag))
  if not_null(self._ui_drag) then
    self._ui_drag:AddClickListener(pack(self, M._on_click), pack(self, M._on_interaction))
  end
end

function M:on_enable()
  base.on_enable(self)
  if not_null(self._ui_drag) then
    self._ui_drag.ignoreDrag = false
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.onUpdateDownloadingUI, pack(self, M._on_download_update))
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:_on_download_update(msg)
  if msg.allComplete then
    self:close_self()
    return
  end
  if not_null(self._slider) then
    self._slider.value = msg.process
  end
  if not_null(self._txt_percent) then
    UIUtil.set_text(self._txt_percent, math.floor(msg.process * 100) .. "%")
  end
  self._downloaded_size = msg.downloadedSize
  self._total_size = msg.totalSize
end

function M:_on_click()
  local downloaded_mb = string.format("%.1f", self._downloaded_size / 1048576)
  local total_mb = string.format("%.1f", self._total_size / 1048576)
  local info_text = UIUtil.get_text_by_id("PreDownload_Cancel_Info", downloaded_mb, total_mb)
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(info_text, UIUtil.get_text_by_id("Common_Cancel"), UIUtil.get_text_by_id("PreDownload_Continue"), nil)
  popup:set_callbacks(function()
    EventCenter.Broadcast(EventID.onCancelPreDownload)
  end, nil, nil)
  popup:show()
end

function M:_on_interaction(type)
  if type then
    if type == InterActType.Down then
      InputManagerIns:lock_input(input_lock_from.Common)
    elseif type == InterActType.Up then
      InputManagerIns:unlock_input(input_lock_from.Common)
    end
  end
end

function M:on_destroy()
  if self._ui_drag then
    self._ui_drag:RemoveClickListener()
  end
  base.on_destroy(self)
end

return M
