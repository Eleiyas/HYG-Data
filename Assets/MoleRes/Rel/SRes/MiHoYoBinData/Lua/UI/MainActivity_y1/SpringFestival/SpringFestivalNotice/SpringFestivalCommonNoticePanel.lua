local M = G.Class("SpringFestivalCommonNoticePanel", G.UIPanel)
local base = G.UIPanel
local SPRING_NOTICE_DELAY_SECONDS = 1
local SPRING_NOTICE_AUTO_HIDE_SECONDS = 3

local function _get_main_page_scene_type()
  return spring_festival_notice_module and spring_festival_notice_module.scene_type and spring_festival_notice_module.scene_type.main_page or 0
end

local function _is_main_page_scene(scene_type)
  return scene_type ~= nil and scene_type == _get_main_page_scene_type()
end

local function _is_spring_module_ready()
  return CsSpringFestivalModuleUtil ~= nil and not CsSpringFestivalModuleUtil.IsNull()
end

local function _is_loading_page_visible()
  return UIManagerInstance:is_show("UI/Loading/LoadingPage")
end

local function _sync_animation_progress(anim, normalized_time)
  if is_null(anim) then
    return
  end
  local clip = anim.clip
  if is_null(clip) then
    return
  end
  local state
  if anim.get_Item ~= nil then
    state = anim:get_Item(clip.name)
  end
  if state == nil then
    state = anim[clip.name]
  end
  if state == nil then
    return
  end
  local progress = normalized_time
  if progress == nil then
    progress = 0
  end
  progress = progress - math.floor(progress)
  state.normalizedTime = progress
  anim:Play(clip.name)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_CommonNoticeDialog"
  self._scene_type = nil
  self._anchor_trans_getter = nil
  self._host_active = false
  self._wait_coroutine = nil
  self._hide_coroutine = nil
  self._timer_trigger_type = nil
  self._timer_owner_uid = 0
  self._resume_on_enable = false
  self._resume_trigger_type = nil
  self._resume_owner_uid = 0
  self._pending_daily_refresh = false
  self._pending_daily_refresh_need_delay = false
end

function M:on_create()
  base.on_create(self)
  self:hide_notice(true)
end

function M:register_events()
  base.register_events(self)
end

function M:setup_notice_host(scene_type, anchor_trans_getter)
  self._scene_type = scene_type
  self._anchor_trans_getter = anchor_trans_getter
end

function M:on_notice_host_enable()
  self._host_active = true
  self:_try_consume_pending_sync_data_notice()
  if self:_try_resume_pending_daily_refresh() then
    return
  end
  self:_start_on_enable_notice_timer()
end

function M:_try_consume_pending_sync_data_notice()
  if not _is_spring_module_ready() then
    return false
  end
  if CsSpringFestivalModuleUtil.HasPendingSyncDataNotice ~= true then
    return false
  end
  local current_owner_uid = 0
  if player_module ~= nil and player_module.get_scene_owner_uid ~= nil then
    current_owner_uid = player_module:get_scene_owner_uid() or 0
  end
  if current_owner_uid == 0 then
    Logger.Log("[SpringFestivalNotice] defer pending sync data notice, scene owner not ready")
    return false
  end
  local owner_uid = CsSpringFestivalModuleUtil.ConsumePendingSyncDataOwnerUid()
  if spring_festival_notice_module ~= nil and spring_festival_notice_module.mark_data_synced_for_current_scene ~= nil then
    spring_festival_notice_module:mark_data_synced_for_current_scene(owner_uid)
  end
  Logger.Log(string.format("[SpringFestivalNotice] consumed pending sync data notice, owner_uid=%s current_owner_uid=%s", tostring(owner_uid), tostring(current_owner_uid)))
  return true
end

