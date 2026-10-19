local M = G.Class("StarBayExchangeDiaryPanel", G.StarPanelBase)
local base = G.StarPanelBase
local search_field_cls = "UI/CompanionStarDetail/ExchangeDiary/StarbaySearchFieldPanel"
local card_item_cls = "UI/CompanionStarDetail/ExchangeDiary/StarBayDiaryCardItem"
local filter_dialog_path = "UI/CommonUI/SearchFilter/CommonGroupedFilterDialog"
local share_dialog_path = "UI/CompanionStarDetail/ExchangeDiary/StarBayDiaryShareDialog"
local DiaryCfgType = typeof(NpcDiaryCfg)
local DiaryTypeCfgType = typeof(NpcDiaryTypeCfg)
local RecorderTypeEnum = NpcDiaryRecorderType
local CardSizeEnum = NpcDiaryCardSize
local diary_star_side_yaw = -20

local function normalize_text(text)
  if text == nil then
    return ""
  end
  text = tostring(text)
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

local function clear_image_if_valid(target)
  if is_null(target) then
    return
  end
  target.sprite = nil
end

local function dict_to_sorted_list(dic, sort_func)
  local result = {}
  for _, value in pairs(dic or {}) do
    table.insert(result, value)
  end
  if sort_func then
    table.sort(result, sort_func)
  end
  return result
end

local function clone_query_state(source_state)
  local query_state = {
    searchText = source_state and source_state.searchText or "",
    selectedTypeIds = {},
    selectedRecorderTypes = {},
    requirePhoto = source_state and source_state.requirePhoto == true or false
  }
  for _, type_id in ipairs(source_state and source_state.selectedTypeIds or {}) do
    table.insert(query_state.selectedTypeIds, type_id)
  end
  for _, recorder_type in ipairs(source_state and source_state.selectedRecorderTypes or {}) do
    table.insert(query_state.selectedRecorderTypes, recorder_type)
  end
  return query_state
end

local function has_confirmed_filter(query_state)
  return query_state and (#(query_state.selectedTypeIds or {}) > 0 or 0 < #(query_state.selectedRecorderTypes or {}) or query_state.requirePhoto == true)
end

local function clear_reused_table(tbl)
  tbl = tbl or {}
  table.clear(tbl)
  return tbl
end

local function query_state_to_filter_selected(query_state, selected)
  selected = selected or {}
  selected.type = clear_reused_table(selected.type)
  selected.recorder = clear_reused_table(selected.recorder)
  selected.photo = clear_reused_table(selected.photo)
  for _, type_id in ipairs(query_state and query_state.selectedTypeIds or {}) do
    selected.type[type_id] = true
  end
  for _, recorder_type in ipairs(query_state and query_state.selectedRecorderTypes or {}) do
    selected.recorder[recorder_type] = true
  end
  if query_state and query_state.requirePhoto == true then
    selected.photo[true] = true
  end
  return selected
end

local function filter_selected_to_query_state(selected, source_state, query_state)
  query_state = query_state or {}
  query_state.searchText = source_state and source_state.searchText or ""
  query_state.selectedTypeIds = clear_reused_table(query_state.selectedTypeIds)
  query_state.selectedRecorderTypes = clear_reused_table(query_state.selectedRecorderTypes)
  query_state.requirePhoto = selected and selected.photo and selected.photo[true] == true or false
  for type_id, is_on in pairs(selected and selected.type or {}) do
    if is_on == true then
      table.insert(query_state.selectedTypeIds, type_id)
    end
  end
  table.sort(query_state.selectedTypeIds, function(a, b)
    return (a or 0) < (b or 0)
  end)
  for recorder_type, is_on in pairs(selected and selected.recorder or {}) do
    if is_on == true then
      table.insert(query_state.selectedRecorderTypes, recorder_type)
    end
  end
  table.sort(query_state.selectedRecorderTypes, function(a, b)
    return tostring(a or "") < tostring(b or "")
  end)
  return query_state
end

local function get_search_history_limit()
  local cfg = ExcelDataUtil.get_value(typeof(BPlayerCfg), 196)
  if cfg and cfg.value and cfg.value > 0 then
    return cfg.value
  end
  return 10
end

local function load_search_history_list(history_limit)
  local result = {}
  local history_str = CsLocalSaveDataUtil.GetString(LocalSaveID.StarBayDiarySearchHistory, "")
  if not string.is_valid(history_str) then
    return result
  end
  for segment in string.gmatch(history_str, [[
[^
]+]]) do
    segment = normalize_text(segment)
    if string.is_valid(segment) then
      table.insert(result, segment)
    end
    if history_limit <= #result then
      break
    end
  end
  return result
end

local function save_search_history_list(history_list)
  CsLocalSaveDataUtil.SetString(LocalSaveID.StarBayDiarySearchHistory, table.concat(history_list or {}, "\n"))
end

local function record_search_history(search_text, source_history, history_limit)
  search_text = normalize_text(search_text)
  if not string.is_valid(search_text) then
    return source_history or {}, history_limit
  end
  local new_history = {search_text}
  for _, item in ipairs(source_history or {}) do
    item = normalize_text(item)
    if string.is_valid(item) and item ~= search_text then
      table.insert(new_history, item)
    end
    if history_limit <= #new_history then
      break
    end
  end
  save_search_history_list(new_history)
  return new_history, history_limit
end

local function stringify_text_map(text_map)
  if text_map == nil then
    return ""
  end
  if type(text_map) == "string" then
    return text_map
  end
  if text_map.ToStringExplicit ~= nil then
    return text_map:ToStringExplicit()
  end
  return tostring(text_map)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CompanionStar/StarBay/StarBayExchangeDiaryPanel"
  self._npc_id = 0
  self._current_page_index = 0
  self._page_descriptors = {}
  self._entry_contexts = {}
  self._applied_query_state = clone_query_state(nil)
  self._draft_filter_state = clone_query_state(nil)
  self._filter_selected_cache = {
    type = {},
    recorder = {},
    photo = {}
  }
  self._filter_query_state_cache = {
    searchText = "",
    selectedTypeIds = {},
    selectedRecorderTypes = {},
    requirePhoto = false
  }
  self._style_cfg_cache = {}
  self._type_cfg_table = nil
  self._diary_cfg_table = nil
  self._album_photo_cache = {}
  self._filter_groups_cache = nil
  self._search_panel = nil
  self._search_panel_ready_callbacks = nil
  self._search_history_list = {}
  self._search_history_limit = get_search_history_limit()
  self._is_destroyed = false
  self._tab_red_point_gameplay_id = 0
  self._entry_red_point_gameplay_id = 0
  self._is_shell_host_active = false
  self._is_search_shell_expanded = false
  self._card_refresh_version = 0
  self._is_opening_share_dialog = false
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._left_template) then
    UIUtil.set_active(self._left_template, false)
  end
  if not is_null(self._right_template) then
    UIUtil.set_active(self._right_template, false)
  end
  if not is_null(self._btn_left) then
    self:bind_callback(self._btn_left, pack(self, M._on_click_prev_page))
  end
  if not is_null(self._btn_right) then
    self:bind_callback(self._btn_right, pack(self, M._on_click_next_page))
  end
  self._side_views = {
    left = {
      root = self._left_group,
      small_items = {},
      big_item = nil
    },
    right = {
      root = self._right_group,
      small_items = {},
      big_item = nil
    }
  }
