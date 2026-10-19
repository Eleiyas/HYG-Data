local M = G.Class("StarBayDiaryShareDialog", G.UIWindow)
local base = G.UIWindow
local share_platform_item_cls = "UI/Share/SharePlatformItem"
local share_platform_item = require(share_platform_item_cls)
local LayoutVersion = CS.miHoYo.HYG.UI.LayoutVersion
local UIAdaptiveUtils = CS.miHoYo.HYG.UI.UIAdaptiveUtils
local save_result_tip_duration = 1.0
local save_result_tip_cooldown_end_time = 0

local function clear_image_if_valid(target)
  if is_null(target) then
    return
  end
  target.sprite = nil
end

local function format_diary_date(timestamp)
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(timestamp or 0)
  return TextMapFormatUtil.FormatDateYMD(date_time)
end

local function get_save_result_tip_cooldown_remain_time()
  return math.max(0, save_result_tip_cooldown_end_time - Time.realtimeSinceStartup)
end

local function show_save_result_tip(text_id)
  UIUtil.show_tips({
    txt = UIUtil.get_text_by_id(text_id),
    duration = save_result_tip_duration
  })
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CompanionStar/StarBay/StarBayDiaryShareDialog"
  self.config.type = EUIType.Dialog
  self._photo_share_platforms = {}
  self._is_close = false
  self._view_bind_version = 0
  self._share_platform_photo = nil
  self._is_saving_to_album = false
  self._is_save_button_locked = false
  self._save_button_unlock_version = 0
  self._is_capturing_share_photo = false
  self._capture_photo_callbacks = {}
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
  end
  if not is_null(self._btn_bg) then
    self:bind_close_btn(self._btn_bg)
  end
  if not is_null(self._share_item_template) then
    UIUtil.set_active(self._share_item_template.gameObject, false)
  end
  if not is_null(self._btn_save) then
    self:bind_callback(self._btn_save, pack(self, M._save_to_album))
  end
  if not is_null(self._btn_transport) then
    self:bind_callback(self._btn_transport, pack(self, M._share_face_to_face))
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_set_capture_controls_visible(true)
  self:_cancel_capture_photo_callbacks()
  self._is_close = false
  self._share_platform_photo = nil
  self:_refresh_save_button_cooldown_state()
  local data = self:get_extra_data() or {}
  self._view_data = data.view_data
  self._entry_cfg = data.entry_cfg
  self._style_cfg = data.style_cfg
  self._type_cfg = data.type_cfg
  self._album_photo = data.album_photo
  self:_refresh_view()
  self:_refresh_share_platform()
end

function M:on_before_close()
  self:_set_capture_controls_visible(true)
  self:_cancel_capture_photo_callbacks()
  self._is_close = true
  self._share_platform_photo = nil
  self._view_bind_version = (self._view_bind_version or 0) + 1
  base.on_before_close(self)
end

function M:on_destroy()
  self:_set_capture_controls_visible(true)
  self:_cancel_capture_photo_callbacks()
  self._is_close = true
  self._share_platform_photo = nil
  base.on_destroy(self)
end

function M:_advance_view_bind_version()
  self._view_bind_version = (self._view_bind_version or 0) + 1
  return self._view_bind_version
end

function M:_is_async_request_valid(bind_version, album_photo)
  return not self._is_close and not is_null(self.game_obj) and self.is_active and self._view_bind_version == bind_version and (album_photo == nil or self._album_photo == album_photo)
end

function M:_refresh_view()
  local bind_version = self:_advance_view_bind_version()
  clear_image_if_valid(self._img_photo)
  if self._entry_cfg == nil or self._view_data == nil then
    return
  end
  UIUtil.set_text(self._txt_title, self._entry_cfg.title)
  UIUtil.set_text(self._txt_content, self._entry_cfg.content)
  UIUtil.set_text(self._txt_unlock_date, format_diary_date(self._view_data.unlockTimestamp))
  UIUtil.set_text(self._txt_share_date, format_diary_date(CsServerTimeModuleUtil.ServerUtcNowTimeStamp()))
  UIUtil.set_text(self._txt_name, player_module:get_player_name())
  local avatar_id = player_module:get_player_data() and player_module:get_player_data().playerServerData and player_module:get_player_data().playerServerData.AvatarID or 0
  if avatar_id ~= 0 then
    local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id)
    if head_cfg and string.is_valid(head_cfg.respath) and not is_null(self._img_head) then
      UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
    end
  end
  if self._view_data and self._view_data.npcId ~= 0 and not is_null(self._tag_icon) then
    local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), self._view_data.npcId)
    if npc_cfg and string.is_valid(npc_cfg.iconnamesmall) then
      UIUtil.set_image(self._tag_icon, npc_cfg.iconnamesmall, self:get_load_proxy())
    end
  end
  if self._type_cfg ~= nil then
    UIUtil.set_text_by_id(self._tag_title, self._type_cfg.displayName)
    if not is_null(self._tag_state_group) then
      self._tag_state_group:SetState(self._type_cfg.styleStateId or 0)
    end
  end
  if self._style_cfg ~= nil and not is_null(self._style_binding_group) then
    self._style_binding_group:Apply(self._style_cfg, self:get_load_proxy())
  end
  clear_image_if_valid(self._img_photo_dynamic)
  if not_null(self._album_photo) and not_null(self._img_photo_dynamic) then
    local album_photo = self._album_photo
    album_photo:LoadPhotoTextureAsync(function(success)
      if success and not_null(album_photo.photoSprite) and self:_is_async_request_valid(bind_version, album_photo) then
        self._img_photo_dynamic.sprite = album_photo.photoSprite
      end
    end)
  end
  if not is_null(self._state_group_photo) then
    self._state_group_photo:SetState(not_null(self._album_photo) and 0 or 1)
  end