function M:on_sync_data_notify()
  self:_try_consume_pending_sync_data_notice()
  if not self._host_active then
    return
  end
  if is_null(self.game_obj) then
    return
  end
  if _is_loading_page_visible() then
    return
  end
  if not is_null(self._wait_coroutine) or not is_null(self._hide_coroutine) then
    Logger.Log("[SpringFestivalNotice] on_sync_data_notify skip, notice in progress")
    return
  end
  local data_owner_uid = spring_festival_notice_module and spring_festival_notice_module._data_owner_uid or 0
  local local_uid = 0
  if player_module ~= nil and player_module.get_player_uid ~= nil then
    local_uid = player_module:get_player_uid() or 0
  end
  if data_owner_uid == 0 or local_uid == 0 then
    Logger.Log(string.format("[SpringFestivalNotice] on_sync_data_notify skip, uid invalid data_owner=%s local=%s", tostring(data_owner_uid), tostring(local_uid)))
    return
  end
  local trigger_type
  local owner_uid_for_mark = 0
  if data_owner_uid == local_uid then
    trigger_type = spring_festival_notice_module.trigger_type.daily_refresh
  else
    if not self:_is_today_first_visit_owner(data_owner_uid) then
      Logger.Log(string.format("[SpringFestivalNotice] on_sync_data_notify skip, owner=%s already visited today", tostring(data_owner_uid)))
      return
    end
    trigger_type = spring_festival_notice_module.trigger_type.enter_other_planet
    owner_uid_for_mark = data_owner_uid
  end
  Logger.Log(string.format("[SpringFestivalNotice] on_sync_data_notify show trigger=%s data_owner=%s local=%s", tostring(trigger_type), tostring(data_owner_uid), tostring(local_uid)))
  self._timer_trigger_type = trigger_type
  self._timer_owner_uid = owner_uid_for_mark
  local ok = self:_refresh_notice(trigger_type, SPRING_NOTICE_AUTO_HIDE_SECONDS)
  if ok and trigger_type == spring_festival_notice_module.trigger_type.enter_other_planet then
    self:_mark_today_visited_owner(owner_uid_for_mark)
  end
end

function M:on_notice_host_disable()
  self._host_active = false
  local is_main_page = _is_main_page_scene(self._scene_type)
  if is_main_page and (not is_null(self._wait_coroutine) or not is_null(self._hide_coroutine)) and self._timer_trigger_type ~= nil then
    self._resume_on_enable = true
    self._resume_trigger_type = self._timer_trigger_type
    self._resume_owner_uid = self._timer_owner_uid or 0
  end
  self:cancel_notice_display()
end

function M:on_daily_refresh_notify(logic_day, need_delay)
  if not _is_main_page_scene(self._scene_type) then
    return
  end
  if need_delay == nil and _is_spring_module_ready() then
    need_delay = CsSpringFestivalModuleUtil.IsTodayFirstLogin == true
  end
  Logger.Log(string.format("[SpringFestivalNotice] recv SpringFestivalDailyRefreshNotify logic_day=%s need_delay=%s", tostring(logic_day), tostring(need_delay)))
  self:_handle_daily_refresh_notify(need_delay == true)
end

function M:cancel_notice_display()
  self:_stop_notice_timers()
  self._timer_trigger_type = nil
  self._timer_owner_uid = 0
  self:hide_notice(false)
end

function M:show_notice_by_trigger(trigger_type, auto_hide_seconds)
  self._timer_trigger_type = trigger_type
  self._timer_owner_uid = 0
  return self:_refresh_notice(trigger_type, auto_hide_seconds)
end

function M:_is_today_first_visit_owner(owner_uid)
  if owner_uid == nil or owner_uid == 0 then
    Logger.Log("[SpringFestivalNotice] _is_today_first_visit_owner owner_uid invalid")
    return false
  end
  if not _is_spring_module_ready() then
    Logger.Log("[SpringFestivalNotice] _is_today_first_visit_owner skip, CsSpringFestivalModuleUtil is null")
    return false
  end
  local first_visit = CsSpringFestivalModuleUtil.IsTodayFirstVisitOwner(owner_uid)
  Logger.Log(string.format("[SpringFestivalNotice] _is_today_first_visit_owner owner_uid=%s first_visit=%s", tostring(owner_uid), tostring(first_visit)))
  return first_visit
end

function M:_mark_today_visited_owner(owner_uid)
  if owner_uid == nil or owner_uid == 0 then
    return
  end
  if not _is_spring_module_ready() then
    return
  end
  CsSpringFestivalModuleUtil.MarkTodayVisitedOwner(owner_uid)
end

function M:_resolve_on_enable_trigger()
  if not _is_main_page_scene(self._scene_type) then
    return nil, 0, "not_main_page"
  end
  if not _is_spring_module_ready() then
    return nil, 0, "module_null"
  end
  if self._resume_on_enable and self._resume_trigger_type ~= nil then
    local trigger_type = self._resume_trigger_type
    local owner_uid = self._resume_owner_uid or 0
    self._resume_on_enable = false
    self._resume_trigger_type = nil
    self._resume_owner_uid = 0
    if trigger_type == spring_festival_notice_module.trigger_type.enter_other_planet then
      local local_uid = player_module:get_player_uid() or 0
      if owner_uid ~= 0 and owner_uid ~= local_uid then
        return trigger_type, owner_uid, "resume_after_disable_visit_owner"
      end
    elseif trigger_type == spring_festival_notice_module.trigger_type.daily_refresh then
      return trigger_type, owner_uid, "resume_after_disable_daily_refresh"
    end
  end
  local local_uid = player_module:get_player_uid() or 0
  local owner_uid = player_module:get_scene_owner_uid() or 0
  Logger.Log(string.format("[SpringFestivalNotice] detect local_uid=%s owner_uid=%s", tostring(local_uid), tostring(owner_uid)))
  if owner_uid ~= 0 and owner_uid ~= local_uid and self:_is_today_first_visit_owner(owner_uid) then
    return spring_festival_notice_module.trigger_type.enter_other_planet, owner_uid, "first_visit_owner_today"
  end
  return nil, 0, "no_trigger"