end

function M:on_destroy()
  self:_invalidate_delayed_card_refresh()
  self._is_destroyed = true
  self._search_panel_ready_callbacks = nil
  self:_release_album_photo_cache()
  base.on_destroy(self)
end

function M:on_disable()
  self:_invalidate_delayed_card_refresh()
  self._search_panel_ready_callbacks = nil
  self._current_page_index = 0
  self:_reset_query_state()
  self._is_opening_share_dialog = false
  CsNPCSphereLandManagerUtil.SetDragRotationLocked(false)
  base.on_disable(self)
end

function M:_is_async_context_valid(request_npc_id)
  return not self._is_destroyed and not is_null(self.game_obj) and self.is_active and (request_npc_id == nil or self._npc_id == request_npc_id)
end

function M:_invalidate_filter_groups_cache()
  self._filter_groups_cache = nil
end

function M:set_red_point_gameplay_ids(tab_gameplay_id, entry_gameplay_id)
  self._tab_red_point_gameplay_id = tab_gameplay_id or 0
  self._entry_red_point_gameplay_id = entry_gameplay_id or 0
end

function M:attach_shell_controls(args)
  if args == nil then
    return
  end
  self._search_field_root = args.search_field_root or self._search_field_root
  self._filter_toggle = args.filter_toggle or self._filter_toggle
  self._filter_result_group = args.filter_result_group or self._filter_result_group
  if args.is_shell_host_active ~= nil then
    self._is_shell_host_active = args.is_shell_host_active == true
  end
  self:_ensure_search_panel()
  self:_refresh_shell_state()
end

function M:set_shell_host_active(is_active)
  self._is_shell_host_active = is_active == true
  if not self._is_shell_host_active then
    self:_set_search_shell_expanded(false)
  end
  self:_refresh_shell_state()
end

function M:open_search_shell_from_shell()
  self:_set_search_shell_expanded(true)
  self:_refresh_shell_state()
  self:_ensure_search_panel(function(search_panel)
    search_panel:open()
  end)
end

function M:submit_search_from_shell()
  if not self._is_search_shell_expanded then
    self:open_search_shell_from_shell()
    return
  end
  self:_ensure_search_panel(function(search_panel)
    search_panel:request_submit("button", nil, true)
  end)
end

function M:reset_search_shell_on_tab_exit()
  self:_set_search_shell_expanded(false)
  self:_refresh_shell_state()
end

function M:open_filter_dialog_from_shell()
  self:_open_filter_dialog()
end

function M:clear_query_state()
  self:_reset_query_state()
  self:_refresh_query_result("default_last")
end

function M:clear_search_from_shell()
  if self._search_panel and not is_null(self._search_panel.game_obj) then
    self._search_panel:sync_reset()
  end
  local had_applied_search = self._applied_query_state.searchText ~= ""
  if had_applied_search then
    self._applied_query_state.searchText = ""
  end
  self:_refresh_shell_state()
  self:_refresh_query_result("default_last")
  if self._is_search_shell_expanded and self._search_panel and not is_null(self._search_panel.game_obj) then
    self._search_panel:open()
  end
end

function M:close_search_shell_from_shell()
  self:_set_search_shell_expanded(false)
  self:_refresh_shell_state()
end

function M:request_close_search_shell_from_shell()
  self:_ensure_search_panel(function(search_panel)
    search_panel:request_blank_close("button")
  end)
end

function M:get_applied_query_state()
  return clone_query_state(self._applied_query_state)
end

