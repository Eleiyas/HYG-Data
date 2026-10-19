new_blueprint_module = new_blueprint_module or {}
new_blueprint_module.custom_own_state = {
  none = 0,
  partial = 1,
  all = 2,
  blocked = 3
}
new_blueprint_module.review_status = {
  none = 0,
  pending = 1,
  approved = 2,
  rejected = 3
}

function new_blueprint_module:init_data()
  self._place_mode = false
  self._import_dialog_guid = nil
end

function new_blueprint_module:clear_data()
  self._place_mode = nil
  self._place_report_ctx = nil
  self._import_dialog_guid = nil
end

function new_blueprint_module:is_in_blueprint_place_mode()
  return self._place_mode == true
end

function new_blueprint_module:set_blueprint_place_mode(on)
  self._place_mode = on == true
end

function new_blueprint_module:get_custom_data_map()
  return CsNewBlueprintModuleUtil.NewBlueprintDataMap
end

function new_blueprint_module:get_custom_data(bp_guid)
  local ok, data = CsNewBlueprintModuleUtil.TryGetNewBlueprintData(bp_guid)
  if ok then
    return data
  end
  return nil
end

function new_blueprint_module:find_custom_data_by_share_code(share_code)
  if not string.is_valid(share_code) then
    return nil
  end
  local data_map = self:get_custom_data_map()
  if data_map == nil then
    return nil
  end
  local iter = data_map:GetEnumerator()
  while iter:MoveNext() do
    local data = iter.Current.Value
    if data ~= nil and data.BpShareCode == share_code then
      return data
    end
  end
  return nil
end

function new_blueprint_module:get_custom_sorted_list()
  local list = {}
  local data_map = CsNewBlueprintModuleUtil.NewBlueprintDataMap
  if data_map then
    local iter = data_map:GetEnumerator()
    while iter:MoveNext() do
      table.insert(list, iter.Current.Value)
    end
  end
  table.sort(list, function(a, b)
    return a.CreateTimestamp > b.CreateTimestamp
  end)
  return list
end

local DEFAULT_CUSTOM_SLOT_LIMIT = 0

function new_blueprint_module:get_custom_used_count()
  local data_map = self:get_custom_data_map()
  if data_map == nil then
    return 0
  end
  return data_map.Count
end

function new_blueprint_module:get_current_habitat_level()
  local level = blueprint_habitat_module:get_architect_level()
  return level or 1
end

function new_blueprint_module:get_custom_slot_limit()
  local level = self:get_current_habitat_level()
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatLevelCfg), level)
  if cfg == nil then
    return DEFAULT_CUSTOM_SLOT_LIMIT
  end
  return cfg.diyblueprintslotnum or DEFAULT_CUSTOM_SLOT_LIMIT
end

function new_blueprint_module:is_custom_slot_full()
  return self:get_custom_used_count() >= self:get_custom_slot_limit()
end

function new_blueprint_module:intercept_if_custom_slot_full()
  if not self:is_custom_slot_full() then
    return false
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Blueprint_CustomSlotFull"), UIUtil.get_text_by_id("Blueprint_GotoDelete"), UIUtil.get_text_by_id("Common_Cancel"), nil)
  popup:set_callbacks(function()
    UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSelectDeletePage")
  end)
  popup:show()
  return true
end

function new_blueprint_module:is_under_review(data)
  if data == nil then
    return false
  end
  local info = data.ReviewInfo
  if is_null(info) then
    return false
  end
  local pending = self.review_status.pending
  return info.NameReviewStatus == pending or info.CoverReviewStatus == pending or info.EntityReviewStatus == pending
end

function new_blueprint_module:get_content_version(data)
  if data == nil then
    return 0
  end
  local info = data.ReviewInfo
  if is_null(info) then
    return 0
  end
  return info.ContentVersion or 0
end

