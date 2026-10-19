local M = G.Class("LittleCornerMyInfoCardSelectPage", G.UIWindow)
local base = G.UIWindow
local item_cls = "UI/LittleCorner/LittleCornerMyInfoCardSelectItem"
local id_card_bg_cls = "UI/LittleCorner/LittleCornerIdCardBg"
local preview_state = little_corner_module.bg_preview_state
local apply_state = {
  applied = 0,
  can_apply = 1,
  locked = 2
}
local item_state = little_corner_module.card_item_state

local function _set_aspect_ratio(fitter, sprite)
  if not_null(fitter) and not_null(sprite) and sprite.rect.height > 0 then
    fitter.aspectRatio = sprite.rect.width / sprite.rect.height
  end
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerMyInfoCardSelectPage"
  self.config.type = EUIType.Dialog
  self._entries = {}
  self._item_panels = {}
  self._selected_index = 0
  self._user_selected = false
  self._picked_custom_photo = nil
  self._id_card_bg = nil
  self._preview_pic_key = nil
  self._held_bg_key = nil
  self._txt_name = nil
  self._txt_lv = nil
  self._trans_lv = nil
  self._txt_thumb_num = nil
  self._txt_post_num = nil
  self._txt_follow_num = nil
  self._txt_follower_num = nil
  self._img_head = nil
  self._btn_close_normal = nil
  self._list_item = nil
  self._ui_state_img = nil
  self._img_pic_custom = nil
  self._img_pic_custom_ratio = nil
  self._img_pic_preset = nil
  self._btn_change_custom = nil
  self._ui_state_apply = nil
  self._btn_confirm = nil
  self._trans_id_card_bg = nil
  self._txt_id_card_name = nil
  self._trans_change_pic = nil
  self._trans_upload_pic = nil
  self._btn_upload = nil
  self._txt_unlock_condition = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close_normal, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_change_custom, pack(self, M._on_btn_change_custom))
  self:bind_callback(self._btn_upload, pack(self, M._on_btn_change_custom))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm))
  self._id_card_bg = self:add_panel(id_card_bg_cls, self._trans_id_card_bg)
end

function M:on_open()
  base.on_open(self)
  self._picked_custom_photo = nil
  self._user_selected = false
  local extra = self:get_extra_data()
  self._close_callback = extra and extra.close_callback or nil
  self:_build_entries()
  CsLittleCornerModuleUtil.GetXhsProfileSettings()
end

function M:on_close()
  base.on_close(self)
  if self._close_callback then
    local close_callback = self._close_callback
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      close_callback()
    end)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_self_info()
  self:_refresh_list()
  self:_select_default_entry()
end

function M:on_destroy()
  base.on_destroy(self)
  self._preview_pic_key = nil
  self:_release_held_bg()
end

function M:_release_held_bg()
  if self._held_bg_key then
    little_corner_module:release_profile_bg_photo(self._held_bg_key)
    self._held_bg_key = nil
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsHomepageBgUpdated, pack(self, M._on_homepage_bg_updated))
  self:add_evt_listener(EventID.OnXhsCreatorLevelUpdated, pack(self, M._on_creator_level_updated))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_normal)
end

function M:_on_btn_close()
  self:close_self()
end

function M:_on_btn_change_custom()
  if not little_corner_module:is_custom_homepage_bg_unlocked() then
    return
  end
  if CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchClosePhotoAlbum) then
    CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
    return
  end
  local extra_data = {
    is_single_select_mode = true,
    single_select_callback = pack(self, M._on_custom_photo_selected),
    close_callback = pack(self, M._on_photo_dialog_closed)
  }
  UIManagerInstance:open("UI/LittleCorner/LittleCornerSelectPhotoDialog", extra_data)
end

function M:_on_custom_photo_selected(photo_data)
  if is_null(photo_data) then
    return
  end
  self._picked_custom_photo = photo_data
  local custom_index = self:_get_custom_entry_index()
  if 0 < custom_index then
    self:_select_entry(custom_index)
  end
end

