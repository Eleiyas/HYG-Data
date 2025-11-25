player_visit_module = player_visit_module or {}
local player_visit_page_cls = "UI/PlayerVisit/PlayerVisitPage"
local player_visit_permission_dropdownitem_cls = "UI/PlayerVisit/PlayerVisitPermissionDropdownitemPanel"
local player_visit_permission_option_cls = "UI/PlayerVisit/PlayerVisitPermissionOptionItem"
local player_visit_record_item_cls = "UI/PlayerVisit/PlayerVisitRecordItem"

function player_visit_module:add_event()
  player_visit_module:remove_event()
  self._events = {}
  self._events[EventID.OnPlayerApplyVisitTips] = pack(self, player_visit_module._player_apply_visit_tips)
  self._events[EventID.OnPlayerVisitTips] = pack(self, player_visit_module._player_visit_tips_no_ask)
  self._events[EventID.OnPlayerOnRouteTips] = pack(self, player_visit_module._player_on_route_tips)
  self._events[EventID.OnPermissionTypeChangeAskType] = pack(self, player_visit_module._on_permission_type_change)
  self._events[EventID.LuaShowVisitResTips] = pack(self, player_visit_module._on_show_visit_res_tips)
  self._events[EventID.OnEnterMultiWorldQueryTips] = pack(self, player_visit_module._on_enter_multi_world_query_tips)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function player_visit_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function player_visit_module:_open_player_visit_page()
  local page = UIManagerInstance:is_show(player_visit_page_cls)
  if is_null(page) then
    UIManagerInstance:open(player_visit_page_cls)
    self.player_visit_page = page
  else
    page:set_active(true)
    self.player_visit_page = page
  end
end

function player_visit_module:_player_apply_visit_tips(notify)
  local from_uid = notify.FromUid
  local avatar_id = notify.FromPlayerAvatarId
  if is_null(from_uid) then
    Logger.LogWarning("PlayerVisitMain: _player_apply_visit_tips - from_uid is null")
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
    uid = from_uid,
    avatar_id = avatar_id,
    interact_type = social_module.social_multi_play_visite_interact_type.apply,
    source = "player_visit",
    callback = function(from_uid, accept)
      if is_null(from_uid) then
        Logger.LogWarning("PlayerVisitMain: apply visit callback - from_uid is null")
        return
      end
      CsPlayerVisitModuleUtil.SocialPlayerGotoSelfWorldoperateReq(from_uid, accept)
    end
  })
end

function player_visit_module:_on_enter_multi_world_query_tips(notify)
  local from_uid = notify.FromUid
  local from_name = notify.FromPlayerName or ""
  local avatar_id = notify.FromPlayerAvatarId
  if is_null(from_uid) then
    Logger.LogWarning("PlayerVisitMain: _player_apply_visit_tips - from_uid is null")
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
    uid = from_uid,
    avatar_id = avatar_id,
    from_name = from_name,
    interact_type = social_module.social_multi_play_visite_interact_type.first_query,
    source = "player_visit",
    callback = function(from_uid, accept)
      if is_null(from_uid) then
        Logger.LogWarning("PlayerVisitMain: apply visit callback - from_uid is null")
        return
      end
      CsPlayerVisitModuleUtil.SocialPlayerGotoSelfWorldoperateReq(from_uid, accept)
    end
  })
end

function player_visit_module:_player_visit_tips_no_ask(player_name)
  if is_null(player_name) then
    Logger.LogWarning("PlayerVisitMain: _player_visit_tips_no_ask - player_name is null")
    return
  end
end

function player_visit_module:_player_on_route_tips(player_name)
  if is_null(player_name) then
    Logger.LogWarning("PlayerVisitMain: _player_visit_tips_no_ask - player_name is null")
    return
  end
  local name = UIUtil.get_text_by_id("Friend_Star_name", player_name)
  UIManagerInstance:open("UI/Tips/OnRouteTips", {
    name = name,
    desc = UIUtil.get_text_by_id("Route_notice")
  })
end

