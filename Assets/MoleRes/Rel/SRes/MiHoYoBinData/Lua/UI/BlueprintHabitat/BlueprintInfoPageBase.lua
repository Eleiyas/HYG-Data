local M = G.Class("BlueprintInfoPageBase", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintInfoPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_BlueprintHabitat"
  self._cur_key = 0
  self._item_panels = {}
  self._preview_helper = nil
  self._sorted_list = nil
  self._cur_index = 0
  self._place_own_state = nil
  self._txt_name = nil
  self._txt_gird_num = nil
  self._list_blueprint_item = nil
  self._trans_drag = nil
  self._btn_back = nil
  self._btn_place = nil
  self._tog_target = nil
  self._btn_arrow_left = nil
  self._btn_arrow_right = nil
  self._ui_state_group_progress = nil
  self._txt_need_progress = nil
  self._ui_state_group_type = nil
  self._txt_creator_name = nil
  self._img_creator_head = nil
  self._txt_create_time = nil
  self._txt_code = nil
  self._btn_copy_code = nil
end

function M:on_create()
  base.on_create(self)
  self._view_root = UIUtil.find_trans(self.ui_scene_obj, "Art/ModelPos/pos")
  self._follow_trans = UIUtil.find_trans(self.ui_scene_obj, "Art/Content/CameraWrap/StarExploreSettlementFollow0")
  self._default_follow_pos = self._follow_trans and self._follow_trans.localPosition or Vector3.zero
  self._look_at_trans = UIUtil.find_trans(self.ui_scene_obj, "Art/Content/CameraWrap/StarExploreSettlementLookAt0")
  self._default_look_at_pos = self._look_at_trans and self._look_at_trans.localPosition or Vector3.zero
  self:_bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
  self._cur_key = self:_read_key_from_extra(self._extra_data)
  self._sorted_list = self:_get_sorted_list()
  self._cur_index = self:_find_index_by_key(self._cur_key)
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
  self:_destroy_preview()
end

function M:on_before_close()
  base.on_before_close(self)
  UIUtil.set_active(self.ui_scene_obj, false)
  self:_destroy_preview()
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_back)
  if not_null(self._trans_drag) then
    self.binder:BindViewCallback(self._trans_drag, EventTriggerType.Drag, pack(self, M._on_drag))
  end
  if not_null(self._btn_place) then
    self:bind_callback(self._btn_place, pack(self, M._on_btn_place_click))
  end
  if not_null(self._btn_arrow_left) then
    self:bind_callback(self._btn_arrow_left, pack(self, M._on_arrow_left))
  end
  if not_null(self._btn_arrow_right) then
    self:bind_callback(self._btn_arrow_right, pack(self, M._on_arrow_right))
  end
  if not_null(self._tog_target) then
    self:bind_callback(self._tog_target, pack(self, M._on_tog_target))
  end
  if not_null(self._btn_copy_code) then
    self:bind_callback(self._btn_copy_code, pack(self, M._on_btn_copy_code_click))
  end
  self:_bind_extra_callbacks()
end

function M:_refresh_view()
  if not_null(self._ui_state_group_type) then
    self._ui_state_group_type:SetState(self:_type_state())
  end
  if not self:_is_valid_key(self._cur_key) then
    return
  end
  self:_refresh_title_and_extra()
  self:_refresh_time_and_code()
  local aabb = self:_query_aabb(self._cur_key)
  UIUtil.set_text(self._txt_gird_num, string.format("%.1f x %.1f", aabb.x, aabb.y))
  self:_refresh_arrows()
  self:_refresh_item_list()
  self:_refresh_target_toggle()
  self:_refresh_creator_card()
  self:_refresh_preview()
end