function M:has_applied_filter()
  return has_confirmed_filter(self._applied_query_state)
end

function M:get_topbar_config()
  return {
    type = "diary",
    on_search = pack(self, M.submit_search_from_shell),
    on_filter = function(val)
      self:open_filter_dialog_from_shell()
      if not val then
        self:refresh_shell_state()
      end
    end,
    has_filter = pack(self, M.has_applied_filter)
  }
end

function M:show()
  base.show(self)
  self:_apply_diary_star_view()
end

function M:_apply_diary_star_view()
  CsNPCSphereLandManagerUtil.RotateTo(0, diary_star_side_yaw, 0, 1.0)
  CsNPCSphereLandManagerUtil.SetDragRotationLocked(true)
end

function M:play_enter(callback)
  self:play_animation("anim_starbayexchangediarypanel_in", callback)
end

function M:play_exit(callback)
  self:play_animation("anim_starbayexchangediarypanel_out", callback)
end

function M:refresh()
  local star_data = self.holder and self.holder.cur_star_data or nil
  if star_data == nil then
    return
  end
  local npc_id = star_data.npcid or 0
  local npc_changed = self._npc_id ~= npc_id
  local need_book_in_refresh = npc_changed or 0 >= self._current_page_index
  self._npc_id = npc_id
  self:_ensure_search_panel()
  self:_invalidate_filter_groups_cache()
  if npc_changed then
    self:_release_album_photo_cache()
    self:_reset_query_state()
    self:_apply_diary_background_illustrations()
  end
  if need_book_in_refresh then
    self:_refresh_cards_after_book_in("default_last")
  else
    self:_refresh_query_result("clamp")
  end
  CsCompanionStarModuleUtil.RecordDiaryTabVisitedForLua(self._npc_id, self._tab_red_point_gameplay_id, self._entry_red_point_gameplay_id)
end

function M:_invalidate_delayed_card_refresh()
  self._card_refresh_version = (self._card_refresh_version or 0) + 1
end

function M:_clear_card_page()
  self._entry_contexts = {}
  self._page_descriptors = {}
  self._current_page_index = 0
  self:_refresh_page()
end

function M:_refresh_cards_after_book_in(page_mode)
  self:_invalidate_delayed_card_refresh()
  local refresh_version = self._card_refresh_version
  local request_npc_id = self._npc_id
  self:_clear_card_page()
  self:_apply_book_spine_style(self:_get_style_cfg_by_npc_id(request_npc_id))
  CsCoroutineManagerUtil.Invoke(0.75, function()
    if self._card_refresh_version ~= refresh_version or not self:_is_async_context_valid(request_npc_id) then
      return
    end
    self:_refresh_query_result(page_mode)
  end)
end

function M:_ensure_search_panel(on_ready)
  if is_null(self._search_field_root) then
    return
  end
  if self._search_panel ~= nil then
    if on_ready ~= nil then
      if not is_null(self._search_panel.game_obj) then
        on_ready(self._search_panel)
      else
        self:_push_search_panel_ready_callback(on_ready)
      end
    end
    return
  end
  self._search_history_limit = get_search_history_limit()
  self._search_history_list = load_search_history_list(self._search_history_limit)
  self:_push_search_panel_ready_callback(on_ready)
  self._search_panel = self:add_panel_async(search_field_cls, {
    history_list = self._search_history_list,
    history_limit = self._search_history_limit,
    normalizer = normalize_text,
    on_record_history = function(search_text)
      self._search_history_list = record_search_history(search_text, self._search_history_list, self._search_history_limit)
      return self._search_history_list, self._search_history_limit
    end
  }, self._search_field_root, pack(self, M._on_search_panel_loaded))
end

function M:_on_search_panel_loaded(search_panel)
  if self._is_destroyed or self._search_panel ~= nil and search_panel ~= self._search_panel then
    self._search_panel_ready_callbacks = nil
    return
  end
  self._search_panel = search_panel
  search_panel:set_callbacks({
    on_submit = function(search_text)
      self:_apply_search_text(search_text)
    end,
    on_candidate_refresh = function()
    end,
    on_clear = function()
      self:clear_search_from_shell()
    end,
    on_request_close = function()
      self:close_search_shell_from_shell()
    end
  })
  self:_refresh_shell_state()
  if self.is_active and self._is_shell_host_active and self._is_search_shell_expanded then
    self:_flush_search_panel_ready_callbacks(search_panel)
  else
    self._search_panel_ready_callbacks = nil
  end
end

function M:_push_search_panel_ready_callback(callback)
  if callback == nil then
    return
  end
  self._search_panel_ready_callbacks = self._search_panel_ready_callbacks or {}
  table.insert(self._search_panel_ready_callbacks, callback)
end

function M:_flush_search_panel_ready_callbacks(search_panel)
  local callbacks = self._search_panel_ready_callbacks
  self._search_panel_ready_callbacks = nil
  for _, callback in ipairs(callbacks or {}) do
    callback(search_panel)
  end
end

function M:_reset_query_state()
  self._applied_query_state = clone_query_state(nil)
  self._draft_filter_state = clone_query_state(nil)
  self:_set_search_shell_expanded(false)
  if self._search_panel and not is_null(self._search_panel.game_obj) then
    self._search_panel:sync_reset()
  end
  self:_refresh_shell_state()
end

