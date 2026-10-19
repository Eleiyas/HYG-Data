local M = G.Class("AiStateTip", G.UIBase)
local base = G.UIBase
local AiQueueConfig = require("UI/MainPage/AiQueueConfig")
local AI_QUEUE_GAMEPLAY_NONE = 0
local AI_QUEUE_GAMEPLAY_COFFEE = AiQueueConfig.GAMEPLAY.COFFEE
local AI_QUEUE_GAMEPLAY_COFFEE_PRIVATE = AiQueueConfig.GAMEPLAY.COFFEE_PRIVATE
local AI_QUEUE_GAMEPLAY_APPRAISAL = AiQueueConfig.GAMEPLAY.APPRAISAL
local AI_QUEUE_APPRAISAL_ACTIVITY_ID = AiQueueConfig.APPRAISAL_ACTIVITY_ID
local AI_NPC_STATE_HEAVY = 2
local SCENE_ACTIVITY_STATUS_NONE = 0
local SCENE_ACTIVITY_STATUS_PREPARE = 3
local SCENE_ACTIVITY_STATUS_RUNNING = 4
local SCENE_ACTIVITY_STATUS_SETTLE = 5
local SCENE_ACTIVITY_STATUS_SHOWCASE = 6
local SCENE_ACTIVITY_AGREE_RUNNING = 1
local EVENT_RESULT_SUCCESS = 1
local APPRAISAL_OWNER = {
  NONE = "NONE",
  AI = "AI",
  LEGACY = "LEGACY"
}
local APPRAISAL_STATE = {
  NONE = "None",
  PLAYING = "Playing",
  MATCH_EXIT_PENDING = "MatchExitPending",
  QUEUE_WAITING = "QueueWaiting",
  CONFIRM_PENDING = "ConfirmPending",
  OPEN_SINGLE_WAITING = "OpenSingleWaiting",
  PREPARING = "Preparing",
  NEXT_ROUND_WAITING = "NextRoundWaiting",
  LEGACY_MATCH = "LegacyMatch"
}
local AI_QUEUE_GAMEPLAY_TYPES = (function()
  local t = {}
  for k in pairs(AiQueueConfig.config) do
    table.insert(t, k)
  end
  table.sort(t)
  return t
end)()
local AI_QUEUE_KICK_REASON_TEXT = {
  [1] = "AiQueue_Kicked_Timeout",
  [2] = "AiQueue_Kicked_Conflict",
  [3] = "AiQueue_Kicked_Offline",
  [4] = "AiQueue_Kicked_CircuitBreaker",
  [6] = "AiQueue_Kicked_Forbidden"
}
local ConfirmDialog = require("UI/ConfirmDialog")

local function is_supported_gameplay_type(gameplay_type)
  return AiQueueConfig.get(gameplay_type) ~= nil
end

