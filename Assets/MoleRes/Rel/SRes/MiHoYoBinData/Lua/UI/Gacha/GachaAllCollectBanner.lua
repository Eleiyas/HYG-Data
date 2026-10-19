local M = G.Class("GachaAllCollectBanner", G.UIWindow)
local base = G.UIWindow
local share_platform_item_cls = "UI/Share/SharePlatformItem"
local share_platform_item = require(share_platform_item_cls)
local LayoutVersion = CS.miHoYo.HYG.UI.LayoutVersion
local UIAdaptiveUtils = CS.miHoYo.HYG.UI.UIAdaptiveUtils
local save_result_tip_duration = 1.0
local save_result_tip_cooldown_end_time = 0

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
  self.config.prefab_path = GachaConst.panel_path.all_collect_banner
  self.config.type = EUIType.Dialog
  self._gacha_id = 0
  self._all_collect_reward_items = {}
  self._photo_share_platforms = {}
  self._is_close = false
  self._view_bind_version = 0
  self._share_platform_photo = nil
  self._is_saving_to_album = false
  self._is_save_button_locked = false
  self._save_button_unlock_version = 0
  self._is_capturing_share_photo = false
  self._capture_photo_callbacks = {}
  self._on_click_share_platform = pack(self, M._on_click_share_platform)
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
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
  self._gacha_id = self._extra_data.gacha_id
  self._is_close = false
  self._share_platform_photo = nil
  self:_refresh_save_button_cooldown_state()
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
  self._all_collect_reward_items = nil
  self:_set_capture_controls_visible(true)
  self:_cancel_capture_photo_callbacks()
  self._is_close = true
  self._share_platform_photo = nil
  base.on_destroy(self)
end

function M:_refresh_view()
  self:_advance_view_bind_version()
  local activity_cfg = gacha_module:get_activity_cfg(self._gacha_id)
  if activity_cfg == nil then
    return
  end
  UIUtil.set_text(self._txt_name, activity_cfg.name)
  UIUtil.set_image(self._img_photo, activity_cfg.allcollectrewardpic, self:get_load_proxy())
  local is_show_all_collect_reward = gacha_module:is_t0_cloth_pool(activity_cfg)
  local reward = is_show_all_collect_reward and gacha_module:get_all_collect_reward_list(activity_cfg.allcollectrewardpoolid) or nil
  local item_count = reward and #reward or 0
  UIUtil.set_active(self._set_effects_panel, 0 < item_count)
  if item_count <= 0 then
    return
  end
  local max_count = math.max(item_count, #self._all_collect_reward_items)
  for i = 1, max_count do
    local item = self._all_collect_reward_items[i]
    if i <= item_count then
      item = self:_refresh_all_collect_reward_item(item, reward[i])
      self._all_collect_reward_items[i] = item
      item:set_active(true)
    elseif item then
      item:set_active(false)
    end
  end
end

function M:_refresh_all_collect_reward_item(cls, collect_cfg)
  if cls == nil then
    local obj = self._obj_cloth_reward:AddItem(0)
    cls = self:add_panel(GachaConst.item_path.all_collect_reward, obj)
  end
  cls:refresh(collect_cfg, true)
  return cls
end

function M:_advance_view_bind_version()
  self._view_bind_version = (self._view_bind_version or 0) + 1
  return self._view_bind_version
end

function M:_is_async_request_valid(bind_version)
  return not self._is_close and not is_null(self.game_obj) and self.is_active and self._view_bind_version == bind_version
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

function M:_capture_share_photo(on_photo_ready, error_log, on_failed)
  local bind_version = self._view_bind_version or 0
  self:_enqueue_capture_photo_callback(on_photo_ready, on_failed)
  if self._is_capturing_share_photo then
    return
  end
  self._is_capturing_share_photo = true
  self:_set_capture_controls_visible(false)
  CsUIUtil.CaptureScreen(function(texture)
    if not self:_is_async_request_valid(bind_version) then
      self:_cancel_capture_photo_callbacks()
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
          self:_cancel_capture_photo_callbacks()
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
  UIUtil.set_active(self._btn_close, is_visible)
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
  end, "GachaAllCollectBanner create platform share photo failed")
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
      item:refresh(cfg, nil, self._on_click_share_platform)
    end
  end
end

function M:_is_pc_share_layout()
  return UIAdaptiveUtils.layoutVersion == LayoutVersion.PC
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
  end, "GachaAllCollectBanner save screenshot failed", on_save_failed)
end

function M:_share_face_to_face()
  self:_capture_share_photo(function(photo_data)
    photo_module:share_photo_single(photo_data)
  end, "GachaAllCollectBanner create album photo for f2f failed", function()
    show_save_result_tip("UI_PhotoAlbum_Save_Error_Tip")
  end)
end

return M