function M:_on_photo_dialog_closed()
  if is_null(self) then
    return
  end
  self._preview_pic_key = nil
  self:_release_held_bg()
  if self._id_card_bg ~= nil then
    self._id_card_bg:reset_bg()
  end
  local entry = self._entries[self._selected_index]
  if entry ~= nil then
    self:_refresh_preview(entry)
  end
end

function M:_on_btn_confirm()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  local entry = self._entries[self._selected_index]
  if entry == nil then
    return
  end
  if not self:_is_entry_unlocked(entry) then
    return
  end
  if entry.is_custom then
    if is_null(self._picked_custom_photo) then
      return
    end
    CsAlbumManagerUtil.UploadPhotoForLittleCornerPost({
      self._picked_custom_photo
    }, function(success, photo_file_keys)
      if is_null(self) then
        return
      end
      if success then
        local keys = list_to_table(photo_file_keys)
        local pic_key = keys[1]
        if pic_key and pic_key ~= "" then
          CsLittleCornerModuleUtil.SetXhsHomepageBg(0, pic_key)
        end
      else
        UIUtil.show_tips_by_text_id("Xhs_UI_Text27")
        Logger.LogWarning("[LittleCorner] Failed to upload custom homepage bg photo")
      end
    end)
  else
    if self:_is_entry_applied(entry) then
      return
    end
    CsLittleCornerModuleUtil.SetXhsHomepageBg(entry.bg_id, "")
  end
end

function M:_on_homepage_bg_updated(arg)
  self._picked_custom_photo = nil
  self:_refresh_after_data_change()
end

function M:_on_creator_level_updated(arg)
  self:_refresh_after_data_change()
end

function M:_refresh_after_data_change()
  self:_refresh_list()
  if not self._user_selected then
    self:_select_default_entry()
  else
    self:_refresh_apply_state()
  end
end

function M:_refresh_self_info()
  UIUtil.set_text(self._txt_name, player_module:get_player_name())
  UIUtil.set_text_by_id(self._txt_lv, "LittleCorner_UI_010", CsLittleCornerModuleUtil.CreatorLevel)
  local server_data = player_module:get_player_data().playerServerData
  local avatar_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), server_data.AvatarID)
  if avatar_cfg and avatar_cfg.respath then
    UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
  end
  if CsLittleCornerModuleUtil.HasMyProfile then
    UIUtil.set_text(self._txt_thumb_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyTotalLikes))
    UIUtil.set_text(self._txt_post_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyPostCount))
    UIUtil.set_text(self._txt_follow_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyFollowingCount))
    UIUtil.set_text(self._txt_follower_num, TextMapFormatUtil.FormatAbbreviation(CsLittleCornerModuleUtil.MyFollowerCount))
  end
end

function M:_build_entries()
  self._entries = {}
  local cfgs = little_corner_module:get_homepage_bg_cfgs()
  for _, cfg in ipairs(cfgs) do
    table.insert(self._entries, {
      is_custom = false,
      cfg = cfg,
      bg_id = cfg.id
    })
  end
  table.insert(self._entries, {
    is_custom = true,
    cfg = nil,
    bg_id = 0
  })
end

function M:_refresh_list()
  local total = #self._entries
  for i, entry in ipairs(self._entries) do
    local panel = self._item_panels[i]
    if panel == nil then
      local obj = self._list_item:AddItem(0)
      panel = self:add_panel(item_cls, obj)
      self._item_panels[i] = panel
      local index = i
      panel:set_selected_callback(function()
        self:_on_user_select(index)
      end)
    end
    panel:refresh(entry, self:_compute_item_state(entry))
    panel:set_active(true)
  end
  for i = total + 1, #self._item_panels do
    self._item_panels[i]:set_active(false)
  end
end

function M:_select_default_entry()
  local applied_index = self:_get_applied_entry_index()
  self:_select_entry(0 < applied_index and applied_index or 1)
end

function M:_on_user_select(index)
  self._user_selected = true
  self:_select_entry(index)
end

function M:_select_entry(index)
  local entry = self._entries[index]
  if entry == nil then
    return
  end
  self._selected_index = index
  for i, panel in pairs(self._item_panels) do
    panel:set_selected(i == index)
  end
  self:_refresh_preview(entry)
  self:_refresh_apply_state()