function M:_apply_search_text(search_text)
  local normalized = normalize_text(search_text)
  if self._search_panel and not is_null(self._search_panel.game_obj) then
    self._search_panel:sync_applied_text(normalized)
  end
  if string.is_valid(normalized) then
    self:_set_search_shell_expanded(true)
  end
  if self._applied_query_state.searchText == normalized then
    self:_refresh_shell_state()
    return
  end
  self._applied_query_state.searchText = normalized
  self:_refresh_shell_state()
  self:_refresh_query_result("first")
end

function M:_apply_confirmed_filter_state(query_state)
  self._draft_filter_state = clone_query_state(query_state)
  local old_search_text = self._applied_query_state.searchText
  self._applied_query_state = clone_query_state(query_state)
  self._applied_query_state.searchText = old_search_text
  self:_refresh_shell_state()
  self:_refresh_query_result("first")
end

function M:_set_search_shell_expanded(is_expanded)
  self._is_search_shell_expanded = is_expanded == true
  if self.holder and self.holder.set_topbar_search_expanded then
    self.holder:set_topbar_search_expanded(self._is_search_shell_expanded)
  end
end

function M:_refresh_shell_state()
  local is_search_visible = self._is_shell_host_active and self._is_search_shell_expanded
  if self._search_panel and not is_null(self._search_panel.game_obj) then
    if is_search_visible then
      self._search_panel:change_state(EUIState.Show)
    elseif self._search_panel.is_active then
      self._search_panel:change_state(EUIState.Hide)
    end
    self._search_panel:sync_visibility(is_search_visible)
  end
  local has_filter = has_confirmed_filter(self._applied_query_state)
  if not is_null(self._filter_toggle) then
    if self._filter_toggle.SetIsOnWithoutNotify ~= nil then
      self._filter_toggle:SetIsOnWithoutNotify(has_filter)
    elseif self._filter_toggle.isOnValue ~= nil then
      self._filter_toggle.isOnValue = has_filter
    end
  end
  if not is_null(self._filter_result_group) then
    UIUtil.set_active(self._filter_result_group, self._is_shell_host_active and has_filter)
  end
  if self.holder and self.holder.refresh_topbar_state then
    self.holder:refresh_topbar_state()
  end
end

function M:_get_diary_cfg_table()
  if self._diary_cfg_table == nil then
    self._diary_cfg_table = LocalDataUtil.get_table(DiaryCfgType) or {}
  end
  return self._diary_cfg_table
end

function M:_get_type_cfg_table()
  if self._type_cfg_table == nil then
    self._type_cfg_table = LocalDataUtil.get_table(DiaryTypeCfgType) or {}
  end
  return self._type_cfg_table
end

function M:_get_style_cfg_by_npc_id(npc_id)
  if npc_id == nil then
    return nil
  end
  if self._style_cfg_cache[npc_id] ~= nil then
    return self._style_cfg_cache[npc_id] or nil
  end
  local style_cfg = CsCompanionStarModuleUtil.GetDiaryStyleCfgForLua(npc_id, RecorderTypeEnum.Npc) or false
  self._style_cfg_cache[npc_id] = style_cfg
  return style_cfg or nil
end

function M:_resolve_entry_style_cfg(type_cfg)
  local recorder_type = type_cfg and type_cfg.recorderType or RecorderTypeEnum.Npc
  if recorder_type == RecorderTypeEnum.Player then
    return self:_get_style_cfg_by_npc_id(0)
  end
  return self:_get_style_cfg_by_npc_id(self._npc_id)
end

function M:_build_entry_contexts(runtime_entries)
  local entry_contexts = {}
  local type_cfg_table = self:_get_type_cfg_table()
  local diary_cfg = self:_get_diary_cfg_table()[self._npc_id]
  local diary_entry_cfg_by_index = {}
  local runtime_entry_list = list_to_table(runtime_entries) or {}
  if diary_cfg and diary_cfg.entries then
    for _, entry_cfg in ipairs(list_to_table(diary_cfg.entries) or {}) do
      if entry_cfg then
        diary_entry_cfg_by_index[entry_cfg.unlockIndex] = entry_cfg
      end
    end
  end
  for _, view_data in ipairs(runtime_entry_list) do
    local entry_cfg = diary_entry_cfg_by_index[view_data.unlockIndex]
    local type_cfg = entry_cfg and type_cfg_table[entry_cfg.typeId] or nil
    local recorder_type = type_cfg and type_cfg.recorderType or RecorderTypeEnum.Npc
    local style_cfg = self:_resolve_entry_style_cfg(type_cfg)
    local photo_alias = entry_cfg and entry_cfg.photoAlias or ""
    table.insert(entry_contexts, {
      view_data = view_data,
      entry_cfg = entry_cfg,
      type_cfg = type_cfg,
      style_cfg = style_cfg,
      recorder_type = recorder_type,
      has_photo = string.is_valid(photo_alias),
      is_big = entry_cfg and entry_cfg.cardSize == CardSizeEnum.Big or false,
      file_key = view_data.fileKey or "",
      photo_alias = photo_alias,
      photo_review_status = view_data.photoReviewStatus or 0
    })
  end
  table.sort(entry_contexts, function(left, right)
    local left_ts = left and left.view_data and left.view_data.unlockTimestamp or 0
    local right_ts = right and right.view_data and right.view_data.unlockTimestamp or 0
    if left_ts ~= right_ts then
      return left_ts < right_ts
    end
    local left_index = left and left.view_data and left.view_data.unlockIndex or 0
    local right_index = right and right.view_data and right.view_data.unlockIndex or 0
    return left_index < right_index
  end)
  return entry_contexts