function new_blueprint_module:open_import_code_dialog()
  if self:try_block_blueprint_import_with_tip() then
    return
  end
  local guid = UIManagerInstance:open("UI/CommonUI/CommomCodeInputDialog", {
    title = UIUtil.get_text_by_id("Blueprint_ImportCodeTitle"),
    placeholder = UIUtil.get_text_by_id("Blueprint_ImportCodePlaceholder"),
    confirm_callback = function(code)
      return self:_on_import_code_confirmed(code)
    end
  })
  self._import_dialog_guid = guid
end

function new_blueprint_module:_close_import_code_dialog()
  local guid = self._import_dialog_guid
  self._import_dialog_guid = nil
  if guid == nil then
    return
  end
  local dialog = UIManagerInstance:is_show_by_guid(guid)
  if dialog then
    dialog:close_self()
  end
end

function new_blueprint_module:try_import_blueprint_by_code(code)
  if self:try_block_blueprint_import_with_tip() then
    return false
  end
  if CsNewBlueprintModuleUtil.IsNull() then
    return false
  end
  CsNewBlueprintModuleUtil.ImportNewBlueprint(code)
  return true
end

function new_blueprint_module:_on_import_code_confirmed(code)
  self:try_import_blueprint_by_code(code)
  return false
end

function new_blueprint_module:_on_shared_blueprint_imported(arg)
  local retcode = tonumber(arg) or 0
  if retcode ~= 0 then
    return
  end
  self:_close_import_code_dialog()
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSharedInfoPage")
end

function new_blueprint_module:copy_shared_blueprint(replace_bp_guid)
  if self:try_block_blueprint_import_with_tip() then
    return
  end
  if CsNewBlueprintModuleUtil.IsNull() then
    return
  end
  CsNewBlueprintModuleUtil.CopyNewBlueprint(replace_bp_guid or 0)
end

function new_blueprint_module:try_copy_shared_blueprint()
  if self:try_block_blueprint_import_with_tip() then
    return
  end
  if not self:is_copied_blueprint_unlocked() then
    UIUtil.show_tips_by_text_id("Blueprint_UI_001", self:get_copied_unlock_architect_level())
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Blueprint_CopyConfirm"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:_do_copy_shared_blueprint()
  end)
  popup:show()
end

function new_blueprint_module:_do_copy_shared_blueprint()
  if self:get_copied_used_count() >= self:get_copied_slot_limit() then
    UIUtil.show_tips_by_text_id("Blueprint_CopiedSlotFull")
    UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSelectReplacePage")
    return
  end
  self:copy_shared_blueprint(0)
end

function new_blueprint_module:_on_copy_blueprint_result(arg)
  local retcode = tonumber(arg) or 0
  if retcode ~= 0 then
    return
  end
  UIUtil.show_tips_by_text_id("Blueprint_CopySuccess")
end

function new_blueprint_module:delete_copied_blueprint(bp_guid)
  if bp_guid == nil or bp_guid == 0 then
    return
  end
  if CsNewBlueprintModuleUtil.IsNull() then
    return
  end
  CsNewBlueprintModuleUtil.DeleteCopiedNewBlueprint(bp_guid)
end

function new_blueprint_module:open_select_post_page()
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSelectPostPage")
end

function new_blueprint_module:open_custom_info_page_from_post(bp_guid)
  if bp_guid == nil or bp_guid == 0 or self:get_custom_data(bp_guid) == nil then
    Logger.LogWarning("[Blueprint] open custom info from post: blueprint not found, guid=" .. tostring(bp_guid))
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintCustomInfoPage", {
    bp_guid = bp_guid,
    page_source = self.INFO_PAGE_SOURCE.little_corner_post
  })
end

function new_blueprint_module:check_little_corner_unlocked()
  if not little_corner_module:is_little_corner_unlocked() then
    UIUtil.show_tips_by_text_id("Blueprint_LittleCornerNotUnlock")
    return false
  end
  return true
end