end

function M:_consume_module_daily_refresh_pending()
  if not _is_spring_module_ready() then
    return false
  end
  CsSpringFestivalModuleUtil.ConsumePendingDailyRefreshNotice()
  return true
end

function M:_show_daily_refresh_notice_now(stop_all_timers)
  self._pending_daily_refresh = false
  self._pending_daily_refresh_need_delay = false
  self:_consume_module_daily_refresh_pending()
  if stop_all_timers then
    self:_stop_notice_timers()
  else
    self:_stop_notice_delay_timer()
  end
  self._timer_trigger_type = spring_festival_notice_module.trigger_type.daily_refresh
  self._timer_owner_uid = 0
  return self:_refresh_notice(self._timer_trigger_type, SPRING_NOTICE_AUTO_HIDE_SECONDS)
end

function M:_show_daily_refresh_notice_with_delay(stop_all_timers)
  self._pending_daily_refresh = false
  self._pending_daily_refresh_need_delay = false
  self:_consume_module_daily_refresh_pending()
  if stop_all_timers then
    self:_stop_notice_timers()
  else
    self:_stop_notice_delay_timer()
  end
  self._timer_trigger_type = spring_festival_notice_module.trigger_type.daily_refresh
  self._timer_owner_uid = 0
  self._wait_coroutine = CsCoroutineManagerUtil.Invoke(SPRING_NOTICE_DELAY_SECONDS, function()
    self._wait_coroutine = nil
    if not self._host_active then
      return
    end
    self:_refresh_notice(self._timer_trigger_type, SPRING_NOTICE_AUTO_HIDE_SECONDS)
  end)
  return true
end

function M:_handle_daily_refresh_notify(need_delay)
  if not _is_main_page_scene(self._scene_type) then
    return
  end
  if not self._host_active then
    self._pending_daily_refresh = true
    self._pending_daily_refresh_need_delay = need_delay == true
    Logger.Log("[SpringFestivalNotice] pending daily_refresh, host inactive")
    return
  end
  if _is_loading_page_visible() then
    self._pending_daily_refresh = true
    self._pending_daily_refresh_need_delay = need_delay == true
    Logger.Log("[SpringFestivalNotice] pending daily_refresh while LoadingPage")
    return
  end
  if need_delay == true then
    self:_show_daily_refresh_notice_with_delay(false)
    return
  end
  self:_show_daily_refresh_notice_now(false)
end

function M:_try_resume_pending_daily_refresh()
  if not _is_main_page_scene(self._scene_type) then
    return false
  end
  if is_null(self.game_obj) then
    return false
  end
  local pending_by_panel = self._pending_daily_refresh
  local pending_by_module = false
  if _is_spring_module_ready() then
    pending_by_module = CsSpringFestivalModuleUtil.HasPendingDailyRefreshNotice == true
  end
  if not pending_by_panel and not pending_by_module then
    return false
  end
  if not self._host_active then
    return false
  end
  if _is_loading_page_visible() then
    return false
  end
  local need_delay = self._pending_daily_refresh_need_delay == true
  if pending_by_module and _is_spring_module_ready() then
    need_delay = need_delay or false
  end
  Logger.Log(string.format("[SpringFestivalNotice] consume pending daily_refresh on host enable, need_delay=%s", tostring(need_delay)))
  if need_delay then
    return self:_show_daily_refresh_notice_with_delay(true)
  end
  return self:_show_daily_refresh_notice_now(true)
end

function M:_start_on_enable_notice_timer()
  self:_stop_notice_delay_timer()
  local trigger_type, owner_uid, reason = self:_resolve_on_enable_trigger()
  Logger.Log(string.format("[SpringFestivalNotice] host_enable resolve trigger=%s owner_uid=%s reason=%s", tostring(trigger_type), tostring(owner_uid), tostring(reason)))
  if trigger_type == nil then
    self._timer_trigger_type = nil
    self._timer_owner_uid = 0
    return
  end
  self._timer_trigger_type = trigger_type
  self._timer_owner_uid = owner_uid or 0
  self._wait_coroutine = CsCoroutineManagerUtil.Invoke(SPRING_NOTICE_DELAY_SECONDS, function()
    self._wait_coroutine = nil
    if not self._host_active then
      return
    end
    local show = self:_refresh_notice(self._timer_trigger_type, SPRING_NOTICE_AUTO_HIDE_SECONDS)
    if not show then
      return
    end
    if self._timer_trigger_type == spring_festival_notice_module.trigger_type.enter_other_planet then
      self:_mark_today_visited_owner(self._timer_owner_uid)
    end
  end)