end

function M:_build_runtime_query_state()
  return self._applied_query_state
end

function M:_refresh_query_result(page_mode)
  local query_state = self:_build_runtime_query_state()
  local query_result = CsCompanionStarModuleUtil.QueryDiaryEntryViewDataListForLua(self._npc_id, query_state.searchText or "", query_state.selectedTypeIds, query_state.selectedRecorderTypes, query_state.requirePhoto == true, self._tab_red_point_gameplay_id, self._entry_red_point_gameplay_id)
  local runtime_entries = query_result and list_to_table(query_result.entries) or {}
  self._entry_contexts = self:_build_entry_contexts(runtime_entries)
  self:_rebuild_page_descriptors()
  self:_apply_page_mode(page_mode or "clamp")
  self:_refresh_page()
end

function M:_rebuild_page_descriptors()
  self._page_descriptors = {}
  if #self._entry_contexts == 0 then
    return
  end
  local page_data = {
    left = {},
    right = {}
  }
  local current_side_key = "left"
  local current_side_used = 0
  
  local function flush_new_page()
    table.insert(self._page_descriptors, page_data)
    page_data = {
      left = {},
      right = {}
    }
    current_side_key = "left"
    current_side_used = 0
  end
  
  local function switch_side_or_page(entry_size)
    if current_side_key == "left" then
      current_side_key = "right"
      current_side_used = #page_data.right == 0 and 0 or 2
      if entry_size <= 2 and current_side_used + entry_size <= 2 then
        return
      end
    end
    flush_new_page()
  end
  
  for _, entry_context in ipairs(self._entry_contexts) do
    local entry_size = entry_context.is_big and 2 or 1
    if 2 < current_side_used + entry_size then
      switch_side_or_page(entry_size)
    end
    table.insert(page_data[current_side_key], entry_context)
    current_side_used = current_side_used + entry_size
    if 2 <= current_side_used and current_side_key == "left" then
      current_side_key = "right"
      current_side_used = 0
    elseif 2 <= current_side_used and current_side_key == "right" then
      flush_new_page()
    end
  end
  if 0 < #page_data.left or 0 < #page_data.right then
    table.insert(self._page_descriptors, page_data)
  end
end

function M:_apply_page_mode(page_mode)
  local page_count = #self._page_descriptors
  if page_count <= 0 then
    self._current_page_index = 0
    return
  end
  if page_mode == "default_last" then
    self._current_page_index = page_count
    return
  end
  if page_mode == "first" then
    self._current_page_index = 1
    return
  end
  if 0 >= self._current_page_index then
    self._current_page_index = page_count
  else
    self._current_page_index = math.clamp(self._current_page_index, 1, page_count)
  end
end

function M:_refresh_page()
  local page_count = #self._page_descriptors
  if page_count <= 0 or 0 >= self._current_page_index then
    UIUtil.set_text(self._txt_page, "0/0")
    UIUtil.set_active(self._btn_left, false)
    UIUtil.set_active(self._btn_right, false)
    self:_bind_side(self._side_views.left, {})
    self:_bind_side(self._side_views.right, {})
    return
  end
  local page_data = self._page_descriptors[self._current_page_index]
  UIUtil.set_text(self._txt_page, string.format("%d/%d", self._current_page_index, page_count))
  UIUtil.set_active(self._btn_left, self._current_page_index > 1)
  UIUtil.set_active(self._btn_right, page_count > self._current_page_index)
  self:_bind_side(self._side_views.left, page_data.left)
  self:_bind_side(self._side_views.right, page_data.right)
  self:_mark_page_entries_viewed(page_data)
end

function M:_mark_page_entries_viewed(page_data)
  if page_data == nil then
    return
  end
  local sides = {
    page_data.left,
    page_data.right
  }
  for _, side_entries in ipairs(sides) do
    for _, entry_context in ipairs(side_entries or {}) do
      local view_data = entry_context and entry_context.view_data or nil
      if view_data ~= nil and CsCompanionStarModuleUtil.IsDiaryEntryRedPointNew(view_data) then
        self:record_entry_viewed(view_data.unlockIndex)
        CsCompanionStarModuleUtil.ClearDiaryEntryRedPointState(view_data)
      end
    end
  end
end

function M:_get_side_big_item(side_view)
  if side_view.big_item then
    return side_view.big_item
  end
  local go = UIUtil.load_prefab_set_parent(self._right_template.gameObject, side_view.root)
  side_view.big_item = self:add_panel(card_item_cls, go)
  UIUtil.set_active(go, false)
  return side_view.big_item
end

function M:_get_side_small_item(side_view, index)
  if side_view.small_items[index] then
    return side_view.small_items[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._left_template.gameObject, side_view.root)
  local item = self:add_panel(card_item_cls, go)
  side_view.small_items[index] = item
  UIUtil.set_active(go, false)
  return item
end

function M:_bind_side(side_view, entry_contexts)
  local big_item = self:_get_side_big_item(side_view)
  local small_item_1 = self:_get_side_small_item(side_view, 1)
  local small_item_2 = self:_get_side_small_item(side_view, 2)
  big_item:set_active(false)
  small_item_1:set_active(false)
  small_item_2:set_active(false)
  if #entry_contexts == 1 and entry_contexts[1].is_big then
    big_item:refresh(entry_contexts[1].view_data, entry_contexts[1].entry_cfg, entry_contexts[1].style_cfg, entry_contexts[1].type_cfg)
    self:_bind_card_photo(big_item, entry_contexts[1])
    return
  end
  for index, entry_context in ipairs(entry_contexts) do
    local item = self:_get_side_small_item(side_view, index)
    item:refresh(entry_context.view_data, entry_context.entry_cfg, entry_context.style_cfg, entry_context.type_cfg)
    self:_bind_card_photo(item, entry_context)
  end