function M:_refresh_item_list()
  if is_null(self._list_blueprint_item) then
    return
  end
  local items = self:_query_items(self._cur_key)
  local count = items and items.Count or 0
  local unmet = {}
  local met = {}
  local total_need = 0
  local owned_capped = 0
  for index = 1, count do
    local data = items[index - 1]
    local entry = {
      cfg_id = data.x,
      need = data.y
    }
    entry.owned = item_module:get_item_total_num_by_cfg_id(entry.cfg_id) or 0
    total_need = total_need + entry.need
    owned_capped = owned_capped + math.min(entry.owned, entry.need)
    local group = entry.owned < entry.need and unmet or met
    group[#group + 1] = entry
  end
  local ordered = unmet
  for i = 1, #met do
    ordered[#ordered + 1] = met[i]
  end
  for slot = 1, #ordered do
    local entry = ordered[slot]
    local panel = self._item_panels[slot]
    if panel == nil then
      local obj = self._list_blueprint_item:AddItem(0)
      if not is_null(obj) then
        panel = self:add_panel(item_v2_cls, obj)
        self._item_panels[slot] = panel
      end
    end
    if panel ~= nil then
      panel:set_active(true)
      panel:set_item_data(entry.cfg_id, nil)
      panel:set_num_required(entry.owned, entry.need, item_module.EMarkWarning.WhenInsufficient)
      panel:bind_item_info_btn(entry.cfg_id)
    end
  end
  for i = #ordered + 1, #self._item_panels do
    local panel = self._item_panels[i]
    if panel ~= nil then
      panel:set_active(false)
    end
  end
  local ratio = 0 < total_need and owned_capped / total_need or 0
  UIUtil.set_text(self._txt_need_progress, TextMapFormatUtil.FormatPercentFloor(ratio, 0))
  if not_null(self._ui_state_group_progress) then
    local placeable = self:_query_placeable(self._cur_key)
    self._ui_state_group_progress:SetState(0 < placeable and 1 or 2)
  end
end

function M:_find_index_by_key(key)
  if self._sorted_list then
    for i = 1, #self._sorted_list do
      if self:_key_of(self._sorted_list[i]) == key then
        return i
      end
    end
  end
  return 0
end

function M:_cur_entry()
  if self._sorted_list and self._cur_index >= 1 and self._cur_index <= #self._sorted_list then
    return self._sorted_list[self._cur_index]
  end
  return nil
end

function M:_switch_blueprint(delta)
  if not self._sorted_list then
    return
  end
  local target = self._cur_index + delta
  if target < 1 or target > #self._sorted_list then
    return
  end
  self._cur_index = target
  self._cur_key = self:_key_of(self._sorted_list[target])
  self:_refresh_view()
end

function M:_on_arrow_left()
  self:_switch_blueprint(-1)
end

function M:_on_arrow_right()
  self:_switch_blueprint(1)
end

function M:_refresh_arrows()
  local count = self._sorted_list and #self._sorted_list or 0
  UIUtil.set_active(self._btn_arrow_left, self._cur_index > 1)
  UIUtil.set_active(self._btn_arrow_right, count > self._cur_index)
end

function M:_refresh_preview()
  self:_destroy_preview()
  if is_null(self._view_root) then
    return
  end
  self._preview_helper = self:_create_preview(self._cur_key, self._view_root.position, self:_preview_rotate())
  self:_apply_preview_framing(self:_cur_entry())
end

function M:_apply_auto_framing()
  if is_null(self._follow_trans) or is_null(self._look_at_trans) or is_null(self._view_root) then
    return
  end
  local aabb = self:_query_aabb(self._cur_key)
  local fill_ratio, assumed_height_cells = self:_preview_framing_tuning()
  local ok, follow_world, look_at_world = CsNewBlueprintModuleUtil.TryComputeBlueprintPreviewFraming(aabb, self._view_root.position, Vector2(new_blueprint_module:get_preview_model_width_ratio(), fill_ratio), assumed_height_cells)
  if ok then
    local camera_wrap = self._follow_trans.parent
    self._follow_trans.localPosition = camera_wrap:InverseTransformPoint(follow_world)
    self._look_at_trans.localPosition = camera_wrap:InverseTransformPoint(look_at_world)
  else
    self._follow_trans.localPosition = self._default_follow_pos
    self._look_at_trans.localPosition = self._default_look_at_pos
  end
end

function M:_destroy_preview()
  if self._preview_helper then
    self._preview_helper:Destroy()
    self._preview_helper = nil
  end
end

function M:_on_drag(event)
  if event.button ~= 0 then
    return
  end
  if self._preview_helper then
    self._preview_helper:RotatePlane(-event.delta.x / 3)
  end
end

function M:_on_tog_target(is_on)
  local source_type = self:_tracking_source_type()
  if source_type == nil then
    return
  end
  if is_on then
    UIUtil.show_tips_by_text_id("Blueprint_UI_002")
  else
    UIUtil.show_tips_by_text_id("Blueprint_UI_003")
  end
  tracking_module:set_tracking_by_track_type(tracking_module.track_type.feature, source_type, self._cur_key, is_on, true)
end

function M:_refresh_target_toggle()
  if is_null(self._tog_target) then
    return
  end
  local source_type = self:_tracking_source_type()
  UIUtil.set_active(self._tog_target, source_type ~= nil)
  if source_type == nil then
    return
  end
  self._tog_target.isOnValue = CsTrackingModuleUtil.IsTrackingByTrackType(tracking_module.track_type.feature, source_type, self._cur_key)
end

function M:_reset_creator_card()
  UIUtil.set_text(self._txt_creator_name, "")
  UIUtil.set_player_avatar(self._img_creator_head, 0, self:get_load_proxy())
end

function M:_refresh_creator_card()
  local uid = self:_creator_uid_of(self:_cur_entry())
  self:_reset_creator_card()
  if uid <= 0 then
    return
  end
  CsSocialModuleUtil.QuerySocialPlayerInfo(uid, function(info)
    if is_null(self._txt_creator_name) then
      return
    end
    if info == nil or uid ~= self:_creator_uid_of(self:_cur_entry()) then
      return
    end
    UIUtil.set_text(self._txt_creator_name, info.Nickname or "")
    UIUtil.set_player_avatar(self._img_creator_head, info.AvatarId, self:get_load_proxy())
  end)
end

function M:_refresh_time_and_code()
  local entry = self:_cur_entry()
  if not_null(self._txt_create_time) then
    local timestamp = self:_timestamp_of(entry)
    if 0 < timestamp then
      local year, month, day, hour, min = LuaTimeUtil.get_date_time_from_timestamp(timestamp)
      UIUtil.set_text(self._txt_create_time, string.format("%d-%02d-%02d %02d:%02d", year, month, day, hour, min))
    else
      UIUtil.set_text(self._txt_create_time, "")
    end
  end
  if not_null(self._txt_code) then
    UIUtil.set_text(self._txt_code, self:_share_code_of(entry))
  end
end

function M:_on_btn_copy_code_click()
  if new_blueprint_module:try_block_blueprint_share_with_tip() then
    return
  end
  local share_code = self:_share_code_of(self:_cur_entry())
  if not string.is_valid(share_code) then
    Logger.LogWarning("[Blueprint] copy share code failed: empty share code")
    return
  end
  CS.UnityEngine.GUIUtility.systemCopyBuffer = share_code
  UIUtil.show_tips_by_text_id("Blueprint_ShareCodeCopied")
end

function M:_on_btn_place_click()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateSceneOverheadEdit) then
    UIUtil.show_tips_by_text_id("Blueprint_PlanetBuildNotUnlock")
    return
  end
  if not level_module:cur_level_is_main() then
    UIUtil.show_tips_by_text_id("Blueprint_UI_004")
    return
  end
  local own_state = self:_query_own_state(self._cur_key)
  if own_state == new_blueprint_module.custom_own_state.none then
    UIUtil.show_tips_by_text_id("Blueprint_UI_009")
    return
  end
  if own_state == new_blueprint_module.custom_own_state.blocked then
    UIUtil.show_tips_by_text_id("WorldEditor_BatchHold_ItemNotEnough_2")
    return
  end
  self._place_own_state = own_state
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Blueprint_PlaceConfirm"), UIUtil.get_text_by_id("Blueprint_UI_011"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(pack(self, M._do_place))
  popup:show()
end

function M:_do_place()
  self:_cancel_tracking_if_needed()
  if self._place_own_state == new_blueprint_module.custom_own_state.partial then
    UIUtil.show_tips_by_text_id("Blueprint_UI_010")
  end
  local domain = self:_domain()
  local fields = new_blueprint_module:build_blueprint_report_fields_by_key(domain, self._cur_key)
  fields.access_method = new_blueprint_module.blueprint_use_access.handbook
  CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.new_blueprint_use, "NewBlueprintUse", fields)
  new_blueprint_module:set_place_report_ctx(domain, self._cur_key)
  new_blueprint_module:set_blueprint_place_mode(true)
  self:_begin_batch_hold(self._cur_key)
  self:close_self()