end

function M:_refresh_notice(trigger_type, auto_hide_seconds)
  if is_null(self.game_obj) then
    return false
  end
  if spring_festival_notice_module == nil or spring_festival_notice_module.query_notice == nil then
    return false
  end
  local scene_type = self._scene_type or _get_main_page_scene_type()
  local show, data = spring_festival_notice_module:query_notice(trigger_type, scene_type)
  Logger.Log(string.format("[SpringFestivalNotice] query trigger=%s show=%s subtitle=%s", tostring(trigger_type), tostring(show), tostring(data and data.subtitle or "")))
  if not show then
    self:_stop_notice_auto_hide_timer()
    self:hide_notice(false)
    return false
  end
  self:refresh_view(data)
  self:show_notice(self:_resolve_anchor_trans())
  if auto_hide_seconds ~= nil and 0 < auto_hide_seconds then
    self:_stop_notice_auto_hide_timer()
    self._hide_coroutine = CsCoroutineManagerUtil.Invoke(auto_hide_seconds, function()
      self._hide_coroutine = nil
      self:hide_notice(false)
    end)
  end
  return true
end

function M:refresh_view(data)
  if data == nil then
    self:hide_notice(false)
    return
  end
  local icon_cmpt = self._icon
  if string.is_valid(data.icon_path) and not is_null(icon_cmpt) then
    UIUtil.set_image(icon_cmpt, data.icon_path, self:get_load_proxy())
  end
  if string.is_valid(data.title) and not is_null(self._text_title) then
    UIUtil.set_text(self._text_title, data.title)
  end
  if string.is_valid(data.subtitle_text_id) and not is_null(self._text_subtitle) then
    local args = data.subtitle_args
    if args ~= nil then
      UIUtil.set_text_by_id(self._text_subtitle, data.subtitle_text_id, table.unpack(args))
    else
      UIUtil.set_text_by_id(self._text_subtitle, data.subtitle_text_id)
    end
  end
  if not is_null(self._text_subtitleex) then
    UIUtil.set_active(self._text_subtitleex, data.show_subtitle_ex == true)
  end
end

function M:show_notice(anchor_trans)
  if is_null(self.game_obj) then
    return
  end
  if not is_null(anchor_trans) and not is_null(self.rect_trans) then
    local parent_rect = self.rect_trans.parent
    if not is_null(parent_rect) then
      local screen_point = RectTransformUtility.WorldToScreenPoint(UIManagerInstance.ui_camera, anchor_trans.position)
      local success, local_point = RectTransformUtility.ScreenPointToLocalPointInRectangle(parent_rect, screen_point, UIManagerInstance.ui_camera)
      if success then
        self.rect_trans.anchoredPosition = local_point
      else
        self.rect_trans.position = anchor_trans.position
      end
    else
      self.rect_trans.position = anchor_trans.position
    end
  end
  if self:get_cur_ui_state() ~= EUIState.Show then
    self:change_state(EUIState.Show)
  end
end

function M:sync_arrow_outline_progress(normalized_time)
  _sync_animation_progress(self._img_arrow_outline, normalized_time)
end

function M:hide_notice(ignore_anim)
  if is_null(self.game_obj) then
    return
  end
  local cur_state = self:get_cur_ui_state()
  if cur_state < EUIState.Open or cur_state > EUIState.Show then
    return
  end
  self:change_state(EUIState.Hide)
end

function M:_resolve_anchor_trans()
  if type(self._anchor_trans_getter) == "function" then
    return self._anchor_trans_getter()
  end
  return nil
end

function M:_stop_notice_delay_timer()
  if not is_null(self._wait_coroutine) then
    CsCoroutineManagerUtil.StopCoroutine(self._wait_coroutine)
    self._wait_coroutine = nil
  end
end

function M:_stop_notice_auto_hide_timer()
  if not is_null(self._hide_coroutine) then
    CsCoroutineManagerUtil.StopCoroutine(self._hide_coroutine)
    self._hide_coroutine = nil
  end
end

function M:_stop_notice_timers()
  self:_stop_notice_delay_timer()
  self:_stop_notice_auto_hide_timer()
end

return M