function M:init()
  base.init(self)
  self._gameplay_type = 0
  self._pos = 0
  self._total = 0
  self._is_ready = false
  self._ready_popup_guid = nil
  self._ready_popup_token = 0
  self._pending_ready_popup = nil
  self._single_start_popup_guid = nil
  self._single_start_popup_token = 0
  self._single_start_prompted = false
  self._pending_single_start_popup = false
  self._appraisal_projection = nil
  self._match_exit_pending = false
  self._match_exit_succeeded = false
  self._agree_start_pending = false
  self._skip_check = false
  self._click_callback = nil
  self._visibility_callback = nil
  self._is_visible = false
  self._projection_changed_callback = nil
  self._dialog_projection_changed_callback = nil
  self._connection_epoch = 0
  self._connection_suspended = nil
  self._activity_state_trusted = false
  self._pending_fresh_progress = nil
  self._pending_fresh_ready = nil
  self._restored = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_destroy()
  self._click_callback = nil
  self._visibility_callback = nil
  self._projection_changed_callback = nil
  self._dialog_projection_changed_owner = nil
  self._dialog_projection_changed_callback = nil
  self:_close_ready_popup()
  self:_close_single_start_popup()
  base.on_destroy(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_on_host_enabled()
end

function M:on_host_enabled()
  self:_on_host_enabled()
end

function M:_on_host_enabled()
  if not self.is_active then
    self:set_active(true)
    return
  end
  if self._connection_suspended == nil or self._connection_suspended then
    self:_hide()
    return
  end
  if not self._restored then
    self._restored = true
    self:_restore_from_module()
  end
  if self._pending_ready_popup then
    local p = self._pending_ready_popup
    self._pending_ready_popup = nil
    local snapshot = not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.GetMyEntrySnapshot(p.gameplay_type) or nil
    local timeout = snapshot and snapshot.value5 or 0
    if snapshot and (snapshot.value4 or 0) == EVENT_RESULT_SUCCESS and 0 < timeout then
      Logger.Log("[AiQueue] _on_host_enabled: open deferred ready popup, timeout=" .. tostring(timeout))
      self:_show_ready_popup(p.gameplay_type, timeout)
    end
  end
  self:_refresh_appraisal_projection("host_enabled")
  if self._pending_single_start_popup then
    self:_show_single_start_popup()
  end
end

function M:set_connection_suspended(suspended)
  if self._connection_suspended == nil then
    if suspended then
      self:_on_socket_disconnected()
    else
      self._connection_suspended = false
      self._activity_state_trusted = true
    end
    return
  end
  if suspended then
    if not self._connection_suspended then
      self:_on_socket_disconnected()
    end
  elseif self._connection_suspended then
    self:_on_connection_resumed()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnAiQueueOverloadStateChanged, pack(self, M._on_ai_queue_overload_changed))
  self:add_evt_listener(EventID.OnAiQueueMyProgressChanged, pack(self, M._on_ai_queue_progress))
  self:add_evt_listener(EventID.OnAiQueueMyReady, pack(self, M._on_ai_queue_ready))
  self:add_evt_listener(EventID.OnAiQueueMyKicked, pack(self, M._on_ai_queue_kicked))
  self:add_evt_listener(EventID.OnAiQueueMyExited, pack(self, M._on_ai_queue_exited))
  self:add_evt_listener(EventID.OnAiQueueConfirmFailed, pack(self, M._on_ai_queue_confirm_failed))
  self:add_evt_listener(EventID.OnAiQueueConfirmSucceeded, pack(self, M._on_ai_queue_confirm_succeeded))
  self:add_evt_listener(EventID.SceneActivity.OnSceneActivityPlayerChanged, pack(self, M._on_activity_player_changed))
  self:add_evt_listener(EventID.SceneActivity.OnSceneActivityCancelJoinResult, pack(self, M._on_activity_cancel_join_result))
  self:add_evt_listener(EventID.SceneActivity.OnSceneActivityAgreeRunningResult, pack(self, M._on_activity_agree_running_result))
  self:add_evt_listener(EventID.OnSocketDisconnected, pack(self, M._on_socket_disconnected))
  self:add_evt_listener(EventID.luaCloseNetError, pack(self, M._on_connection_resumed))
end

function M:_on_socket_disconnected()
  if self._connection_suspended == true then
    return
  end
  self._connection_epoch = self._connection_epoch + 1
  self._connection_suspended = true
  self._activity_state_trusted = false
  self._match_exit_pending = false
  self._match_exit_succeeded = false
  self._agree_start_pending = false
  self._pending_ready_popup = nil
  self:_close_ready_popup()
  self:_close_single_start_popup()
  self:_hide()
  self:_notify_appraisal_projection_changed({
    ai_owned = false,
    should_close_dialog = true,
    defer_legacy_restore = true
  })
end

function M:_on_connection_resumed()
  if self._connection_suspended ~= true then
    return
  end
  self._connection_suspended = false
  self._restored = true
  local pending_ready_gameplay_type = self._pending_fresh_ready and self._pending_fresh_ready.value1 or nil
  if self._pending_fresh_progress then
    local data = self._pending_fresh_progress
    self._pending_fresh_progress = nil
    self:_on_ai_queue_progress(data)
  end
  if self._pending_fresh_ready then
    self._pending_fresh_ready = nil
    local snapshot = not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.GetMyEntrySnapshot(pending_ready_gameplay_type) or nil
    if snapshot and (snapshot.value4 or 0) == EVENT_RESULT_SUCCESS and 0 < (snapshot.value5 or 0) then
      self:_on_ai_queue_ready({
        value1 = pending_ready_gameplay_type,
        value2 = snapshot.value5
      })
    end
  end
  self:_restore_from_module()
  self:_refresh_appraisal_projection("connection_resumed")
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_ai_state_tip, pack(self, M._on_click))
end

function M:_on_ai_queue_overload_changed(data)
  if data == nil then
    return
  end
  local gameplay_type = data.value1
  if not is_supported_gameplay_type(gameplay_type) then
    return
  end
  local state = data.value2
  local npc_id = data.value3
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self:is_in_appraisal_match_pool() then
    if state >= AI_NPC_STATE_HEAVY then
      self:_close_single_start_popup()
      return
    end
    self:_refresh_appraisal_projection("overload_changed")
  end
end

