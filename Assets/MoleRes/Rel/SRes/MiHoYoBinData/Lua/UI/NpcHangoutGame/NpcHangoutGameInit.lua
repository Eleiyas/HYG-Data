npc_hangout_game_module = npc_hangout_game_module or {}
npc_hangout_game_module._cname = "npc_hangout_game_module"
npc_hangout_game_module.npc_hangout_game_status = {
  None = 0,
  Started = 1,
  Completed = 2,
  Suspended = 3,
  Failed = 4,
  ContestEnd = 5
}
local controller_class_path = "UI/NpcHangoutGame/NpcHangoutGameUIController"

local function is_side_panel_status(status)
  return status == npc_hangout_game_module.npc_hangout_game_status.Started or status == npc_hangout_game_module.npc_hangout_game_status.ContestEnd
end

function npc_hangout_game_module:init()
  self._controller = nil
  self._events = {
    [EventID.NpcHangoutGameChanged] = pack(self, self._on_game_changed),
    [EventID.NpcHangoutGameRemoved] = pack(self, self._on_game_removed),
    [EventID.LuaShowNpcHangoutGameStartTip] = pack(self, self._on_show_start_tip),
    [EventID.LuaShowNpcHangoutGameCompleteTip] = pack(self, self._on_show_complete_tip)
  }
  for event_id, callback in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, callback)
  end
  self._main_page_active_callback = pack(self, self._on_main_page_active)
  lua_event_module:add_listener(lua_event_module.event_type.dispatch_main_page_active, self._main_page_active_callback)
end

function npc_hangout_game_module:close()
  if self._events then
    for event_id, callback in pairs(self._events) do
      EventCenter.LuaRemoveListener(event_id, callback)
    end
  end
  self._events = nil
  if self._main_page_active_callback then
    lua_event_module:remove_listener(lua_event_module.event_type.dispatch_main_page_active, self._main_page_active_callback)
    self._main_page_active_callback = nil
  end
  self:_release_controller()
end

function npc_hangout_game_module:on_level_prepare()
  local active_ids = CsNpcHangoutGameManagerUtil.GetActiveHangoutIds()
  if is_null(active_ids) then
    return
  end
  for i = 0, active_ids.Count - 1 do
    local context = CsNpcHangoutGameManagerUtil.GetUIContext(active_ids[i])
    if not_null(context) and is_side_panel_status(context.status) then
      self:_get_controller():refresh(active_ids[i])
      return
    end
  end
end

function npc_hangout_game_module:on_level_destroy()
  self:_release_controller()
end

function npc_hangout_game_module:clear_on_disconnect()
  self:_release_controller()
end

function npc_hangout_game_module:_get_controller()
  if self._controller == nil then
    self._controller = G.New(controller_class_path)
  end
  return self._controller
end

function npc_hangout_game_module:_release_controller()
  if self._controller then
    self._controller:close()
    self._controller = nil
  end
end

function npc_hangout_game_module:_on_main_page_active(is_active)
  if is_active and self._controller then
    self._controller:sync_side_panel_state()
  end
end

function npc_hangout_game_module:_on_game_changed(hangout_id)
  local context = CsNpcHangoutGameManagerUtil.GetUIContext(hangout_id)
  if not_null(context) and is_side_panel_status(context.status) then
    self:_get_controller():refresh(hangout_id)
  elseif self._controller then
    self._controller:refresh(hangout_id)
  end
end

function npc_hangout_game_module:_on_game_removed(hangout_id)
  if self._controller then
    self._controller:on_game_removed(hangout_id)
  end
end

function npc_hangout_game_module:_on_show_start_tip(hangout_id)
  self:_show_tip(hangout_id, true)
end

function npc_hangout_game_module:_on_show_complete_tip(hangout_id)
  self:_show_tip(hangout_id, false)
end

function npc_hangout_game_module:_show_tip(hangout_id, is_start)
  local cfg = LocalDataUtil.get_value(typeof(NpcHangoutGameUICfg), hangout_id)
  local context = CsNpcHangoutGameManagerUtil.GetUIContext(hangout_id)
  if is_null(cfg) or is_null(context) then
    Logger.LogError("[NpcHangoutGame] missing tip data, hangout_id=" .. tostring(hangout_id))
    return
  end
  local title_cfg = is_start and cfg.startTipTitleText or cfg.completeTipTitleText
  local detail = ""
  if is_start and not_null(cfg.startTipDetailText) then
    local npc_name = npc_module:get_npc_name_by_id(context.npcId) or ""
    detail = cfg.startTipDetailText:ToStringExplicitWithParams(npc_name)
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.npc_hangout_game_tip, {
    title = not_null(title_cfg) and title_cfg:ToStringExplicit() or "",
    detail = detail,
    state = is_start and 1 or 0,
    icon = cfg.featureIcon
  })
end

function npc_hangout_game_module:get_render_data()
  return self._controller and self._controller:get_render_data() or nil
end

function npc_hangout_game_module:request_abandon()
  if self._controller then
    self._controller:request_abandon()
  end
end

function npc_hangout_game_module:show_unstarted_leave_confirm(yes_callback)
  return self:_get_controller():show_unstarted_leave_confirm(yes_callback)
end

return npc_hangout_game_module
