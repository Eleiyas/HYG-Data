local M = G.Class("WorldEditorBlueprintItem", G.UIBase)
local base = G.UIBase
local CUSTOM_BLUEPRINT_ICON_PATH = "UISprite/Load/Item/Img_Blueprint_CanBa_Player_b"

function M:init()
  base.init(self)
  self._is_pointer_down = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._current_cover_photo = nil
  
  function self._load_cover_cb(success, file_key)
    self:_on_cover_loaded(success, file_key)
  end
end

function M:_add_ui_listener()
  self.binder:BindViewCallback(self.trans, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  self.binder:BindViewCallback(self.trans, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  self.binder:BindViewCallback(self.trans, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  self.binder:BindViewCallback(self.trans, EventTriggerType.Drag, pack(self, M._on_drag))
  self.binder:BindViewCallback(self.trans, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
  self.binder:BindViewCallback(self.trans, EventTriggerType.Scroll, pack(self, M._on_scroll))
end

function M:refresh_view()
  local data = self._extra_data
  local has_data = data ~= nil
  self:set_active(has_data)
  if not has_data then
    return
  end
  if data.category == "official" then
    self:_refresh_official_view(data)
  else
    self:_refresh_custom_view(data)
  end
end

function M:_refresh_official_view(data)
  UIUtil.set_image(self._img_icon, data.tooltableicon, self:get_load_proxy())
  UIUtil.set_text(self._txt_schedule, self:_get_owned_item_percent_text(data.entity_list))
  UIUtil.set_active(self._trans_star_group, false)
end

function M:_refresh_custom_view(data)
  UIUtil.set_text(self._txt_schedule, self:_get_owned_item_percent_text(data.entity_list))
  UIUtil.set_active(self._trans_star_group, false)
  self:_refresh_cover(data)
end

function M:_refresh_cover(data)
  if is_null(self._img_icon) then
    return
  end
  UIUtil.set_image(self._img_icon, CUSTOM_BLUEPRINT_ICON_PATH, self:get_load_proxy())
  local image_key = data.image_key
  if image_key == nil or image_key == "" then
    self._current_cover_photo = nil
    return
  end
  local cover_photo = CsNewBlueprintModuleUtil.GetCoverPhoto(image_key)
  self._current_cover_photo = cover_photo
  if is_null(cover_photo) then
    return
  end
  cover_photo:LoadPhotoThumbnailTextureAsync(self._load_cover_cb)
end

function M:_on_cover_loaded(success, file_key)
  if is_null(self.game_obj) then
    return
  end
  if not success then
    return
  end
  local data = self._extra_data
  if data == nil or is_null(file_key) then
    return
  end
  if data.image_key ~= file_key then
    return
  end
  local cover_photo = self._current_cover_photo
  if is_null(cover_photo) or is_null(cover_photo.photoThumbnailSprite) then
    return
  end
  UIUtil.set_image(self._img_icon, cover_photo.photoThumbnailSprite, self:get_load_proxy())
end

function M:_get_owned_item_percent_text(entity_list)
  local required_count_map = {}
  local total_count = 0
  if entity_list then
    for i = 0, entity_list.Count - 1 do
      local entity_data = entity_list[i]
      local config_id = entity_data and entity_data.ConfigId or 0
      if config_id and 0 < config_id then
        required_count_map[config_id] = (required_count_map[config_id] or 0) + 1
        total_count = total_count + 1
      end
    end
  end
  if total_count <= 0 then
    return TextMapFormatUtil.FormatPercentFloor(0, 0)
  end
  local owned_count = 0
  for config_id, required_count in pairs(required_count_map) do
    local item_count = self.holder:get_blueprint_owned_count(config_id)
    owned_count = owned_count + math.min(item_count, required_count)
  end
  return TextMapFormatUtil.FormatPercentFloor(owned_count / total_count, 0)
end

function M:_has_invalid_config(entity_list)
  if not entity_list then
    return false
  end
  local checked = {}
  for i = 0, entity_list.Count - 1 do
    local entity_data = entity_list[i]
    local config_id = entity_data and entity_data.ConfigId or 0
    if config_id and 0 < config_id and not checked[config_id] then
      checked[config_id] = true
      if not self.holder:check_config_id_valid(config_id) then
        return true
      end
    end
  end
  return false
end

function M:_refresh_stars(star_count)
  if is_null(self._trans_star_group) then
    return
  end
  for i = 0, self._trans_star_group.childCount - 1 do
    local child = self._trans_star_group:GetChild(i)
    child.gameObject:SetActive(i < star_count)
  end
end

function M:_on_pointer_down(evt)
  if evt.button ~= 0 then
    return
  end
  if self._is_pointer_down then
    self:_on_pointer_up(evt)
  end
  self._is_dragging = false
  self._is_pointer_down = true
  self._create_new_entity = false
end

function M:_on_begin_drag(evt)
  if evt.button ~= 0 then
    return
  end
  self._is_dragging = true
  self.holder:on_blueprint_item_begin_drag(evt)
end

function M:_on_drag(evt)
  if evt.button ~= 0 then
    return
  end
  if not self._create_new_entity then
    self.holder:on_blueprint_item_drag(evt)
    local check_area = self.holder:get_check_blueprint_drag_area_trans()
    if not RectTransformUtility.RectangleContainsScreenPoint(check_area, evt.position, UIManagerInstance.ui_camera) then
      self._create_new_entity = true
      self:_begin_batch_hold(nil)
      AudioManagerIns:post_event_by_cfg(UEvent.Furniture_PickUp)
      self.holder:on_blueprint_item_end_drag(evt)
    end
  end
end

function M:_on_pointer_up(evt)
  if evt.button ~= 0 then
    return
  end
  self._is_pointer_down = false
  if not self._create_new_entity and evt.button == 0 and not self._is_dragging then
    local cam = CsGameplayUtilitiesCameraUtil.GetMainCamera()
    local ray = cam:ViewportPointToRay(Vector3(0.5, 0.5, 0))
    if self:_begin_batch_hold(ray) then
      local handler = RuntimeWorldEditor.Current.eicEntityEditHandler
      handler.editCtrl:EndMultiHold(cam, ray)
      if handler.editCtrl:CanApplyMultiHold() then
        handler.editCtrl:ApplyMultiHold()
      end
    end
  end
end

function M:_begin_batch_hold(ray)
  local data = self._extra_data
  if not data then
    return false
  end
  if self:_has_invalid_config(data.entity_list) then
    UIUtil.show_tips(UIUtil.get_text_by_id("WorldEditor_Blueprint_HasInvalidEntity"))
  end
  local handler = RuntimeWorldEditor.Current.eicEntityEditHandler
  local is_official = data.category == "official"
  local began = false
  if is_official then
    if not data.jsondata or data.jsondata == "" then
      return false
    end
    began = handler.editCtrl:BeginBatchHoldFromJson(data.jsondata, ray)
  else
    local ok, bp_data
    if data.category == "copied" then
      ok, bp_data = CsNewBlueprintModuleUtil.TryGetCopiedBlueprintData(data.bp_guid)
    else
      ok, bp_data = CsNewBlueprintModuleUtil.TryGetNewBlueprintData(data.bp_guid)
    end
    if not ok or not bp_data then
      UIUtil.show_tips(UIUtil.get_text_by_id("WorldEditor_Blueprint_DataNotReady"))
      return false
    end
    began = handler.editCtrl:BeginBatchHold(bp_data.EntityList, ray)
  end
  if began then
    local key = is_official and (data.blueprint_id or 0) or data.bp_guid or 0
    local fields = new_blueprint_module:build_blueprint_report_fields_by_entities(is_official, key, data.entity_list)
    fields.access_method = new_blueprint_module.blueprint_use_access.furnish
    CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.new_blueprint_use, "NewBlueprintUse", fields)
  end
  return began
end

function M:_on_end_drag(evt)
  if evt.button ~= 0 then
    return
  end
  if not self._create_new_entity then
    self.holder:on_blueprint_item_end_drag(evt)
  end
end

function M:_on_scroll(evt)
  self.holder:on_blueprint_item_scroll(evt)
end

return M
