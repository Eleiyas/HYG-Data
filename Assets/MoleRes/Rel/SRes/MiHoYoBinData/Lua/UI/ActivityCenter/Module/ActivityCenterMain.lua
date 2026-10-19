activity_center_module = activity_center_module or {}
local ACTIVITY_TRACKING_TIPS_TRANSACTION_KEY = "activity_tracking_tips"
activity_center_module._tracking_navigation_resolvers = activity_center_module._tracking_navigation_resolvers or {}

function activity_center_module:add_event()
  activity_center_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOpenActivityCenter] = pack(self, activity_center_module.open_main_page)
  self._events[EventID.LuaCloseActivityCenter] = pack(self, activity_center_module.close_main_page)
  self._events[EventID.OnActivityListChanged] = pack(self, activity_center_module.on_activity_list_changed)
  self._events[EventID.OnActivityDataChanged] = pack(self, activity_center_module.on_activity_data_changed)
  self._events[EventID.OnActivityRemoved] = pack(self, activity_center_module.on_activity_removed)
  self._events[EventID.onDailyRefresh] = pack(self, activity_center_module.on_daily_refresh)
  self._events[EventID.LuaOpenActivityDescription] = pack(self, activity_center_module.open_activity_description)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function activity_center_module.on_activity_list_changed()
  activity_center_module:clear_activity_time_cache()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

function activity_center_module.on_activity_data_changed(activity_id)
  activity_center_module:clear_activity_time_cache()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

function activity_center_module.on_activity_removed(activity_id)
  activity_center_module:clear_activity_time_cache()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

function activity_center_module.on_daily_refresh()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

function activity_center_module:open_activity_description(intro_id)
  if intro_id and 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

function activity_center_module:show_activity_introduction_dialog(activity_id, introduction_cfg_id)
  if introduction_cfg_id == nil or introduction_cfg_id <= 0 then
    Logger.LogWarning("[ActivityCenter] show_activity_introduction_dialog: invalid introduction_cfg_id = " .. tostring(introduction_cfg_id))
    return
  end
  UIManagerInstance:open(self.introduction_dialog_class_path, {
    activity_id = activity_id or 0,
    introduction_cfg_id = introduction_cfg_id
  })
end

function activity_center_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function activity_center_module:is_unlocked()
  return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateActivityCenter)
end

function activity_center_module:register_tracking_navigation_resolver(key, resolver)
  if not string.is_valid(key) or type(resolver) ~= "function" then
    Logger.LogWarning("[ActivityCenter] register_tracking_navigation_resolver: invalid arguments.")
    return
  end
  for _, entry in ipairs(self._tracking_navigation_resolvers) do
    if entry.key == key then
      entry.resolver = resolver
      return
    end
  end
  table.insert(self._tracking_navigation_resolvers, {key = key, resolver = resolver})
end

function activity_center_module:unregister_tracking_navigation_resolver(key)
  for index = #self._tracking_navigation_resolvers, 1, -1 do
    if self._tracking_navigation_resolvers[index].key == key then
      table.remove(self._tracking_navigation_resolvers, index)
      return
    end
  end
end

function activity_center_module:_resolve_tracking_navigation(source_activity_id)
  for _, entry in ipairs(self._tracking_navigation_resolvers) do
    local navigation = entry.resolver(source_activity_id)
    if navigation ~= nil then
      return navigation
    end
  end
  if self:is_activity_list_host(source_activity_id) then
    return {host_activity_id = source_activity_id}
  end
  return nil
end

function activity_center_module:_open_main_page_with_focus(activity_id, on_detail_ready)
  if not self:is_unlocked() then
    Logger.LogWarning("[ActivityCenter] open_main_page: system not unlocked.")
    return false
  end
  activity_id = activity_id or 0
  if 0 < activity_id and not self:is_activity_list_host(activity_id) then
    Logger.LogWarning("[ActivityCenter] open_main_page: invalid activity_id = " .. tostring(activity_id))
    return false
  end
  local focus_category = self.default_category
  if 0 < activity_id then
    focus_category = self:get_category_by_activity_id(activity_id)
  end
  UIManagerInstance:open(self.main_page_class_path, {
    focus_activity_id = activity_id,
    focus_category = focus_category,
    on_detail_ready = on_detail_ready
  })
  return true
end

function activity_center_module:open_activity_from_tracking(source_activity_id)
  local navigation = self:_resolve_tracking_navigation(source_activity_id)
  if navigation == nil then
    Logger.LogWarning("[ActivityCenter] tracking navigation unavailable, activity_id = " .. tostring(source_activity_id))
    return false
  end
  return self:_open_main_page_with_focus(navigation.host_activity_id, navigation.open_content)