end

function M:_open_big_preview()
  if is_null(self._album_photo) then
    return
  end
  UIManagerInstance:open("UI/Photography/PhotoPreviewDialog", {
    photo_list = {
      self._album_photo
    },
    index = 1,
    mode = photo_module.PreviewMode.AlbumPhoto,
    hide_delete = true
  })
end

function M:_capture_share_photo(on_photo_ready, error_log, on_failed)
  local bind_version = self._view_bind_version or 0
  self:_enqueue_capture_photo_callback(on_photo_ready, on_failed)
  if self._is_capturing_share_photo then
    return
  end
  self._is_capturing_share_photo = true
  self:_set_capture_controls_visible(false)
  MouseManager.BeginCursorCaptureSuppression()
  CsUIUtil.CaptureScreen(function(texture)
    MouseManager.EndCursorCaptureSuppression()
    if not self:_is_async_request_valid(bind_version) then
      return
    end
    self:_set_capture_controls_visible(true)
    if not_null(texture) then
      local photo_id = CsAlbumManagerUtil.GenerateUniquePhotoId()
      local succeed = CsAlbumManagerUtil.SavePhoto(photo_id, texture, function(save_success)
        if not self:_is_async_request_valid(bind_version) then
          if not save_success then
            GameObject.Destroy(texture)
          end
          return
        end
        if not save_success then
          GameObject.Destroy(texture)
          self:_flush_capture_photo_callbacks(nil)
          return
        end
        local photo_data = CsAlbumManagerUtil.GetPhoto(photo_id)
        if not_null(photo_data) then
          self:_flush_capture_photo_callbacks(photo_data)
        else
          self:_flush_capture_photo_callbacks(nil)
        end
      end)
      if not succeed then
        GameObject.Destroy(texture)
        if self:_is_async_request_valid(bind_version) then
          Logger.LogError(error_log)
          self:_flush_capture_photo_callbacks(nil)
        end
      end
    else
      self:_flush_capture_photo_callbacks(nil)
    end
  end)
end

function M:_enqueue_capture_photo_callback(on_photo_ready, on_failed)
  self._capture_photo_callbacks = self._capture_photo_callbacks or {}
  table.insert(self._capture_photo_callbacks, {on_photo_ready = on_photo_ready, on_failed = on_failed})
end

function M:_flush_capture_photo_callbacks(photo_data)
  local callbacks = self._capture_photo_callbacks or {}
  self._capture_photo_callbacks = {}
  self._is_capturing_share_photo = false
  for _, callback_data in ipairs(callbacks) do
    if not_null(photo_data) and callback_data.on_photo_ready then
      callback_data.on_photo_ready(photo_data)
    elseif is_null(photo_data) and callback_data.on_failed then
      callback_data.on_failed()
    end
  end
end

function M:_cancel_capture_photo_callbacks()
  self._capture_photo_callbacks = {}
  self._is_capturing_share_photo = false
end

function M:_set_capture_controls_visible(is_visible)
  UIUtil.set_active(self._btn_list, is_visible)
  UIUtil.set_active(self._btn_save_root, is_visible)
  UIUtil.set_active(self._btn_transport_root, is_visible and photo_module:can_show_face_to_face_share_button())
  if not is_null(self._btn_close) then
    UIUtil.set_active(self._btn_close, is_visible)
  end
end