end

function M:_refresh_preview(entry)
  if entry.is_custom then
    self:_refresh_custom_preview()
  else
    self._preview_pic_key = nil
    self:_release_held_bg()
    self._ui_state_img:SetState(preview_state.preset)
    UIUtil.set_image(self._img_pic_preset, entry.cfg.path1, self:get_load_proxy())
    UIUtil.set_text(self._txt_id_card_name, entry.cfg.name)
    if self._id_card_bg ~= nil then
      self._id_card_bg:show_preset(entry.cfg)
    end
    local unlocked = little_corner_module:is_preset_homepage_bg_unlocked(entry.cfg)
    self:_set_affordance_active(false, false, not unlocked)
    if not unlocked then
      local unlock_level = little_corner_module:get_preset_homepage_bg_unlock_level(entry.cfg)
      UIUtil.set_text_by_id(self._txt_unlock_condition, "LittleCorner_UI_013", unlock_level)
    end
  end
end

function M:_refresh_custom_preview()
  self._ui_state_img:SetState(preview_state.custom)
  UIUtil.set_text_by_id(self._txt_id_card_name, "Xhs_UI_Text29")
  local unlocked = little_corner_module:is_custom_homepage_bg_unlocked()
  local applied_custom_key = CsLittleCornerModuleUtil.DisplayHomepageCustomPicKey or ""
  local has_custom_set = applied_custom_key ~= ""
  local has_picked = not is_null(self._picked_custom_photo)
  if not unlocked then
    self._preview_pic_key = nil
    self:_release_held_bg()
    self:_show_custom_default_bg()
    self:_set_affordance_active(false, false, true)
    local unlock_level = little_corner_module:get_custom_homepage_bg_unlock_level()
    UIUtil.set_text_by_id(self._txt_unlock_condition, "LittleCorner_UI_013", unlock_level)
    return
  end
  if has_picked then
    self._preview_pic_key = nil
    self:_release_held_bg()
    self:_show_custom_picked_photo()
  elseif has_custom_set then
    self:_show_custom_applied_bg(applied_custom_key)
  else
    self:_show_custom_unset_default()
  end
  self:_set_affordance_active(has_custom_set, not has_custom_set, false)
end

function M:_show_custom_applied_bg(custom_key)
  if self._id_card_bg ~= nil then
    self._id_card_bg:show_custom_by_key(custom_key)
  end
  self._preview_pic_key = custom_key
  if not string.is_valid(custom_key) then
    self:_release_held_bg()
    return
  end
  if self._held_bg_key ~= custom_key then
    self:_release_held_bg()
    self._held_bg_key = custom_key
    little_corner_module:acquire_profile_bg_photo(custom_key, function(success, photo_data)
      if is_null(self._img_pic_custom) or self._preview_pic_key ~= custom_key then
        return
      end
      if not success or is_null(photo_data) then
        return
      end
      photo_data:LoadPhotoTextureAsync(function(has_tex)
        if is_null(self._img_pic_custom) or self._preview_pic_key ~= custom_key or is_null(photo_data.photoSprite) then
          return
        end
        self._img_pic_custom.sprite = photo_data.photoSprite
        _set_aspect_ratio(self._img_pic_custom_ratio, photo_data.photoSprite)
      end)
    end)
  end
end

function M:_show_custom_default_bg()
  local default_cfg = little_corner_module:get_homepage_bg_cfg(little_corner_module.default_homepage_bg_id)
  if default_cfg == nil then
    return
  end
  if not_null(self._img_pic_custom) then
    UIUtil.set_image(self._img_pic_custom, default_cfg.path1, self:get_load_proxy())
  end
  if self._id_card_bg ~= nil then
    self._id_card_bg:show_preset(default_cfg)
  end
end

function M:_show_custom_unset_default()
  self._preview_pic_key = nil
  self:_release_held_bg()
  self._ui_state_img:SetState(preview_state.preset)
  local default_cfg = little_corner_module:get_homepage_bg_cfg(little_corner_module.default_homepage_bg_id)
  if default_cfg == nil then
    return
  end
  if not_null(self._img_pic_preset) then
    UIUtil.set_image(self._img_pic_preset, default_cfg.path1, self:get_load_proxy())
  end
  if self._id_card_bg ~= nil then
    self._id_card_bg:show_preset(default_cfg)
  end