end

function activity_center_module:open_main_page()
  local focus_id = CsActivityCenterModuleUtil.GetFirstShowSelectedActivityId()
  return self:_open_main_page_with_focus(focus_id, nil)
end

function activity_center_module:close_main_page()
  local page = UIManagerInstance:is_show(self.main_page_class_path)
  if page ~= nil and page.is_active then
    UIManagerInstance:close(page.guid)
  end
end

function activity_center_module:is_main_page_open()
  if UIManagerInstance == nil then
    return false
  end
  return UIManagerInstance:is_in_stack(self.main_page_class_path)
end

activity_center_module._list_refresh_holders = activity_center_module._list_refresh_holders or {}

function activity_center_module:hold_list_refresh(key)
  if not string.is_valid(key) then
    Logger.LogWarning("[ActivityCenter] hold_list_refresh: invalid key.")
    return
  end
  self._list_refresh_holders[key] = true
end

function activity_center_module:release_list_refresh(key)
  if not string.is_valid(key) then
    return
  end
  self._list_refresh_holders[key] = nil
end

function activity_center_module:is_list_refresh_held()
  return next(self._list_refresh_holders) ~= nil
end

activity_center_module._activity_end_dialog_shown = activity_center_module._activity_end_dialog_shown or {}

function activity_center_module:_normalize_activity_end_key(key)
  if string.is_valid(key) then
    return key
  end
  return self.activity_end_gate_key_prefix .. "default"
end

function activity_center_module:make_activity_end_gate_key(activity_id)
  return self.activity_end_gate_key_prefix .. tostring(activity_id or 0)
end

function activity_center_module:show_activity_end_dialog(on_confirm, opts)
  opts = opts or {}
  local key = self:_normalize_activity_end_key(opts.key)
  if self._activity_end_dialog_shown[key] then
    return
  end
  self._activity_end_dialog_shown[key] = true
  self:hold_list_refresh(key)
  local text_id = opts.text_id
  if not string.is_valid(text_id) then
    text_id = self.activity_end_dialog_text_id
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_texts(UIUtil.get_text_by_id(text_id), UIUtil.get_text_by_id("Common_Accept"), nil, nil)
  popup:set_callbacks(function()
    if on_confirm ~= nil then
      on_confirm()
    end
    self:release_activity_end_refresh_gate(key)
  end)
  popup:show()
end

function activity_center_module:release_activity_end_refresh_gate(key)
  self:release_list_refresh(self:_normalize_activity_end_key(key))
end

function activity_center_module:reset_activity_end_dialog_flag(key)
  self._activity_end_dialog_shown[self:_normalize_activity_end_key(key)] = nil
end

function activity_center_module:show_activity_expire_tips()
  UIUtil.show_tips_by_text_id(self.activity_expire_tips_text_id)
end

function activity_center_module:request_refresh_list()
  EventCenter.Broadcast(EventID.OnActivityListChanged, nil)
end

local function _match_effect_field(effect_str, current_value)
  if not string.is_valid(effect_str) then
    return true
  end
  local first = string.sub(effect_str, 1, 1)
  local body = string.sub(effect_str, 2)
  local is_white = first == "+"
  local is_black = first == "-"
  if not is_white and not is_black then
    Logger.LogWarning("[ActivityCenter] EffectField missing +/- prefix: '" .. tostring(effect_str) .. "'")
    return true
  end
  if not string.is_valid(body) then
    return true
  end
  current_value = current_value or ""
  local found = false
  for token in string.gmatch(body, "([^,]+)") do
    local t = string.gsub(token, "^%s*(.-)%s*$", "%1")
    if t == current_value then
      found = true
      break
    end
  end
  if is_white then
    return found
  end
  return not found
end

local function _is_jump_cfg_match(cfg, current_pkg, current_ip, current_lang, current_server)
  return _match_effect_field(cfg.effectpackage, current_pkg) and _match_effect_field(cfg.effectip, current_ip) and _match_effect_field(cfg.effectlanguage, current_lang) and _match_effect_field(cfg.effectserver, current_server)
end