function new_blueprint_module:try_make_little_corner_post_ctx(data)
  if data == nil then
    return nil
  end
  if self:try_block_blueprint_share_with_tip() then
    return nil
  end
  if self:is_under_review(data) then
    return nil
  end
  if not self:check_little_corner_unlocked() then
    return nil
  end
  if not string.is_valid(data.BpShareCode) then
    Logger.LogWarning("[Blueprint] upload to little corner failed: empty share code")
    return nil
  end
  if not string.is_valid(data.ImageKey) then
    UIUtil.show_tips_by_text_id("Blueprint_UploadNeedCover")
    return nil
  end
  return {
    share_code = data.BpShareCode,
    cover_file_key = data.ImageKey,
    cover_uploader_uid = data.CreatorUid or 0,
    bp_guid = data.BpGuid
  }
end

function new_blueprint_module:has_shared_xhs_post(data)
  if data == nil or data.SharedXhsPostList == nil then
    return false
  end
  return data.SharedXhsPostList.Count > 0
end

function new_blueprint_module:_on_xhs_post_created(post_id)
  local origin = little_corner_module:get_last_created_post()
  if origin == nil or origin.blueprint_guid == nil or origin.blueprint_guid == 0 then
    return
  end
  if origin.post_id ~= post_id then
    Logger.LogWarning("[Blueprint] bind xhs post skipped: origin snapshot mismatch")
    return
  end
  CsNewBlueprintModuleUtil.BindXhsPost(origin.blueprint_guid, origin.post_id)
end

function new_blueprint_module:get_copied_data_map()
  return CsNewBlueprintModuleUtil.CopiedBlueprintDataMap
end

function new_blueprint_module:get_copied_data(bp_guid)
  local ok, data = CsNewBlueprintModuleUtil.TryGetCopiedBlueprintData(bp_guid)
  if ok then
    return data
  end
  return nil
end

function new_blueprint_module:open_info_page_by_guid(bp_guid)
  if bp_guid == nil or bp_guid == 0 then
    return
  end
  if self:get_custom_data(bp_guid) ~= nil then
    UIManagerInstance:open("UI/BlueprintHabitat/BlueprintCustomInfoPage", {bp_guid = bp_guid})
    return
  end
  if self:get_copied_data(bp_guid) ~= nil then
    UIManagerInstance:open("UI/BlueprintHabitat/BlueprintCopiedInfoPage", {bp_guid = bp_guid})
    return
  end
  Logger.LogWarning("[Blueprint] open info page by guid: blueprint not found, guid=" .. tostring(bp_guid))
end

function new_blueprint_module:get_copied_sorted_list()
  local list = {}
  local data_map = CsNewBlueprintModuleUtil.CopiedBlueprintDataMap
  if data_map then
    local iter = data_map:GetEnumerator()
    while iter:MoveNext() do
      table.insert(list, iter.Current.Value)
    end
  end
  table.sort(list, function(a, b)
    return a.CopyTimestamp > b.CopyTimestamp
  end)
  return list
end

function new_blueprint_module:refresh_stat_by_domain(domain)
  if domain == nil then
    return
  end
  if CsNewBlueprintModuleUtil.IsNull() then
    return
  end
  CsNewBlueprintModuleUtil.QueryNewBlueprintStatByDomain(domain)
end

function new_blueprint_module:refresh_stat_by_share_code(domain, share_code)
  if domain == nil then
    return
  end
  if not string.is_valid(share_code) then
    return
  end
  if CsNewBlueprintModuleUtil.IsNull() then
    return
  end
  CsNewBlueprintModuleUtil.QueryNewBlueprintStat(domain, share_code)
end

local DEFAULT_COPIED_SLOT_LIMIT = 0

function new_blueprint_module:get_copied_used_count()
  local data_map = self:get_copied_data_map()
  if data_map == nil then
    return 0
  end
  return data_map.Count
end

function new_blueprint_module:get_copied_slot_limit()
  local level = self:get_current_habitat_level()
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatLevelCfg), level)
  if cfg == nil then
    return DEFAULT_COPIED_SLOT_LIMIT
  end
  return cfg.copyblueprintslotnum or DEFAULT_COPIED_SLOT_LIMIT
end

new_blueprint_module.blueprint_use_access = {handbook = 0, furnish = 1}