function M:_on_ai_queue_progress(data)
  if data == nil then
    return
  end
  local gameplay_type = data.value1
  local pos = data.value2
  local total = data.value3
  if not is_supported_gameplay_type(gameplay_type) then
    Logger.LogWarning("[AiQueue] ignore unsupported AiStateTip gameplay type=" .. tostring(gameplay_type))
    return
  end
  if self._connection_suspended then
    self._pending_fresh_progress = data
    return
  end
  if pos == nil or pos <= 0 then
    if gameplay_type == self._gameplay_type then
      self._is_ready = false
      self:_close_ready_popup()
      self:_hide()
    end
    if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
      self:_refresh_appraisal_projection("queue_tombstone")
    end
    return
  end
  local snapshot = not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.GetMyEntrySnapshot(gameplay_type) or nil
  local snapshot_is_ready = snapshot ~= nil and (snapshot.value4 or 0) == EVENT_RESULT_SUCCESS
  if gameplay_type == self._gameplay_type and self._is_ready and snapshot_is_ready then
    self._pos = pos
    self._total = total
    if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
      self:_refresh_appraisal_projection("late_queue_progress")
    end
    return
  end
  self._gameplay_type = gameplay_type
  self._is_ready = snapshot_is_ready
  if not snapshot_is_ready then
    self:_close_ready_popup()
  end
  self._pos = pos
  self._total = total
  self:_show()
  self:set_data(gameplay_type)
  if snapshot_is_ready then
    self:set_ready()
  else
    self:set_progress(pos, total)
  end
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    EventCenter.Broadcast(EventID.SceneActivity.LuaCloseGalacticBazaarMatchingDialog, nil)
    self:_refresh_appraisal_projection("queue_progress")
  end
end

function M:_on_ai_queue_ready(data)
  if data == nil then
    return
  end
  local gameplay_type = data.value1
  local timeout_sec = data.value2
  if not is_supported_gameplay_type(gameplay_type) then
    Logger.LogWarning("[AiQueue] ignore unsupported AiStateTip Ready type=" .. tostring(gameplay_type))
    return
  end
  if timeout_sec == nil or timeout_sec <= 0 then
    Logger.Log("[AiQueue] AiStateTip _on_ai_queue_ready: ignore expired ready type=" .. tostring(gameplay_type))
    return
  end
  if self._connection_suspended then
    self._pending_fresh_ready = data
    return
  end
  Logger.Log("[AiQueue] AiStateTip _on_ai_queue_ready: type=" .. tostring(gameplay_type) .. " timeout=" .. tostring(timeout_sec))
  self._gameplay_type = gameplay_type
  self._is_ready = true
  self:_show()
  self:set_data(gameplay_type)
  self:set_ready()
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    EventCenter.Broadcast(EventID.SceneActivity.LuaCloseGalacticBazaarMatchingDialog, nil)
  end
  if AiQueueConfig.is_auto_confirm(gameplay_type) then
    Logger.Log("[AiQueue] _on_ai_queue_ready: auto-confirm type=" .. tostring(gameplay_type))
    if not CsAiQueueModuleUtil.IsNull() then
      CsAiQueueModuleUtil.RequestConfirm(gameplay_type)
    end
    self:_refresh_appraisal_projection("queue_ready")
  else
    self:_show_ready_popup(gameplay_type, timeout_sec)
  end
end

function M:_on_ai_queue_kicked(data)
  if data == nil then
    return
  end
  local gameplay_type = data.value1
  if not is_supported_gameplay_type(gameplay_type) then
    return
  end
  local reason = data.value2
  if self._pending_fresh_progress and self._pending_fresh_progress.value1 == gameplay_type then
    self._pending_fresh_progress = nil
  end
  if self._pending_fresh_ready and self._pending_fresh_ready.value1 == gameplay_type then
    self._pending_fresh_ready = nil
  end
  Logger.Log("[AiQueue] AiStateTip _on_ai_queue_kicked: type=" .. tostring(gameplay_type) .. " reason=" .. tostring(reason))
  if gameplay_type ~= self._gameplay_type then
    local tip_id = AI_QUEUE_KICK_REASON_TEXT[reason]
    if tip_id then
      UIUtil.show_tips(UIUtil.get_text_by_id(tip_id))
    end
    return
  end
  self._is_ready = false
  self:_close_ready_popup()
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    self:_reset_appraisal_prompt()
  end
  self:_hide()
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    self:_notify_appraisal_projection_changed({
      ai_owned = false,
      should_close_dialog = true,
      defer_legacy_restore = true
    })
  end
  local tip_id = AI_QUEUE_KICK_REASON_TEXT[reason]
  if tip_id then
    UIUtil.show_tips(UIUtil.get_text_by_id(tip_id))
  end
end

function M:_on_ai_queue_exited(gameplay_type)
  if not is_supported_gameplay_type(gameplay_type) then
    return
  end
  if self._pending_fresh_progress and self._pending_fresh_progress.value1 == gameplay_type then
    self._pending_fresh_progress = nil
  end
  if self._pending_fresh_ready and self._pending_fresh_ready.value1 == gameplay_type then
    self._pending_fresh_ready = nil
  end
  Logger.Log("[AiQueue] AiStateTip _on_ai_queue_exited: type=" .. tostring(gameplay_type))
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    self:_refresh_appraisal_projection("queue_exited")
    return
  end
  if gameplay_type ~= self._gameplay_type then
    return
  end
  self._is_ready = false
  self:_close_ready_popup()
  self:_hide()