end

function M:_resolve_entry_file_key(entry_context, callback)
  if string.is_valid(entry_context.photo_alias) then
    CsAlbumManagerUtil.QueryPhotoAlias(entry_context.photo_alias, function(success, file_key)
      if success and string.is_valid(file_key) then
        callback(file_key)
        return
      end
      callback(string.is_valid(entry_context.file_key) and entry_context.file_key or nil)
    end)
    return
  end
  callback(nil)
end

function M:_bind_card_photo(card_item, entry_context)
  if card_item == nil or entry_context == nil or not entry_context.has_photo then
    return
  end
  local bind_version, bind_view_data, bind_file_key = card_item:get_photo_bind_snapshot()
  local request_npc_id = self._npc_id
  self:_resolve_entry_file_key(entry_context, function(resolved_file_key)
    if not (string.is_valid(resolved_file_key) and self:_is_async_context_valid(request_npc_id)) or not card_item:is_photo_bind_snapshot_valid(bind_version, bind_view_data, bind_file_key) then
      return
    end
    self:_prepare_album_photo(resolved_file_key, function(album_photo)
      if not (not is_null(album_photo) and self:_is_async_context_valid(request_npc_id)) or not card_item:is_photo_bind_snapshot_valid(bind_version, bind_view_data, bind_file_key) then
        return
      end
      if self:_try_apply_card_photo_texture(card_item, bind_version, bind_view_data, bind_file_key, request_npc_id, album_photo) then
        return
      end
      self:_ensure_album_photo_texture_ready(resolved_file_key, album_photo, function(success, loaded_photo)
        if success then
          self:_try_apply_card_photo_texture(card_item, bind_version, bind_view_data, bind_file_key, request_npc_id, loaded_photo)
        end
      end)
    end)
  end)
end

function M:_try_apply_card_photo_texture(card_item, bind_version, bind_view_data, bind_file_key, request_npc_id, album_photo)
  if not (not is_null(album_photo) and not is_null(album_photo.photoThumbnailSprite) and album_photo.photoThumbnailSprite.texture ~= nil and not is_null(card_item._photo_dynamic) and self:_is_async_context_valid(request_npc_id)) or not card_item:is_photo_bind_snapshot_valid(bind_version, bind_view_data, bind_file_key) then
    return false
  end
  card_item._photo_dynamic.texture = album_photo.photoThumbnailSprite.texture
  return true
end

function M:_ensure_album_photo_texture_ready(file_key, album_photo, callback)
  if not string.is_valid(file_key) or is_null(album_photo) then
    callback(false, album_photo)
    return
  end
  local cache_data = self._album_photo_cache[file_key]
  if cache_data == nil then
    callback(false, album_photo)
    return
  end
  if not is_null(album_photo.photoThumbnailSprite) and album_photo.photoThumbnailSprite.texture ~= nil then
    cache_data.texture_state = "ready"
    callback(true, album_photo)
    return
  end
  if cache_data.texture_state == "ready" then
    cache_data.texture_state = nil
  elseif cache_data.texture_state == "failed" then
    cache_data.texture_state = nil
  end
  cache_data.texture_callbacks = cache_data.texture_callbacks or {}
  if cache_data.texture_state == "loading" then
    table.insert(cache_data.texture_callbacks, callback)
    return
  end
  cache_data.texture_state = "loading"
  table.insert(cache_data.texture_callbacks, callback)
  album_photo:LoadPhotoThumbnailTextureAsync(function(success)
    local latest_cache = self._album_photo_cache[file_key]
    if latest_cache == nil then
      return
    end
    local texture_ready = success and not is_null(album_photo.photoThumbnailSprite) and album_photo.photoThumbnailSprite.texture ~= nil
    latest_cache.texture_state = texture_ready and "ready" or "failed"
    local callbacks = latest_cache.texture_callbacks or {}
    latest_cache.texture_callbacks = nil
    for _, cb in ipairs(callbacks) do
      cb(texture_ready, album_photo)
    end
  end)
end

function M:_prepare_album_photo(file_key, callback)
  if not string.is_valid(file_key) then
    callback(nil)
    return
  end
  local cache_data = self._album_photo_cache[file_key]
  if cache_data and cache_data.state == "ready" then
    callback(cache_data.photo)
    return
  end
  if cache_data and cache_data.state == "loading" then
    table.insert(cache_data.callbacks, callback)
    return
  end
  local raw_photo = CsAlbumManagerUtil.GetPhotoByCloudFileKey(file_key)
  if not_null(raw_photo) then
    self._album_photo_cache[file_key] = {
      state = "ready",
      photo = raw_photo,
      owned = false,
      texture_state = not is_null(raw_photo.photoThumbnailSprite) and raw_photo.photoThumbnailSprite.texture ~= nil and "ready" or nil
    }
    callback(raw_photo)
    return
  end
  self._album_photo_cache[file_key] = {
    state = "loading",
    callbacks = {callback},
    photo = nil,
    owned = true,
    texture_state = nil
  }
  CsAlbumManagerUtil.PrepareTemporaryCloudPhotoForPreview(file_key, function(success, album_photo)
    local prepared = self._album_photo_cache[file_key]
    if prepared == nil then
      if success and not is_null(album_photo) then
        CsAlbumManagerUtil.ReleaseTemporaryCloudPhotoForPreview(album_photo)
      end
      return
    end
    prepared.state = not (not success or is_null(album_photo)) and "ready" or "failed"
    prepared.photo = success and album_photo or nil
    prepared.texture_state = not (not success or is_null(album_photo) or is_null(album_photo.photoThumbnailSprite)) and album_photo.photoThumbnailSprite.texture ~= nil and "ready" or nil
    local callbacks = prepared.callbacks or {}
    prepared.callbacks = nil
    for _, cb in ipairs(callbacks) do
      cb(prepared.photo)
    end
  end)