function M:_get_or_create_share_platform_photo(on_photo_ready)
  local bind_version = self._view_bind_version or 0
  if not_null(self._share_platform_photo) then
    if self:_is_async_request_valid(bind_version) then
      on_photo_ready(self._share_platform_photo)
    end
    return
  end
  self:_capture_share_photo(function(photo_data)
    if not self:_is_async_request_valid(bind_version) then
      return
    end
    self._share_platform_photo = photo_data
    on_photo_ready(photo_data)
  end, "StarBayDiaryShareDialog create platform share photo failed")
end

function M:_refresh_share_platform()
  if is_null(self._btn_list) or is_null(self._share_item_template) then
    return
  end
  for _, item in pairs(self._photo_share_platforms) do
    if item then
      item:set_active(false)
    end
  end
  if self:_is_pc_share_layout() then
    return
  end
  local share_cfg = ExcelDataUtil.get_table(typeof(BPhotoShareCfg)) or {}
  local share_cfg_list = dic_to_list_table(share_cfg) or {}
  table.sort(share_cfg_list, function(a, b)
    if a.datasorting == b.datasorting then
      return a.shareid < b.shareid
    end
    return a.datasorting < b.datasorting
  end)
  for _, cfg in ipairs(share_cfg_list) do
    if photo_module:check_share_channel_enable(cfg) then
      local item = self:_get_platform_item(cfg.shareid)
      item:set_active(true)
      item:refresh(cfg, nil, pack(self, M._on_click_share_platform))
    end
  end
end

function M:_is_pc_share_layout()
  return UIAdaptiveUtils.layoutVersion == LayoutVersion.PC
end

function M:_get_platform_item(share_id)
  local item = self._photo_share_platforms[share_id]
  if item == nil then
    local obj = UIUtil.load_prefab_set_parent(self._share_item_template.gameObject, self._btn_list)
    item = self:add_panel(share_platform_item_cls, obj)
    self._photo_share_platforms[share_id] = item
  end
  return item
end

function M:_on_click_share_platform(share_cfg)
  if share_cfg == nil then
    return
  end
  local bind_version = self._view_bind_version or 0
  self:_get_or_create_share_platform_photo(function(photo_data)
    if not self:_is_async_request_valid(bind_version) then
      return
    end
    share_platform_item.share_photo_to_platform(share_cfg, photo_data, pack(self, M._on_share_platform_notification))
  end)
end

function M:_on_share_platform_notification(result)
  share_platform_item.handle_share_notification(result)
end

function M:_set_save_button_interactable(is_interactable)
  if not is_null(self._btn_save) then
    self._btn_save.interactable = is_interactable == true
  end
end

function M:_reset_save_button_state()
  self._is_saving_to_album = false
  self._is_save_button_locked = false
  self._save_button_unlock_version = (self._save_button_unlock_version or 0) + 1
  self:_set_save_button_interactable(true)
end

function M:_refresh_save_button_cooldown_state()
  local remain_time = get_save_result_tip_cooldown_remain_time()
  if 0 < remain_time then
    self:_start_save_button_cooldown(remain_time, false)
  else
    self:_reset_save_button_state()
  end
end

function M:_start_save_button_cooldown(duration, should_record_global)
  self._is_saving_to_album = false
  self._is_save_button_locked = true
  local unlock_version = (self._save_button_unlock_version or 0) + 1
  self._save_button_unlock_version = unlock_version
  self:_set_save_button_interactable(false)
  if should_record_global ~= false then
    save_result_tip_cooldown_end_time = Time.realtimeSinceStartup + duration
  end
  CsCoroutineManagerUtil.Invoke(duration, function()
    if not (not self._is_close and not is_null(self.game_obj) and self.is_active) or self._save_button_unlock_version ~= unlock_version then
      return
    end
    self:_reset_save_button_state()
  end)
end

function M:_save_to_album()
  if self._is_saving_to_album or self._is_save_button_locked then
    return
  end
  
  local function on_save_failed()
    show_save_result_tip("UI_PhotoAlbum_Save_Error_Tip")
    self:_start_save_button_cooldown(save_result_tip_duration + 0.5)
  end
  
  self._is_saving_to_album = true
  self._is_save_button_locked = true
  self:_set_save_button_interactable(false)
  self:_capture_share_photo(function(photo_data)
    local is_success = CsAlbumManagerUtil.SaveToPhotoAlbum(photo_data)
    if is_success then
      show_save_result_tip("UI_PhotoAlbum_Save_To_Album_Tip")
      self:_start_save_button_cooldown(save_result_tip_duration + 0.5)
    else
      on_save_failed()
    end
  end, "StarBayDiaryShareDialog save screenshot failed", on_save_failed)
end

function M:_share_face_to_face()
  self:_capture_share_photo(function(photo_data)
    photo_module:share_photo_single(photo_data)
  end, "StarBayDiaryShareDialog create album photo for f2f failed")
end

return M