end

function M:_on_ai_queue_confirm_failed(gameplay_type)
  if not is_supported_gameplay_type(gameplay_type) then
    return
  end
  if self._pending_fresh_progress and self._pending_fresh_progress.value1 == gameplay_type then
    self._pending_fresh_progress = nil
  end
  if self._pending_fresh_ready and self._pending_fresh_ready.value1 == gameplay_type then
    self._pending_fresh_ready = nil
  end
  Logger.Log("[AiQueue] AiStateTip _on_ai_queue_confirm_failed: type=" .. tostring(gameplay_type))
  if gameplay_type ~= self._gameplay_type then
    return
  end
  self._is_ready = false
  self:_refresh_appraisal_projection("confirm_failed")
  if not is_null(self.game_obj) and self.game_obj.activeInHierarchy then
    self:set_progress(self._pos, self._total)
  end
  UIUtil.show_tips(UIUtil.get_text_by_id("AiQueue_ConfirmFailed_Tip"))
end

function M:_on_ai_queue_confirm_succeeded(gameplay_type)
  if not is_supported_gameplay_type(gameplay_type) then
    return
  end
  if self._pending_fresh_progress and self._pending_fresh_progress.value1 == gameplay_type then
    self._pending_fresh_progress = nil
  end
  if self._pending_fresh_ready and self._pending_fresh_ready.value1 == gameplay_type then
    self._pending_fresh_ready = nil
  end
  if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    self:_refresh_appraisal_projection("confirm_succeeded")
    return
  end
  if gameplay_type ~= AI_QUEUE_GAMEPLAY_COFFEE and gameplay_type ~= AI_QUEUE_GAMEPLAY_COFFEE_PRIVATE then
    return
  end
  if gameplay_type ~= self._gameplay_type then
    return
  end
  self._is_ready = false
  self._pos = 0
  self._total = 0
  self._gameplay_type = AI_QUEUE_GAMEPLAY_NONE
  self:_close_ready_popup()
  self:_hide()
end

function M:_on_activity_player_changed(activity_id)
  if activity_id ~= AI_QUEUE_APPRAISAL_ACTIVITY_ID then
    return
  end
  if self._connection_suspended then
    return
  end
  self._activity_state_trusted = true
  self:_refresh_appraisal_projection("activity_player_changed")
end

function M:_on_activity_cancel_join_result(data)
  if data.value1 ~= AI_QUEUE_APPRAISAL_ACTIVITY_ID then
    return
  end
  if not self._match_exit_pending then
    return
  end
  if data.value2 ~= EVENT_RESULT_SUCCESS then
    Logger.LogWarning("[AiQueue] appraisal cancel join failed")
    self._match_exit_pending = false
    self._match_exit_succeeded = false
  else
    self._match_exit_succeeded = true
  end
  self:_refresh_appraisal_projection("cancel_join_result")
end

function M:_on_activity_agree_running_result(data)
  if data.value1 ~= AI_QUEUE_APPRAISAL_ACTIVITY_ID or not self._agree_start_pending then
    return
  end
  if data.value2 ~= EVENT_RESULT_SUCCESS then
    Logger.LogWarning("[AiQueue] appraisal agree running failed")
  end
  self._agree_start_pending = false
  self:_refresh_appraisal_projection("agree_running_result")
end

function M:_show()
  self._is_visible = true
  if self._visibility_callback then
    self._visibility_callback(true)
  end
end

function M:_hide()
  self._is_visible = false
  if self._visibility_callback then
    self._visibility_callback(false)
  end
end

function M:set_visibility_callback(callback)
  self._visibility_callback = callback
  if self._visibility_callback then
    self._visibility_callback(self._is_visible)
  end
end

function M:set_data(gameplay_type)
  self._gameplay_type = gameplay_type
  if not is_null(self._state_group_icon) then
    if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
      self._state_group_icon:SetState(1)
    else
      self._state_group_icon:SetState(0)
    end
  end
  if not is_null(self._state_group_txt) then
    self._state_group_txt:SetState(0)
  end
end

function M:set_progress(pos, total)
  if not is_null(self._state_group_txt) then
    self._state_group_txt:SetState(0)
  end
  if not is_null(self._btn_ai_state_tip) then
    self._btn_ai_state_tip:SetSelect(false)
  end
end

function M:set_ready()
  if not is_null(self._state_group_txt) then
    self._state_group_txt:SetState(1)
  end
  if not is_null(self._btn_ai_state_tip) then
    self._btn_ai_state_tip:SetSelect(true)
  end
end

