local M = G.Class("BlueprintSaveDataDialog", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintSaveDataDialog"
  self.config.type = EUIType.Dialog
  self._blueprint_name = ""
  self._cover_photo_guid = 0
  self._saving = false
  self._item_panels = {}
  self._img_cover = nil
  self._btn_change_cover = nil
  self._list_item = nil
  self._btn_set_name = nil
  self._ui_state_group = nil
  self._btn_change_name = nil
  self._txt_blueprint_name = nil
  self._btn_confim = nil
  self._btn_close_popup = nil
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.WorldEdit.LuaUI.NewBlueprintStoreResult, pack(self, M._on_store_result))
end

function M:on_enable()
  base.on_enable(self)
  self._blueprint_name = self._extra_data and self._extra_data.name or ""
  self._cover_photo_guid = self._extra_data and self._extra_data.cover_guid or 0
  self._saving = false
  self._going_to_shot_page = false
  self:_refresh_item_list()
  self:_refresh_cover()
  self:_refresh_name_view()
end

function M:on_disable()
  base.on_disable(self)
  if not self._going_to_shot_page and self._cover_photo_guid and self._cover_photo_guid > 0 then
    CsCameraManagerUtil.DiscardPhotoTexture(self._cover_photo_guid)
    self._cover_photo_guid = 0
  end
  if not self._going_to_shot_page then
    CsNewBlueprintModuleUtil.SetRuntimeCoverStageActive(true)
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close_popup)
  if not_null(self._btn_confim) then
    self:bind_callback(self._btn_confim, pack(self, M._on_btn_confirm))
  end
  if not_null(self._btn_set_name) then
    self:bind_callback(self._btn_set_name, pack(self, M._on_btn_edit_name))
  end
  if not_null(self._btn_change_name) then
    self:bind_callback(self._btn_change_name, pack(self, M._on_btn_edit_name))
  end
  if not_null(self._btn_change_cover) then
    self:bind_callback(self._btn_change_cover, pack(self, M._on_btn_change_cover))
  end
end

function M:_refresh_item_list()
  if is_null(self._list_item) then
    return
  end
  local items = CsNewBlueprintModuleUtil.GetRuntimeMultiSelectedBlueprintItems()
  local count = items and items.Count or 0
  for slot = 1, count do
    local data = items[slot - 1]
    local panel = self._item_panels[slot]
    if panel == nil then
      local obj = self._list_item:AddItem(0)
      if not is_null(obj) then
        panel = self:add_panel(item_v2_cls, obj)
        self._item_panels[slot] = panel
      end
    end
    if panel ~= nil then
      panel:set_active(true)
      panel:set_item_data(data.x, data.y)
      panel:bind_item_info_btn(data.x)
    end
  end
  for i = count + 1, #self._item_panels do
    local panel = self._item_panels[i]
    if panel ~= nil then
      panel:set_active(false)
    end
  end
end

function M:_refresh_cover()
  if is_null(self._img_cover) then
    return
  end
  if self._cover_photo_guid and self._cover_photo_guid > 0 then
    local sprite = CsCameraManagerUtil.GetPhoto(self._cover_photo_guid)
    if not_null(sprite) then
      self._img_cover.sprite = sprite
    end
  end
end

function M:_refresh_name_view()
  local has_name = self._blueprint_name ~= nil and self._blueprint_name ~= ""
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(has_name and 1 or 0)
  end
  if not_null(self._txt_blueprint_name) then
    UIUtil.set_text(self._txt_blueprint_name, has_name and self._blueprint_name or UIUtil.get_text_by_id("Blueprint_UI_016"))
  end
end

function M:_on_btn_edit_name()
  local edit_data = {
    title = UIUtil.get_text_by_id("Blueprint_UI_017"),
    confirm_callback = pack(self, M._on_name_confirmed),
    confirm_btn_text = UIUtil.get_text_by_id("Common_Yes"),
    init_input_txt = self._blueprint_name or "",
    max_char_limit = 20
  }
  common_ui_module:show_name_edit_dialog(edit_data)
end

function M:_on_name_confirmed(new_name)
  self._blueprint_name = new_name or ""
  self:_refresh_name_view()
end

function M:_on_btn_change_cover()
  self._going_to_shot_page = true
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintShotCoverPage", {
    name = self._blueprint_name,
    cover_guid = self._cover_photo_guid
  })
  self:close_self()
end

function M:_on_btn_confirm()
  if self._blueprint_name == nil or self._blueprint_name == "" then
    UIUtil.show_tips_by_text_id("Blueprint_UI_018")
    return
  end
  if self._saving then
    return
  end
  self._saving = true
  if self._cover_photo_guid and self._cover_photo_guid > 0 then
    CsAlbumManagerUtil.UploadCameraPhotoAsCover(self._cover_photo_guid, function(ok, file_key)
      if ok and file_key and file_key ~= "" then
        self:_do_store(file_key)
      else
        self._saving = false
        UIUtil.show_tips(UIUtil.get_text_by_id("WorldEditor_SaveBlueprint_Fail"))
      end
    end)
  else
    self:_do_store("")
  end
end

function M:_do_store(image_key)
  local dispatched = CsNewBlueprintModuleUtil.StoreRuntimeMultiSelectedAsNewBlueprint(self._blueprint_name, image_key or "")
  if not dispatched then
    self._saving = false
    UIUtil.show_tips(UIUtil.get_text_by_id("WorldEditor_SaveBlueprint_Fail"))
  end
end

function M:_on_store_result(success)
  if not self._saving then
    return
  end
  self._saving = false
  if success then
    UIUtil.show_tips(UIUtil.get_text_by_id("WorldEditor_SaveBlueprint_Success"))
    self:close_self()
  end
end

return M