end

function M:_release_album_photo_cache()
  for _, cache_data in pairs(self._album_photo_cache) do
    if cache_data and cache_data.owned and cache_data.photo and not is_null(cache_data.photo) then
      CsAlbumManagerUtil.ReleaseTemporaryCloudPhotoForPreview(cache_data.photo)
    end
  end
  self._album_photo_cache = {}
end

function M:_invalidate_album_photo_texture(file_key)
  local cache_data = self._album_photo_cache[file_key]
  if cache_data == nil then
    return
  end
  cache_data.texture_state = nil
  cache_data.texture_callbacks = nil
end

function M:_resolve_filter_groups()
  if self._filter_groups_cache ~= nil then
    return self._filter_groups_cache
  end
  local type_groups = {}
  local recorder_groups = {}
  local photo_count = 0
  local runtime_entries = list_to_table(CsCompanionStarModuleUtil.GetDiaryEntryViewDataList(self._npc_id, self._entry_red_point_gameplay_id)) or {}
  local filter_entry_contexts = self:_build_entry_contexts(runtime_entries)
  for _, entry_context in ipairs(filter_entry_contexts) do
    if entry_context.entry_cfg then
      local type_id = entry_context.entry_cfg.typeId or 0
      type_groups[type_id] = type_groups[type_id] or {
        key = type_id,
        label = stringify_text_map(entry_context.type_cfg and entry_context.type_cfg.displayName or nil),
        count = 0,
        icon_path = "",
        style_state_id = entry_context.type_cfg and entry_context.type_cfg.styleStateId or 0
      }
      type_groups[type_id].count = type_groups[type_id].count + 1
    end
    recorder_groups[entry_context.recorder_type] = recorder_groups[entry_context.recorder_type] or {
      key = entry_context.recorder_type,
      label = UIUtil.get_text_by_id(entry_context.recorder_type == RecorderTypeEnum.Player and "NpcStar_Diary_Recorder_Player" or "NpcStar_Diary_Recorder_Npc"),
      label_text_id = entry_context.recorder_type == RecorderTypeEnum.Player and "NpcStar_Diary_Recorder_Player" or "NpcStar_Diary_Recorder_Npc",
      count = 0,
      icon_path = ""
    }
    recorder_groups[entry_context.recorder_type].count = recorder_groups[entry_context.recorder_type].count + 1
    if entry_context.has_photo then
      photo_count = photo_count + 1
    end
  end
  self._filter_groups_cache = {
    {
      group_key = "type",
      selection_mode = "multi",
      title_text_id = "NpcStar_Diary_Select_Type",
      use_color_state = true,
      items = dict_to_sorted_list(type_groups, function(a, b)
        return (a.key or 0) < (b.key or 0)
      end)
    },
    {
      group_key = "recorder",
      selection_mode = "multi",
      title_text_id = "NpcStar_Diary_Select_Recorder",
      items = dict_to_sorted_list(recorder_groups, function(a, b)
        return tostring(a.label or "") < tostring(b.label or "")
      end)
    },
    {
      group_key = "photo",
      selection_mode = "single",
      title_text_id = "NpcStar_Diary_Select_Image",
      items = {
        {
          key = true,
          label_text_id = "NpcStar_Diary_Image_Only",
          count = photo_count,
          icon_path = ""
        }
      }
    }
  }
  return self._filter_groups_cache
end

function M:_open_filter_dialog()
  self:_refresh_shell_state()
  UIManagerInstance:open(filter_dialog_path, {
    groups = self:_resolve_filter_groups(),
    selected = query_state_to_filter_selected(self._draft_filter_state, self._filter_selected_cache),
    on_confirm = function(selected)
      local query_state = filter_selected_to_query_state(selected, self._draft_filter_state, self._filter_query_state_cache)
      self:_apply_confirmed_filter_state(query_state)
    end
  })
end

function M:_on_click_prev_page()
  if self._current_page_index <= 1 then
    return
  end
  self._current_page_index = self._current_page_index - 1
  self:_play_book_spine_animation("turnleft", false)
  self:_refresh_page()
end

function M:_on_click_next_page()
  if self._current_page_index >= #self._page_descriptors then
    return
  end
  self._current_page_index = self._current_page_index + 1
  self:_play_book_spine_animation("turnright", false)
  self:_refresh_page()
end

function M:_play_book_spine_animation(animation_name, loop)
  if is_null(self._book_spine) or not string.is_valid(animation_name) then
    return
  end
  CsUIUtil.PlaySkeletonGraphicAnimation(self._book_spine, animation_name, loop == true)
end

function M:_can_apply_book_spine_style()
  return not is_null(self._book_spine) and not is_null(self._book_spine.gameObject) and self._book_spine.gameObject.activeInHierarchy and self._book_spine.IsValid == true