function M:set_click_callback(cb)
  self._click_callback = cb
end

function M:set_projection_changed_callback(cb)
  self._projection_changed_callback = cb
end

function M:set_dialog_projection_changed_callback(owner, cb)
  self._dialog_projection_changed_owner = owner
  self._dialog_projection_changed_callback = cb
end

function M:clear_dialog_projection_changed_callback(owner)
  if self._dialog_projection_changed_owner ~= owner then
    return
  end
  self._dialog_projection_changed_owner = nil
  self._dialog_projection_changed_callback = nil
end

function M:get_connection_epoch()
  return self._connection_epoch
end

function M:is_connection_suspended()
  return self._connection_suspended
end

function M:_notify_appraisal_projection_changed(projection)
  if self._projection_changed_callback then
    self._projection_changed_callback(projection)
  end
  if self._dialog_projection_changed_callback then
    self._dialog_projection_changed_callback(projection)
  end
end

function M:_on_click()
  if not self._connection_suspended and self._click_callback then
    self._click_callback(self._gameplay_type)
  end
end

function M:_show_ready_popup(gameplay_type, timeout_sec)
  if self._connection_suspended then
    return
  end
  if self._ready_popup_guid then
    return
  end
  self._ready_popup_token = self._ready_popup_token + 1
  local popup_token = self._ready_popup_token
  self:_close_single_start_popup()
  local dismissed_foreign = ConfirmDialog.dismiss_all_ordinary() > 0
  if popup_token ~= self._ready_popup_token or self._ready_popup_guid then
    return
  end
  if not dismissed_foreign and not is_null(self.game_obj) and not self.game_obj.activeInHierarchy then
    self._pending_ready_popup = {gameplay_type = gameplay_type, timeout_sec = timeout_sec}
    Logger.Log("[AiQueue] _show_ready_popup: host inactive, defer popup")
    return
  end
  self._pending_ready_popup = nil
  local title_txt = UIUtil.get_text_by_id(AiQueueConfig.get_name_text_id(gameplay_type))
  local popup = UIUtil.get_confirm_popup()
  popup:set_priority_confirm(true)
  local connection_epoch = self._connection_epoch
  popup:set_texts(nil, UIUtil.get_text_by_id("Common_EnterNow"), UIUtil.get_text_by_id("Common_ComeBackLater"), title_txt)
  popup:set_countdown(timeout_sec or 0)
  popup:set_force_confirm(true)
  popup:set_countdown_text(function(sec)
    return UIUtil.get_text_by_id("CoffeeRp_Queue_Ready_ConfirmEnter") .. "\n" .. UIUtil.get_text_by_id("CoffeeRp_Countdown_Seconds", sec)
  end)
  
  local function _on_close()
    if popup_token ~= self._ready_popup_token then
      return false
    end
    self._ready_popup_token = self._ready_popup_token + 1
    self._ready_popup_guid = nil
    return true
  end
  
  local function _on_cancel()
    if not _on_close() then
      return
    end
    if connection_epoch ~= self._connection_epoch or self._connection_suspended then
      return
    end
    if not CsAiQueueModuleUtil.IsNull() then
      CsAiQueueModuleUtil.RequestCancel(gameplay_type)
    end
  end
  
  popup:set_callbacks(function()
    if not _on_close() then
      return
    end
    if connection_epoch ~= self._connection_epoch or self._connection_suspended then
      return
    end
    if not CsAiQueueModuleUtil.IsNull() then
      CsAiQueueModuleUtil.RequestConfirm(gameplay_type)
    end
  end, _on_cancel, _on_cancel, _on_close)
  local popup_guid = popup:show()
  if popup_token == self._ready_popup_token then
    self._ready_popup_guid = popup_guid
  elseif popup_guid then
    UIManagerInstance:close(popup_guid)
  end
end

function M:_close_ready_popup()
  self._ready_popup_token = self._ready_popup_token + 1
  if self._ready_popup_guid then
    UIManagerInstance:close(self._ready_popup_guid)
    self._ready_popup_guid = nil
  end
  self._pending_ready_popup = nil
end

function M:_restore_ready_popup_from_snapshot()
  if self._connection_suspended then
    return
  end
  if self._ready_popup_guid then
    return
  end
  self._pending_ready_popup = nil
  if CsAiQueueModuleUtil.IsNull() then
    return
  end
  local gameplay_type = self._gameplay_type
  if AiQueueConfig.is_auto_confirm(gameplay_type) then
    return
  end
  local snapshot = CsAiQueueModuleUtil.GetMyEntrySnapshot(gameplay_type)
  if snapshot == nil or (snapshot.value4 or 0) ~= EVENT_RESULT_SUCCESS then
    return
  end
  local remaining = snapshot.value5 or 0
  if remaining <= 0 then
    return
  end
  self:_show_ready_popup(gameplay_type, remaining)