end

function M:_show_custom_picked_photo()
  local picked = self._picked_custom_photo
  if is_null(picked) then
    return
  end
  local photo_id = picked.photoId
  local photo_data = CsAlbumManagerUtil.GetPhoto(photo_id)
  if is_null(photo_data) then
    return
  end
  photo_data:LoadPhotoTextureAsync(function(has_tex)
    if is_null(self._img_pic_custom) or is_null(self._picked_custom_photo) or self._picked_custom_photo.photoId ~= photo_id then
      return
    end
    if not has_tex or is_null(photo_data.photoSprite) then
      Logger.LogWarning("[LittleCorner] Load custom bg photo failed with photo id: " .. tostring(photo_id))
      return
    end
    UIUtil.set_image(self._img_pic_custom, photo_data.photoSprite, self:get_load_proxy())
    _set_aspect_ratio(self._img_pic_custom_ratio, photo_data.photoSprite)
    if self._id_card_bg ~= nil then
      local card_sprite = not_null(photo_data.photoThumbnailSprite) and photo_data.photoThumbnailSprite or photo_data.photoSprite
      self._id_card_bg:show_custom(card_sprite)
    end
  end)
end

function M:_set_affordance_active(show_change, show_upload, show_unlock_cond)
  if not_null(self._trans_change_pic) then
    UIUtil.set_active(self._trans_change_pic, show_change)
  end
  if not_null(self._trans_upload_pic) then
    UIUtil.set_active(self._trans_upload_pic, show_upload)
  end
  if not_null(self._txt_unlock_condition) then
    UIUtil.set_active(self._txt_unlock_condition, show_unlock_cond)
  end
end

function M:_refresh_apply_state()
  local entry = self._entries[self._selected_index]
  if entry == nil then
    return
  end
  local state
  local confirm_enabled = true
  if not self:_is_entry_unlocked(entry) then
    state = apply_state.locked
    confirm_enabled = false
  elseif entry.is_custom and not is_null(self._picked_custom_photo) then
    state = apply_state.can_apply
  elseif self:_is_entry_applied(entry) then
    state = apply_state.applied
    confirm_enabled = false
  elseif entry.is_custom then
    state = apply_state.can_apply
    confirm_enabled = false
  else
    state = apply_state.can_apply
  end
  self._ui_state_apply:SetState(state)
  self._btn_confirm.interactable = confirm_enabled
end

function M:_is_entry_unlocked(entry)
  if entry.is_custom then
    return little_corner_module:is_custom_homepage_bg_unlocked()
  end
  return little_corner_module:is_preset_homepage_bg_unlocked(entry.cfg)
end

function M:_is_entry_applied(entry)
  local custom_key = CsLittleCornerModuleUtil.DisplayHomepageCustomPicKey or ""
  if entry.is_custom then
    return custom_key ~= ""
  end
  if custom_key ~= "" then
    return false
  end
  local applied_preset_id = CsLittleCornerModuleUtil.HomepagePresetBgId
  if applied_preset_id == 0 then
    applied_preset_id = little_corner_module.default_homepage_bg_id
  end
  return entry.bg_id == applied_preset_id
end

function M:_compute_item_state(entry)
  if not self:_is_entry_unlocked(entry) then
    return entry.is_custom and item_state.custom_locked or item_state.locked
  end
  if self:_is_entry_applied(entry) then
    return entry.is_custom and item_state.custom_applied or item_state.applied
  end
  return entry.is_custom and item_state.custom or item_state.normal
end

function M:_get_custom_entry_index()
  for i, entry in ipairs(self._entries) do
    if entry.is_custom then
      return i
    end
  end
  return 0
end

function M:_get_applied_entry_index()
  for i, entry in ipairs(self._entries) do
    if self:_is_entry_applied(entry) then
      return i
    end
  end
  return 0
end

return M