end

function M:_apply_diary_background_illustrations()
  local style_cfg = self:_get_style_cfg_by_npc_id(self._npc_id)
  clear_image_if_valid(self._left_diary_illustration)
  clear_image_if_valid(self._right_diary_illustration)
  clear_image_if_valid(self._left_diary_art_word)
  clear_image_if_valid(self._right_diary_art_word)
  if style_cfg ~= nil and not is_null(self._diary_style_binding_group) then
    self._diary_style_binding_group:Apply(style_cfg, self:get_load_proxy())
  end
end

function M:_apply_book_spine_style(force_style_cfg)
  if not self:_can_apply_book_spine_style() then
    return
  end
  local style_cfg = force_style_cfg
  if style_cfg == nil then
    local page_data = self._page_descriptors[self._current_page_index]
    local page_entries = page_data and (page_data.left and #page_data.left > 0 and page_data.left or page_data.right) or nil
    local entry_context = page_entries and page_entries[1] or self._entry_contexts[1]
    if entry_context then
      style_cfg = entry_context.style_cfg
    end
  end
  if is_null(self._book_spine_style_binding_group) then
    self:_play_book_spine_animation("in", false)
    return
  end
  if style_cfg ~= nil then
    self._book_spine_style_binding_group:Apply(style_cfg, self:get_load_proxy())
  else
    self._book_spine_style_binding_group:ClearTarget("bookSpineTexturePath")
  end
  self:_play_book_spine_animation("in", false)
end

function M:refresh_shell_state(is_shell_host_active)
  if is_shell_host_active ~= nil then
    self._is_shell_host_active = is_shell_host_active == true
  end
  self:_refresh_shell_state()
end

function M:record_entry_viewed(unlock_index)
  if self._entry_red_point_gameplay_id == 0 or self._npc_id == 0 or unlock_index == nil then
    return
  end
  CsCompanionStarModuleUtil.RecordDiaryEntryViewed(self._entry_red_point_gameplay_id, self._npc_id, unlock_index)
end

function M:_open_share_dialog(view_data, entry_cfg, style_cfg, type_cfg, album_photo)
  if self._is_opening_share_dialog then
    return
  end
  self._is_opening_share_dialog = true
  local holder = self.holder
  local dialog_data = {
    view_data = view_data,
    entry_cfg = entry_cfg,
    style_cfg = style_cfg,
    type_cfg = type_cfg,
    album_photo = album_photo
  }
  self._is_opening_share_dialog = false
  UIManagerInstance:open(share_dialog_path, dialog_data)
end

function M:on_card_share(view_data, entry_cfg, style_cfg, type_cfg)
  if view_data == nil or entry_cfg == nil then
    return
  end
  if (view_data.photoReviewStatus or 0) == 1 then
    return
  end
  local photo_alias = entry_cfg.photoAlias or ""
  local file_key = view_data.fileKey or ""
  local request_npc_id = self._npc_id
  
  local function open_share_with_photo(resolved_file_key)
    if not string.is_valid(resolved_file_key) then
      self:_open_share_dialog(view_data, entry_cfg, style_cfg, type_cfg, nil)
      return
    end
    self:_prepare_album_photo(resolved_file_key, function(album_photo)
      if not self:_is_async_context_valid(request_npc_id) then
        return
      end
      self:_open_share_dialog(view_data, entry_cfg, style_cfg, type_cfg, album_photo)
    end)
  end
  
  if string.is_valid(photo_alias) then
    CsAlbumManagerUtil.QueryPhotoAlias(photo_alias, function(success, resolved_key)
      if not self:_is_async_context_valid(request_npc_id) then
        return
      end
      if success and string.is_valid(resolved_key) then
        open_share_with_photo(resolved_key)
        return
      end
      open_share_with_photo(string.is_valid(file_key) and file_key or nil)
    end)
  else
    open_share_with_photo(nil)
  end
end

function M:on_card_photo_preview(view_data, entry_cfg)
  if view_data == nil or entry_cfg == nil then
    return
  end
  local photo_alias = entry_cfg.photoAlias or ""
  local file_key = view_data.fileKey or ""
  local request_npc_id = self._npc_id
  
  local function open_preview_with_photo(resolved_file_key)
    if not string.is_valid(resolved_file_key) then
      return
    end
    self:_prepare_album_photo(resolved_file_key, function(album_photo)
      if not self:_is_async_context_valid(request_npc_id) or is_null(album_photo) then
        return
      end
      UIManagerInstance:open("UI/Photography/PhotoPreviewDialog", {
        photo_list = {album_photo},
        index = 1,
        mode = photo_module.PreviewMode.AlbumPhoto,
        hide_delete = true,
        action = function()
          if not self:_is_async_context_valid(request_npc_id) then
            return
          end
          self:_invalidate_album_photo_texture(resolved_file_key)
          self:_refresh_page()
        end
      })
    end)
  end
  
  if string.is_valid(photo_alias) then
    CsAlbumManagerUtil.QueryPhotoAlias(photo_alias, function(success, resolved_key)
      if not self:_is_async_context_valid(request_npc_id) then
        return
      end
      if success and string.is_valid(resolved_key) then
        open_preview_with_photo(resolved_key)
        return
      end
      open_preview_with_photo(string.is_valid(file_key) and file_key or nil)
    end)
  else
    open_preview_with_photo(string.is_valid(file_key) and file_key or nil)
  end
end

return M