end

local function count_match_players(raw)
  local count = 0
  if raw then
    for i = 0, raw.Count - 1 do
      if raw[i] and (raw[i].PlayerUid or 0) ~= 0 then
        count = count + 1
      end
    end
  end
  return count
end

function M:_build_appraisal_projection()
  local entry
  local in_match_pool = false
  if not CsAiQueueModuleUtil.IsNull() then
    entry = CsAiQueueModuleUtil.GetMyEntrySnapshot(AI_QUEUE_GAMEPLAY_APPRAISAL)
    in_match_pool = CsAiQueueModuleUtil.IsInAppraisalMatchPool()
  end
  local status = CsSceneActivityModuleUtil.GetActivityScheduleStatus(AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  local in_match_list = CsSceneActivityModuleUtil.IsLocalPlayerInActivityMatchPlayerList(AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  local in_player_list = CsSceneActivityModuleUtil.IsInActivityPlayerList(AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  local match_list = CsSceneActivityModuleUtil.GetActivityMatchPlayerInfoList(AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  local match_count = count_match_players(match_list)
  if not self._activity_state_trusted then
    status = SCENE_ACTIVITY_STATUS_NONE
    in_match_list = false
    in_player_list = false
    match_list = nil
    match_count = 0
  end
  local match_capacity = AiQueueConfig.get_match_player_capacity(AI_QUEUE_GAMEPLAY_APPRAISAL) or 2
  local state = APPRAISAL_STATE.NONE
  local owner = (entry ~= nil or in_match_pool) and APPRAISAL_OWNER.AI or in_match_list and APPRAISAL_OWNER.LEGACY or APPRAISAL_OWNER.NONE
  if in_player_list then
    state = APPRAISAL_STATE.PLAYING
  elseif self._match_exit_pending then
    state = APPRAISAL_STATE.MATCH_EXIT_PENDING
  elseif owner == APPRAISAL_OWNER.AI and entry ~= nil and not in_match_list and match_count >= match_capacity then
    state = APPRAISAL_STATE.QUEUE_WAITING
  elseif owner == APPRAISAL_OWNER.AI and in_match_pool and in_match_list then
    if status == SCENE_ACTIVITY_STATUS_RUNNING or status == SCENE_ACTIVITY_STATUS_SETTLE or status == SCENE_ACTIVITY_STATUS_SHOWCASE then
      state = APPRAISAL_STATE.NEXT_ROUND_WAITING
    elseif status == SCENE_ACTIVITY_STATUS_PREPARE then
      state = APPRAISAL_STATE.PREPARING
    elseif match_count >= match_capacity then
      state = APPRAISAL_STATE.PREPARING
    else
      state = APPRAISAL_STATE.OPEN_SINGLE_WAITING
    end
  elseif owner == APPRAISAL_OWNER.AI and entry ~= nil and (entry.value4 or 0) == EVENT_RESULT_SUCCESS then
    state = APPRAISAL_STATE.CONFIRM_PENDING
  elseif owner == APPRAISAL_OWNER.AI then
    state = APPRAISAL_STATE.QUEUE_WAITING
  elseif owner == APPRAISAL_OWNER.LEGACY then
    state = APPRAISAL_STATE.LEGACY_MATCH
  end
  return {
    owner = owner,
    state = state,
    position = entry and (entry.value2 or 0) or 0,
    total = entry and (entry.value3 or 0) or 0,
    match_count = match_count,
    in_match_list = in_match_list,
    in_player_list = in_player_list,
    in_match_pool = in_match_pool,
    status = status,
    show_match_layout = state == APPRAISAL_STATE.OPEN_SINGLE_WAITING or state == APPRAISAL_STATE.PREPARING or state == APPRAISAL_STATE.NEXT_ROUND_WAITING or state == APPRAISAL_STATE.MATCH_EXIT_PENDING,
    should_close_dialog = state == APPRAISAL_STATE.PLAYING or state == APPRAISAL_STATE.NONE or state == APPRAISAL_STATE.LEGACY_MATCH,
    ai_owned = owner == APPRAISAL_OWNER.AI,
    can_start = state == APPRAISAL_STATE.OPEN_SINGLE_WAITING and not self._agree_start_pending,
    can_exit_queue = not in_match_pool and (state == APPRAISAL_STATE.QUEUE_WAITING or state == APPRAISAL_STATE.CONFIRM_PENDING),
    can_exit_match = state == APPRAISAL_STATE.OPEN_SINGLE_WAITING or state == APPRAISAL_STATE.NEXT_ROUND_WAITING or state == APPRAISAL_STATE.PREPARING
  }
end

function M:_refresh_appraisal_projection(reason)
  if self._connection_suspended then
    self:_close_ready_popup()
    self:_close_single_start_popup()
    self:_hide()
    self:_notify_appraisal_projection_changed({
      ai_owned = false,
      should_close_dialog = true,
      defer_legacy_restore = true
    })
    return
  end
  local old = self._appraisal_projection
  local projection = self:_build_appraisal_projection()
  if self._match_exit_pending and self._match_exit_succeeded and not projection.in_match_list then
    self._match_exit_pending = false
    self._match_exit_succeeded = false
    projection = self:_build_appraisal_projection()
  end
  self._appraisal_projection = projection
  self:_notify_appraisal_projection_changed(projection)
  local showing_appraisal = self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL
  if projection.state == APPRAISAL_STATE.PLAYING then
    self:_close_single_start_popup()
    if showing_appraisal then
      self._is_ready = false
      self:_close_ready_popup()
      self:_hide()
    end
  elseif projection.owner == APPRAISAL_OWNER.AI then
    EventCenter.Broadcast(EventID.SceneActivity.LuaCloseGalacticBazaarMatchingDialog, nil)
    self._gameplay_type = AI_QUEUE_GAMEPLAY_APPRAISAL
    self._pos = projection.position
    self._total = projection.total
    self:_show()
    self:set_data(AI_QUEUE_GAMEPLAY_APPRAISAL)
    if projection.state == APPRAISAL_STATE.QUEUE_WAITING then
      self._is_ready = false
      self:set_progress(self._pos, self._total)
    else
      self._is_ready = true
      self:set_ready()
    end
  elseif showing_appraisal then
    self._is_ready = false
    self:_close_ready_popup()
    self:_close_single_start_popup()
    self:_hide()
  end
  if projection.state == APPRAISAL_STATE.OPEN_SINGLE_WAITING then
    if not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.IsAppraisalSingleStartPrompted and CsAiQueueModuleUtil.IsAppraisalSingleStartPrompted() then
      self._single_start_prompted = true
    end
    if not self._single_start_prompted and not self._single_start_popup_guid then
      self:_show_single_start_popup()
    end
  else
    self:_close_single_start_popup()
    if not projection.in_match_list then
      self._single_start_prompted = false
    end
  end
  if old == nil or old.owner ~= projection.owner or old.state ~= projection.state then
    EventCenter.Broadcast(EventID.SceneActivity.LuaOpenMatchPanel, AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  end
end

function M:_show_single_start_popup()
  if self._connection_suspended then
    return
  end
  if self._single_start_popup_guid then
    return
  end
  self._single_start_popup_token = self._single_start_popup_token + 1
  local popup_token = self._single_start_popup_token
  self:_close_ready_popup()
  local dismissed_foreign = ConfirmDialog.dismiss_all_ordinary() > 0
  if popup_token ~= self._single_start_popup_token or self._single_start_popup_guid then
    return
  end
  if not dismissed_foreign and not is_null(self.game_obj) and not self.game_obj.activeInHierarchy then
    self._pending_single_start_popup = true
    return
  end
  self._pending_single_start_popup = false
  local popup = UIUtil.get_confirm_popup()
  popup:set_priority_confirm(true)
  local connection_epoch = self._connection_epoch
  popup:set_texts(nil, UIUtil.get_text_by_id("Common_JoinNow"), UIUtil.get_text_by_id("Common_ComeBackLater"), UIUtil.get_text_by_id("AiQueue_Name_Appraisal"))
  local timeout = AiQueueConfig.get_single_start_confirm_timeout(AI_QUEUE_GAMEPLAY_APPRAISAL) or 20
  popup:set_countdown(timeout)
  popup:set_countdown_text(function(sec)
    return UIUtil.get_text_by_id("Appraisal_Match_Ready_Confirm") .. "\n" .. UIUtil.get_text_by_id("Appraisal_Countdown_Seconds", sec)
  end)
  
  local function on_close()
    if popup_token ~= self._single_start_popup_token then
      return false
    end
    self._single_start_popup_token = self._single_start_popup_token + 1
    self._single_start_popup_guid = nil
    return true
  end
  
  local function start_now()
    if not on_close() then
      return
    end
    if connection_epoch ~= self._connection_epoch or self._connection_suspended then
      return
    end
    self:request_appraisal_start()
  end
  
  popup:set_callbacks(start_now, on_close, on_close, start_now)
  local popup_guid = popup:show()
  if popup_token == self._single_start_popup_token then
    self._single_start_popup_guid = popup_guid
  elseif popup_guid then
    UIManagerInstance:close(popup_guid)
  end
  if popup_token == self._single_start_popup_token and self._single_start_popup_guid then
    self._single_start_prompted = true
    if not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.MarkAppraisalSingleStartPrompted then
      CsAiQueueModuleUtil.MarkAppraisalSingleStartPrompted()
    end
  end
end

function M:_close_single_start_popup()
  self._single_start_popup_token = self._single_start_popup_token + 1
  if self._single_start_popup_guid then
    UIManagerInstance:close(self._single_start_popup_guid)
    self._single_start_popup_guid = nil
  end
  self._pending_single_start_popup = false
end

function M:_reset_appraisal_prompt()
  self:_close_single_start_popup()
  self._single_start_prompted = false
  self._appraisal_projection = nil
  self._match_exit_pending = false
  self._match_exit_succeeded = false
  self._agree_start_pending = false
end

function M:_restore_from_module()
  if CsAiQueueModuleUtil.IsNull() then
    return
  end
  local found = false
  for _, gameplay_type in ipairs(AI_QUEUE_GAMEPLAY_TYPES) do
    local snapshot = CsAiQueueModuleUtil.GetMyEntrySnapshot(gameplay_type)
    if snapshot then
      found = true
      local pos = snapshot.value2 or 0
      local total = snapshot.value3 or 0
      local is_ready = (snapshot.value4 or 0) == EVENT_RESULT_SUCCESS
      local timeout = snapshot.value5 or 0
      Logger.Log("[AiQueue] _restore_from_module: type=" .. tostring(gameplay_type) .. " pos=" .. tostring(pos) .. " total=" .. tostring(total) .. " isReady=" .. tostring(is_ready))
      self._gameplay_type = gameplay_type
      self._pos = pos
      self._total = total
      self:_show()
      self:set_data(gameplay_type)
      if gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
        EventCenter.Broadcast(EventID.SceneActivity.LuaCloseGalacticBazaarMatchingDialog, nil)
      end
      if 0 < pos then
        self:set_progress(pos, total)
      end
      if is_ready and 0 < timeout then
        self._is_ready = true
        self:set_ready()
        if not self._ready_popup_guid then
          if AiQueueConfig.is_auto_confirm(gameplay_type) and not self._connection_suspended then
            if not self:is_in_appraisal_match_pool() and not CsAiQueueModuleUtil.IsNull() then
              CsAiQueueModuleUtil.RequestConfirm(gameplay_type)
              break
            end
            self:_refresh_appraisal_projection("restore_ready")
            break
          end
          self:_show_ready_popup(gameplay_type, timeout)
        end
        break
      end
      if is_ready then
        self._is_ready = false
      end
      break
    end
  end
  if not found then
    self:_hide()
  end
end

function M:check_before_leave_street(on_confirm)
  if self._connection_suspended then
    return true
  end
  if self._skip_check then
    self._skip_check = false
    return false
  end
  if CsAiQueueModuleUtil.IsNull() then
    return false
  end
  local connection_epoch = self._connection_epoch
  self:_close_ready_popup()
  self:_close_single_start_popup()
  CsAiQueueModuleUtil.ResolveMatchConflictsBeforeLeave(function(success)
    if connection_epoch ~= self._connection_epoch or self._connection_suspended then
      return
    end
    if not success then
      self:_restore_ready_popup_from_snapshot()
      return
    end
    self._skip_check = true
    if on_confirm then
      on_confirm()
    end
  end)
  return true
end

function M:is_in_appraisal_match_pool()
  if CsAiQueueModuleUtil.IsNull() then
    return false
  end
  return CsAiQueueModuleUtil.IsInAppraisalMatchPool ~= nil and CsAiQueueModuleUtil.IsInAppraisalMatchPool()
end

function M:get_appraisal_projection()
  if self._appraisal_projection == nil then
    self._appraisal_projection = self:_build_appraisal_projection()
  end
  return self._appraisal_projection
end

function M:refresh_appraisal_projection(reason)
  self:_refresh_appraisal_projection(reason)
end

function M:request_appraisal_start()
  if self._connection_suspended then
    return false
  end
  self:_refresh_appraisal_projection("request_start")
  local projection = self._appraisal_projection
  if projection == nil or not projection.can_start then
    return false
  end
  self._agree_start_pending = true
  CsSceneActivityModuleUtil.SceneActivityAgreeRunningReq(SCENE_ACTIVITY_AGREE_RUNNING)
  self:_close_single_start_popup()
  self:_refresh_appraisal_projection("start_requested")
  return true
end

function M:request_appraisal_match_exit()
  if self._connection_suspended then
    return false
  end
  self:_refresh_appraisal_projection("request_match_exit")
  local projection = self._appraisal_projection
  if projection == nil or not projection.can_exit_match then
    return false
  end
  self._match_exit_pending = true
  self._match_exit_succeeded = false
  CsSceneActivityModuleUtil.SceneActivityPlayerCancelJoinReq(AI_QUEUE_APPRAISAL_ACTIVITY_ID)
  self:_refresh_appraisal_projection("match_exit_requested")
  return true
end

function M:get_queue_info()
  return self._gameplay_type, self._pos, self._total, self._is_ready
end

return M