end

function M:_cancel_tracking_if_needed()
  local source_type = self:_tracking_source_type()
  if source_type == nil then
    return
  end
  if CsTrackingModuleUtil.IsTrackingByTrackType(tracking_module.track_type.feature, source_type, self._cur_key) then
    tracking_module:set_tracking_by_track_type(tracking_module.track_type.feature, source_type, self._cur_key, false, true)
  end
end

function M:_is_valid_key(key)
  return key ~= nil and 0 < key
end

function M:_read_key_from_extra(extra)
  return 0
end

function M:_key_of(entry)
  return 0
end

function M:_get_sorted_list()
  return nil
end

function M:_query_aabb(key)
  return CsNewBlueprintModuleUtil.GetBlueprintAABB(self:_domain(), key)
end

function M:_query_items(key)
  return CsNewBlueprintModuleUtil.GetBlueprintItems(self:_domain(), key)
end

function M:_query_placeable(key)
  return CsNewBlueprintModuleUtil.GetBlueprintPlaceableCount(self:_domain(), key)
end

function M:_query_own_state(key)
  return CsNewBlueprintModuleUtil.GetBlueprintOwnState(self:_domain(), key)
end

function M:_create_preview(key, world_pos, rotate)
  return CsNewBlueprintModuleUtil.CreateBlueprintPreview(self:_domain(), key, world_pos, rotate)