local function build_item_list_and_percent(need_map)
  local parts = {}
  local total_need = 0
  local owned_capped = 0
  for cfg_id, need in pairs(need_map) do
    parts[#parts + 1] = string.format("{\"id\":%d,\"count\":%d}", cfg_id, need)
    local owned = item_module:get_item_total_num_by_cfg_id(cfg_id) or 0
    total_need = total_need + need
    owned_capped = owned_capped + math.min(owned, need)
  end
  local percent = 0 < total_need and math.floor(owned_capped / total_need * 100) or 0
  return "[" .. table.concat(parts, ",") .. "]", percent
end

local function make_report_fields(is_official, key, need_map)
  local item_list, percent = build_item_list_and_percent(need_map)
  return {
    id = is_official and key or 0,
    guid = is_official and 0 or key,
    type = is_official and 0 or 1,
    percent = percent,
    item_list = item_list
  }
end

function new_blueprint_module:build_blueprint_report_fields_by_key(domain, key)
  local items = CsNewBlueprintModuleUtil.GetBlueprintItems(domain, key)
  local need_map = {}
  local count = items and items.Count or 0
  for i = 0, count - 1 do
    local data = items[i]
    need_map[data.x] = (need_map[data.x] or 0) + data.y
  end
  return make_report_fields(domain == self.BLUEPRINT_DOMAIN.official, key, need_map)
end

function new_blueprint_module:build_blueprint_report_fields_by_entities(is_official, key, entity_list)
  local need_map = {}
  if entity_list then
    for i = 0, entity_list.Count - 1 do
      local entity_data = entity_list[i]
      local cfg_id = entity_data and entity_data.ConfigId or 0
      if 0 < cfg_id then
        need_map[cfg_id] = (need_map[cfg_id] or 0) + 1
      end
    end
  end
  return make_report_fields(is_official, key, need_map)
end

function new_blueprint_module:set_place_report_ctx(domain, key)
  self._place_report_ctx = {domain = domain, key = key}
end

function new_blueprint_module:get_place_report_ctx()
  return self._place_report_ctx
end

function new_blueprint_module:clear_place_report_ctx()
  self._place_report_ctx = nil
end

function new_blueprint_module:is_unlocked()
  return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateNewBlueprint)
end

function new_blueprint_module:get_unlock_architect_level()
  return CsNewBlueprintModuleUtil.GetBlueprintUnlockArchitectLevel()
end

function new_blueprint_module:is_custom_blueprint_unlocked()
  return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateDiyNewBlueprint)
end

function new_blueprint_module:get_custom_unlock_architect_level()
  return CsNewBlueprintModuleUtil.GetCustomBlueprintUnlockArchitectLevel()
end

function new_blueprint_module:is_copied_blueprint_unlocked()
  return self:is_custom_blueprint_unlocked()
end

function new_blueprint_module:get_copied_unlock_architect_level()
  return self:get_custom_unlock_architect_level()
end

function new_blueprint_module:is_blueprint_unlocked(blueprint_id)
  if CsNewBlueprintModuleUtil.IsNull() then
    return false
  end
  return CsNewBlueprintModuleUtil.IsOfficialBlueprintUnlocked(blueprint_id)
end

function new_blueprint_module:is_discovered(blueprint_id)
  return self:is_blueprint_unlocked(blueprint_id)
end

function new_blueprint_module:record_blueprint_unlock(blueprint_id)
  red_point_module:record_with_id(red_point_module.red_point_type.blueprint_unlock, blueprint_id)
end

function new_blueprint_module:is_blueprint_unlock_recorded(blueprint_id)
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.blueprint_unlock, blueprint_id)
end

function new_blueprint_module:has_any_blueprint_unlock_not_recorded()
  local cfg_list = self:get_discovered_sorted_list()
  for _, cfg in ipairs(cfg_list) do
    if not self:is_blueprint_unlock_recorded(cfg.id) then
      return true
    end
  end
  return false
end

return new_blueprint_module