function activity_center_module:request_jump(jump_id)
  if jump_id == nil or jump_id == 0 then
    Logger.LogWarning("[ActivityCenter] request_jump: invalid jump_id = " .. tostring(jump_id))
    return
  end
  local cfg_list = list_to_table(ExcelDataUtil.get_value(typeof(BActivityJumpToCfg), jump_id))
  if cfg_list == nil or cfg_list[1] == nil then
    Logger.LogWarning("[ActivityCenter] request_jump: missing BActivityJumpToCfg, id = " .. tostring(jump_id))
    return
  end
  local picked = cfg_list[1]
  if cfg_list[2] ~= nil then
    local game_cfg = CsGameManagerUtil and CsGameManagerUtil.gameConfig or nil
    local current_pkg = game_cfg ~= nil and (game_cfg.changeList or "") or ""
    local current_ip = CsNetManagerUtil.GetIP() or ""
    local current_lang = CsLocalizationManagerUtil.curLanguageStr or ""
    local current_server = CsNetManagerUtil.GetCurrentServerConfig().name or ""
    for i = 1, #cfg_list do
      local cfg = cfg_list[i]
      if _is_jump_cfg_match(cfg, current_pkg, current_ip, current_lang, current_server) then
        picked = cfg
        break
      end
    end
  end
  local site = picked.jumptosite
  if not string.is_valid(site) then
    Logger.LogWarning("[ActivityCenter] request_jump: empty jumptosite, jump_id = " .. tostring(jump_id))
    return
  end
  if picked.jumptotype and picked.jumptotype == 2 then
    CsOpenURLUtil.OpenUrlExternal(site)
  else
    CsOpenURLUtil.OpenUrl(site)
  end
end

function activity_center_module:resolve_panel_for_activity(activity_id)
  local data = self:get_activity_by_id(activity_id)
  if data == nil then
    return self.default_activity_panel_class, nil
  end
  local activity_type = data.Type
  local lua_class = self:get_panel_class_by_type(activity_type)
  local prefab_path = self:get_prefab_path(activity_id)
  return lua_class, prefab_path
end

function activity_center_module:toggle_tracking(target)
  if target == nil then
    return
  end
  local kind = self.tracking_kind
  if target.kind == kind.task then
    self:_open_memo_for_task(target)
  elseif target.kind == kind.feature then
    self:_toggle_feature_tracking(target)
  else
    Logger.LogWarning("[ActivityCenter] toggle_tracking: unknown kind = " .. tostring(target.kind))
  end
end

function activity_center_module:_open_memo_for_task(target)
  if self:is_tracking(target) then
    tracking_module:set_tracking_by_track_type(target.track_type, target.source_type, target.tracking_id, false, true)
    return
  end
  local task_id = target.tracking_id
  if not self:is_task_navigable(task_id) then
    Logger.LogWarning("[ActivityCenter] tracking: task not navigable, task_id = " .. tostring(task_id))
    return
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(task_id)
  local grouping_type = memo_module.grouping_type.none
  if not_null(step_cfg) then
    grouping_type = step_cfg.GroupingType or memo_module.grouping_type.none
  end
  if grouping_type == memo_module.grouping_type.none then
    Logger.LogWarning("[ActivityCenter] tracking: invalid grouping_type, task_id = " .. tostring(task_id))
    return
  end
  UIManagerInstance:close_all_stack_window_without_main_page()
  memo_module:open_memo_page(false, memo_module.tab_type.task, grouping_type, task_id)
end

function activity_center_module:_toggle_feature_tracking(target)
  if self:is_tracking(target) then
    tracking_module:set_tracking_by_track_type(target.track_type, target.source_type, target.tracking_id, false, true)
    return
  end
  self:start_feature_tracking(target)
end

function activity_center_module:start_feature_tracking(target)
  if target == nil or target.kind ~= self.tracking_kind.feature then
    return false
  end
  local tips_id = self:get_tracking_tips_id(target.tracking_cfg_id)
  
  local function on_confirmed(is_scene_change_requested)
    local started_tracking = false
    if not self:is_tracking(target) then
      tracking_module:set_tracking_by_track_type(target.track_type, target.source_type, target.tracking_id, true, true)
      started_tracking = true
    end
    tracking_module:set_cur_track_type(target.track_type)
    if started_tracking and string.is_valid(tips_id) and not CsStarSeaUtil.IsCurrentSceneMaterialStar() then
      if not is_scene_change_requested then
        UIUtil.show_tips_by_text_id(tips_id)
      elseif UIIdleDetectManagerIns ~= nil then
        UIIdleDetectManagerIns:enqueue_after_loading_transaction(ACTIVITY_TRACKING_TIPS_TRANSACTION_KEY, function()
          UIUtil.show_tips_by_text_id(tips_id)
          return true
        end)
      end
    end
    UIManagerInstance:close_all_stack_window_without_main_page()
  end
  
  if not CsActivityCenterModuleUtil.InvokeTrackingClickAction(target.tracking_id, on_confirmed) then
    Logger.LogWarning("[ActivityCenter] feature tracking action unavailable, tracking_cfg_id = " .. tostring(target.tracking_cfg_id) .. ", activity_id = " .. tostring(target.tracking_id))
    return false
  end
  return true
end

return activity_center_module