end

function M:_begin_batch_hold(key)
  CsNewBlueprintModuleUtil.BeginBlueprintBatchHold(self:_domain(), key)
end

function M:_domain()
  return new_blueprint_module.BLUEPRINT_DOMAIN.official
end

function M:_tracking_source_type()
  return new_blueprint_module:get_tracking_source_by_domain(self:_domain())
end

function M:_type_state()
  return 0
end

function M:_is_official_blueprint()
  return self:_domain() == new_blueprint_module.BLUEPRINT_DOMAIN.official
end

function M:_creator_uid_of(entry)
  return entry and entry.CreatorUid or 0
end

function M:_timestamp_of(entry)
  return entry and entry.CreateTimestamp or 0
end

function M:_share_code_of(entry)
  return entry and entry.BpShareCode or ""
end

function M:_is_created_by_self(entry)
  local uid = self:_creator_uid_of(entry)
  return 0 < uid and uid == player_module:get_player_uid()
end

function M:_preview_rotate()
  return new_blueprint_module:get_preview_base_yaw()
end

function M:_refresh_title_and_extra()
end

function M:_preview_framing_tuning()
  return new_blueprint_module:get_preview_fill_ratio(), new_blueprint_module:get_preview_assumed_height_cells()
end

function M:_apply_preview_framing(entry)
  self:_apply_auto_framing()
end

function M:_bind_extra_callbacks()
end

return M