function player_visit_module:_on_show_visit_res_tips(res_type)
  if is_null(res_type) then
    Logger.LogWarning("PlayerVisitMain: _on_show_visit_res_tips - res_type is null")
    return
  end
  if res_type == 0 then
    local tips_info = {}
    tips_info.txt = UIUtil.get_text_by_id("Visit_quest")
    tips_info.duration = 3
    EventCenter.Broadcast(EventID.LuaShowTips, tips_info)
  end
  if res_type == 3 then
    local tips_info = {}
    tips_info.txt = UIUtil.get_text_by_id("Visit_decline")
    tips_info.duration = 3
    EventCenter.Broadcast(EventID.LuaShowTips, tips_info)
  end
  if res_type == 1 then
    local tips_info = {}
    tips_info.txt = UIUtil.get_text_by_id("Visit_forbidden")
    tips_info.duration = 3
    EventCenter.Broadcast(EventID.LuaShowTips, tips_info)
  end
  if res_type == 2 then
    local tips_info = {}
    tips_info.txt = UIUtil.get_text_by_id("Visit_offline")
    tips_info.duration = 3
    EventCenter.Broadcast(EventID.LuaShowTips, tips_info)
  end
  if res_type == 4 then
    local tips_info = {}
    tips_info.txt = UIUtil.get_text_by_id("Visit_full")
    tips_info.duration = 3
    EventCenter.Broadcast(EventID.LuaShowTips, tips_info)
  end
end

function player_visit_module:_on_permission_type_change(option_id)
  if is_null(option_id) then
    Logger.LogWarning("PlayerVisitMain: _on_permission_type_change - option_id is null")
    return
  end
  local ask_types = self:get_permission_map_ask_type(option_id)
  if is_null(ask_types) then
    Logger.LogWarning("PlayerVisitMain: _on_permission_type_change - ask_types is null")
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.on_permission_type_change_ask_type, ask_types)
end

function player_visit_module:add_entry(uiwindow, entry_pool, active_entries, prefab_transform, parent_transform, panel_class, refresh_callback)
  if is_null(uiwindow) or is_null(entry_pool) or is_null(active_entries) or is_null(prefab_transform) or is_null(parent_transform) then
    Logger.LogWarning("PlayerVisitMain: add_entry - required parameters are null")
    return nil
  end
  local entry
  if 0 < #entry_pool then
    entry = table.remove(entry_pool)
  else
    if is_null(prefab_transform.gameObject) then
      Logger.LogWarning("PlayerVisitMain: add_entry - prefab_transform.gameObject is null")
      return nil
    end
    local obj = UIUtil.load_prefab_set_parent(prefab_transform.gameObject, parent_transform)
    if is_null(obj) then
      Logger.LogWarning("PlayerVisitMain: add_entry - failed to load prefab")
      return nil
    end
    if panel_class then
      entry = uiwindow:add_panel(panel_class, obj)
      if is_null(entry) then
        Logger.LogWarning("PlayerVisitMain: add_entry - failed to add panel")
        return nil
      end
    else
      entry = obj
    end
  end
  if entry.trans then
    entry.trans:SetParent(parent_transform)
    entry.trans:SetAsLastSibling()
    entry:set_active(true)
  else
    entry.transform:SetParent(parent_transform)
    entry.transform:SetAsLastSibling()
    UIUtil.set_active(entry, true)
  end
  if refresh_callback and type(refresh_callback) == "function" then
    refresh_callback(entry)
  end
  table.insert(active_entries, entry)
  return entry
end

function player_visit_module:clear_and_recycle_entries(active_entries, entry_pool)
  for _, entry in ipairs(active_entries) do
    if entry.trans then
      entry:set_active(false)
    else
      UIUtil.set_active(entry, false)
    end
    table.insert(entry_pool, entry)
  end
  active_entries = {}
end

function player_visit_module:refresh_player_visit_permission(uiwindow, pools, prefab_transform, parent_transform)
  if is_null(uiwindow) or is_null(pools) or is_null(prefab_transform) or is_null(parent_transform) then
    Logger.LogWarning("PlayerVisitMain: refresh_player_visit_permission - required parameters are null")
    return
  end
  if is_null(pools.visit_permission_dropdownitem_pool) then
    Logger.LogWarning("PlayerVisitMain: refresh_player_visit_permission - visit_permission_dropdownitem_pool is null")
    return
  end
  if is_null(player_visit_module.permission_info) then
    Logger.LogWarning("PlayerVisitMain: refresh_player_visit_permission - permission_info is null")
    return
  end
  self:clear_and_recycle_entries(pools.visit_permission_dropdownitem_pool.active, pools.visit_permission_dropdownitem_pool.pool)
  pools.visit_permission_dropdownitem_pool.active = {}
  for id, permission_info in ipairs(player_visit_module.permission_info) do
    self:add_entry(uiwindow, pools.visit_permission_dropdownitem_pool.pool, pools.visit_permission_dropdownitem_pool.active, prefab_transform, parent_transform, player_visit_permission_dropdownitem_cls, function(entry)
      entry:set_info(permission_info[1].permissionname, id)
    end)
  end
end

function player_visit_module:refresh_visit_permission_options(uiwindow, pools, prefab_transform, parent_transform, option_cfgs, permission_id)
  if is_null(uiwindow) or is_null(pools) or is_null(prefab_transform) or is_null(parent_transform) or is_null(option_cfgs) or is_null(permission_id) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_permission_options - required parameters are null")
    return
  end
  if is_null(pools.visit_permission_option_pool) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_permission_options - visit_permission_option_pool is null")
    return
  end
  self:clear_and_recycle_entries(pools.visit_permission_option_pool.active, pools.visit_permission_option_pool.pool)
  pools.visit_permission_option_pool.active = {}
  for _, option_cfg in pairs(option_cfgs) do
    self:add_entry(uiwindow, pools.visit_permission_option_pool.pool, pools.visit_permission_option_pool.active, prefab_transform, parent_transform, player_visit_permission_option_cls, function(entry)
      entry:refresh_option(option_cfg, permission_id)
      uiwindow:bind_callback(entry._toggle, function(is_on)
        entry:on_toggle_click(is_on)
      end)
    end)
  end
end

function player_visit_module:refresh_visit_record_list(uiwindow, pools, prefab_transform, parent_transform)
  if is_null(uiwindow) or is_null(pools) or is_null(prefab_transform) or is_null(parent_transform) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_list - required parameters are null")
    return
  end
  if is_null(pools.visit_record_item_pool) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_list - visit_record_item_pool is null")
    return
  end
  local record_infos = player_visit_module:get_player_visit_list()
  if is_null(record_infos) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_list - record_infos is null")
    return
  end
  self:clear_and_recycle_entries(pools.visit_record_item_pool.active, pools.visit_record_item_pool.pool)
  pools.visit_record_item_pool.active = {}
  for _, record in pairs(record_infos) do
    if not is_null(record) then
      self:add_entry(uiwindow, pools.visit_record_item_pool.pool, pools.visit_record_item_pool.active, prefab_transform, parent_transform, player_visit_record_item_cls, function(entry)
        entry:refresh_record(record)
      end)
    end
  end
end

function player_visit_module:refresh_visit_record_detail(uiwindow, pools, prefab_transform, parent_transform, visitor_uid, time)
  if is_null(uiwindow) or is_null(pools) or is_null(prefab_transform) or is_null(parent_transform) or is_null(visitor_uid) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_detail - required parameters are null")
    return
  end
  if is_null(pools.visit_record_detail_item_pool) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_detail - visit_record_detail_item_pool is null")
    return
  end
  local record_infos = player_visit_module:get_player_visit_record_info()
  if is_null(record_infos) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_detail - record_infos is null")
    return
  end
  local record_info = list_to_table(record_infos[visitor_uid .. "-" .. time])
  if is_null(record_info) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_detail - record_info is null for visitor_uid: " .. tostring(visitor_uid))
    return
  end
  local record_detail_info = player_visit_module:get_player_visit_record_detail_info(record_info)
  if is_null(record_detail_info) then
    Logger.LogWarning("PlayerVisitMain: refresh_visit_record_detail - record_detail_info is null")
    return
  end
  self:clear_and_recycle_entries(pools.visit_record_detail_item_pool.active, pools.visit_record_detail_item_pool.pool)
  pools.visit_record_detail_item_pool.active = {}
  for _, record_detail in pairs(record_detail_info) do
    self:add_entry(uiwindow, pools.visit_record_detail_item_pool.pool, pools.visit_record_detail_item_pool.active, prefab_transform, parent_transform, player_visit_record_item_cls, function(entry)
      entry:_refresh_detail_record(record_info[1].VisitorName, record_info[1].AvatarId, record_detail)
    end)
  end
end

return player_visit_module
