local M = G.Class("AiMatchDialog", G.UIWindow)
local base = G.UIWindow
local AiQueueConfig = require("UI/MainPage/AiQueueConfig")
local AI_MATCH_PLAYER_ITEM_CLS = "UI/MainPage/AiMatchPlayerItem"
local AI_QUEUE_GAMEPLAY_COFFEE = AiQueueConfig.GAMEPLAY.COFFEE
local AI_QUEUE_GAMEPLAY_COFFEE_PRIVATE = AiQueueConfig.GAMEPLAY.COFFEE_PRIVATE
local AI_QUEUE_GAMEPLAY_APPRAISAL = AiQueueConfig.GAMEPLAY.APPRAISAL
local DIALOG_TYPE_STATE = {
  APPRAISAL = 0,
  COFFEE = 1,
  COFFEE_PRIVATE = 2
}
local DIALOG_BUTTON_STATE = {
  COFFEE = 0,
  APPRAISAL_QUEUE = 1,
  APPRAISAL_MATCH = 2
}
local PANEL_ANCHOR_OFFSET = Vector3(-64, -80, 0)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/AiMatchDialog"
  self.config.type = EUIType.Dialog
  self._gameplay_type = 0
  self._pos = 0
  self._total = 0
  self._is_ready = false
  self._coordinator = nil
  self._exit_queue_popup_guid = nil
  self._exit_popup_token = 0
  self._connection_epoch = 0
  self._connection_suspended = false
  self._item_pool = {
    pool = {},
    active = {}
  }
  self._anchor_trans = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  if not is_null(self._player_item_obj) then
    UIUtil.set_active(self._player_item_obj, false)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnAiQueueMyProgressChanged, pack(self, M._on_ai_queue_progress))
  self:add_evt_listener(EventID.OnAiQueueMyReady, pack(self, M._on_ai_queue_ready))
  self:add_evt_listener(EventID.OnAiQueueMyKicked, pack(self, M._on_ai_queue_kicked))
  self:add_evt_listener(EventID.OnAiQueueMyExited, pack(self, M._on_ai_queue_exited))
  self:add_evt_listener(EventID.SceneActivity.OnSceneActivityPlayerChanged, pack(self, M._on_activity_player_changed))
  self:add_evt_listener(EventID.OnSocketDisconnected, pack(self, M._on_socket_disconnected))
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  if data == nil then
    Logger.LogWarning("[AiQueue] AiMatchDialog on_enable: extra_data is nil")
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      if not is_null(self.game_obj) and self.is_active and self:get_extra_data() == nil then
        self:close_self()
      end
    end)
    return
  end
  self._gameplay_type = data.gameplay_type or 0
  if AiQueueConfig.get(self._gameplay_type) == nil then
    Logger.LogWarning("[AiQueue] AiMatchDialog on_enable: unsupported gameplay_type=" .. tostring(self._gameplay_type))
    CsCoroutineManagerUtil.InvokeNextFrame(function()
      if not is_null(self.game_obj) and self.is_active then
        self:close_self()
      end
    end)
    return
  end
  self._pos = data.pos or 0
  self._total = data.total or 0
  self._is_ready = data.is_ready or false
  self._coordinator = data.coordinator
  self:_align_to_anchor(data.anchor_trans)
  if self._coordinator then
    self._connection_epoch = self._coordinator:get_connection_epoch()
    self._connection_suspended = self._coordinator:is_connection_suspended()
    self._coordinator:set_dialog_projection_changed_callback(self, pack(self, M._on_projection_changed))
  end
  Logger.Log("[AiQueue] AiMatchDialog on_enable: type=" .. tostring(self._gameplay_type) .. " pos=" .. tostring(self._pos) .. " total=" .. tostring(self._total) .. " isReady=" .. tostring(self._is_ready))
  self:_refresh_view()
end

function M:_align_to_anchor(anchor_trans)
  self._anchor_trans = anchor_trans
  self:_apply_anchor_alignment()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if not is_null(self.game_obj) and self.is_active then
      self:_apply_anchor_alignment()
    end
  end)
end

function M:_apply_anchor_alignment()
  local anchor_trans = self._anchor_trans
  if is_null(anchor_trans) or is_null(self._player_items_obj) then
    return
  end
  local panel_trans = self._player_items_obj.transform.parent
  if is_null(panel_trans) or is_null(panel_trans.parent) then
    return
  end
  UIUtil.align_local_to_anchor(panel_trans, anchor_trans, "xy", PANEL_ANCHOR_OFFSET)
end

function M:on_disable()
  self._anchor_trans = nil
  self._exit_popup_token = self._exit_popup_token + 1
  if self._exit_queue_popup_guid then
    UIManagerInstance:close(self._exit_queue_popup_guid)
    self._exit_queue_popup_guid = nil
  end
  if self._coordinator then
    self._coordinator:clear_dialog_projection_changed_callback(self)
  end
  base.on_disable(self)
  self:_recycle_all()
end

function M:_on_socket_disconnected()
  self._connection_epoch = self._connection_epoch + 1
  self._connection_suspended = true
  self._exit_popup_token = self._exit_popup_token + 1
  if self._exit_queue_popup_guid then
    UIManagerInstance:close(self._exit_queue_popup_guid)
    self._exit_queue_popup_guid = nil
  end
  self:close_self()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_exit_queue, pack(self, M._on_btn_exit_queue))
  self:bind_callback(self._btn_start, pack(self, M._on_btn_start))
  self:bind_callback(self._btn_exit_match, pack(self, M._on_btn_exit_match))
end

function M:_is_match_mode()
  if self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator then
    local projection = self._coordinator:get_appraisal_projection()
    return projection ~= nil and projection.show_match_layout == true
  end
  return AiQueueConfig.get_activity_id(self._gameplay_type) ~= nil and self._is_ready
end

function M:_on_ai_queue_progress(data)
  local gameplay_type = data.value1
  local pos = data.value2
  local total = data.value3
  if gameplay_type ~= self._gameplay_type then
    return
  end
  if pos == nil or pos <= 0 then
    self._is_ready = false
    self:close_self()
    return
  end
  self._pos = pos or self._pos
  self._total = total or self._total
  local snapshot = not CsAiQueueModuleUtil.IsNull() and CsAiQueueModuleUtil.GetMyEntrySnapshot(self._gameplay_type) or nil
  self._is_ready = snapshot ~= nil and (snapshot.value4 or 0) == 1
  if not self:_is_match_mode() then
    self:_refresh_view()
  end
end

function M:_on_ai_queue_ready(data)
  local gameplay_type = data.value1
  Logger.Log("[AiQueue] AiMatchDialog _on_ai_queue_ready: type=" .. tostring(gameplay_type))
  if gameplay_type ~= self._gameplay_type then
    return
  end
  self._is_ready = true
  self:_refresh_view()
end

function M:_on_ai_queue_kicked(data)
  if data.value1 ~= self._gameplay_type then
    return
  end
  self:close_self()
end

function M:_on_ai_queue_exited(gameplay_type)
  if gameplay_type ~= self._gameplay_type then
    return
  end
  self:close_self()
end

function M:_on_projection_changed(projection)
  if projection ~= nil and projection.should_close_dialog then
    self:close_self()
    return
  end
  self:_refresh_view()
end

function M:_on_activity_player_changed(activity_id)
  local my_activity_id = AiQueueConfig.get_activity_id(self._gameplay_type)
  if my_activity_id == nil or activity_id ~= my_activity_id then
    return
  end
  if self._coordinator then
    return
  end
  self:_refresh_view()
end

function M:_refresh_view()
  local projection = self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator and self._coordinator:get_appraisal_projection() or nil
  if projection and projection.should_close_dialog then
    self:close_self()
    return
  end
  self:_recycle_all()
  if not is_null(self._state_group_type) then
    if self._gameplay_type == AI_QUEUE_GAMEPLAY_COFFEE then
      self._state_group_type:SetState(DIALOG_TYPE_STATE.COFFEE)
    elseif self._gameplay_type == AI_QUEUE_GAMEPLAY_COFFEE_PRIVATE then
      self._state_group_type:SetState(DIALOG_TYPE_STATE.COFFEE_PRIVATE)
    elseif self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
      self._state_group_type:SetState(DIALOG_TYPE_STATE.APPRAISAL)
    end
  end
  if self:_is_match_mode() then
    self:_refresh_match_mode()
  else
    self:_refresh_queue_mode()
  end
end

function M:_refresh_queue_mode()
  local projection = self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator and self._coordinator:get_appraisal_projection() or nil
  if not is_null(self._state_group_btn) then
    if self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
      self._state_group_btn:SetState(DIALOG_BUTTON_STATE.APPRAISAL_QUEUE)
    else
      self._state_group_btn:SetState(DIALOG_BUTTON_STATE.COFFEE)
    end
  end
  if not is_null(self._btn_wait_txt) then
    UIUtil.set_text(self._btn_wait_txt, UIUtil.get_text_by_id("AiQueue_Status_Queuing") .. " " .. UIUtil.get_text_by_id("AiQueue_Position_Ordinal", self._pos, self._total))
  end
  if not is_null(self._btn_exit_queue) then
    self._btn_exit_queue.interactable = projection == nil or projection.can_exit_queue
  end
  local item0 = self:_get_or_create_item(0)
  if item0 then
    local show_ahead_count = self._gameplay_type == AI_QUEUE_GAMEPLAY_COFFEE or self._gameplay_type == AI_QUEUE_GAMEPLAY_COFFEE_PRIVATE
    item0:set_host(self._pos, false, show_ahead_count)
  end
  if AiQueueConfig.is_duo(self._gameplay_type) then
    local item1 = self:_get_or_create_item(1)
    if item1 then
      local has_queuing_partner = self._total > 1 and (self._total % 2 == 0 or self._pos < self._total)
      if has_queuing_partner then
        item1:set_guest_queuing()
      else
        item1:set_empty()
      end
    end
  end
end

function M:_refresh_match_mode()
  local activity_id = AiQueueConfig.get_activity_id(self._gameplay_type)
  local projection = self._coordinator and self._coordinator:get_appraisal_projection() or nil
  if not is_null(self._state_group_btn) and self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL then
    self._state_group_btn:SetState(DIALOG_BUTTON_STATE.APPRAISAL_MATCH)
  end
  if not is_null(self._btn_wait_txt) then
    UIUtil.set_text(self._btn_wait_txt, UIUtil.get_text_by_id("SceneActivity_Match_Status_Success"))
  end
  local item_index = 0
  local self_uid = player_module:get_player_uid()
  if activity_id then
    local raw = CsSceneActivityModuleUtil.GetActivityMatchPlayerInfoList(activity_id)
    if raw then
      for i = 0, raw.Count - 1 do
        local player_info = raw[i]
        if player_info and (player_info.PlayerUid or 0) ~= 0 then
          local item = self:_get_or_create_item(item_index)
          if item then
            if player_info.PlayerUid == self_uid then
              item:set_host(self._pos, true)
            else
              item:set_guest_matched(player_info)
            end
            item_index = item_index + 1
          end
        end
      end
    end
  end
  if not is_null(self._btn_start) then
    self._btn_start.interactable = projection ~= nil and projection.can_start
  end
  if not is_null(self._btn_exit_match) then
    self._btn_exit_match.interactable = projection == nil or projection.can_exit_match
  end
end

function M:_get_or_create_item(idx)
  if is_null(self._player_item_obj) or is_null(self._player_items_obj) then
    return nil
  end
  local item = self._item_pool.active[idx + 1]
  if item and not is_null(item.game_obj) then
    return item
  end
  item = table.remove(self._item_pool.pool)
  if not item or is_null(item.game_obj) then
    local go = UIUtil.load_prefab_set_parent(self._player_item_obj, self._player_items_obj.transform)
    if is_null(go) then
      return nil
    end
    item = self:add_panel(AI_MATCH_PLAYER_ITEM_CLS, go)
  end
  if item then
    UIUtil.set_active(item.game_obj, true)
    self._item_pool.active[idx + 1] = item
  end
  return item
end

function M:_recycle_all()
  local active = self._item_pool.active
  for i = #active, 1, -1 do
    local item = active[i]
    if item and not is_null(item.game_obj) then
      UIUtil.set_active(item.game_obj, false)
      table.insert(self._item_pool.pool, item)
    end
    active[i] = nil
  end
end

function M:_on_btn_close()
  self:close_self()
end

function M:_on_btn_exit_queue()
  if self._coordinator and self._coordinator:is_connection_suspended() then
    return
  end
  Logger.Log("[AiQueue] _on_btn_exit_queue: type=" .. tostring(self._gameplay_type))
  self:_show_exit_confirm_popup(function()
    if self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator then
      local projection = self._coordinator:get_appraisal_projection()
      if projection == nil or not projection.can_exit_queue then
        return
      end
    end
    if not CsAiQueueModuleUtil.IsNull() then
      CsAiQueueModuleUtil.RequestCancel(self._gameplay_type)
    end
    self:close_self()
  end)
end

function M:_get_queue_name()
  return UIUtil.get_text_by_id(AiQueueConfig.get_name_text_id(self._gameplay_type))
end

function M:_on_btn_start()
  local activity_id = AiQueueConfig.get_activity_id(self._gameplay_type)
  if activity_id == nil then
    return
  end
  if self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator then
    self._coordinator:request_appraisal_start()
    return
  end
  Logger.Log("[AiQueue] _on_btn_start: activity_id=" .. tostring(activity_id) .. " status=1")
  CsSceneActivityModuleUtil.SceneActivityAgreeRunningReq(1)
end

function M:_on_btn_exit_match()
  local activity_id = AiQueueConfig.get_activity_id(self._gameplay_type)
  if activity_id == nil then
    return
  end
  if self._coordinator and self._coordinator:is_connection_suspended() then
    return
  end
  self:_show_exit_confirm_popup(function()
    if self._gameplay_type == AI_QUEUE_GAMEPLAY_APPRAISAL and self._coordinator then
      local projection = self._coordinator:get_appraisal_projection()
      if projection == nil or not projection.can_exit_match then
        return
      end
      self._coordinator:request_appraisal_match_exit()
    else
      CsSceneActivityModuleUtil.SceneActivityPlayerCancelJoinReq(activity_id)
    end
    self:close_self()
  end)
end

function M:_show_exit_confirm_popup(on_confirm_action)
  if self._exit_queue_popup_guid then
    return
  end
  local connection_epoch = self._coordinator and self._coordinator:get_connection_epoch() or self._connection_epoch
  self._exit_popup_token = self._exit_popup_token + 1
  local popup_token = self._exit_popup_token
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("AiQueue_Confirm_Leave"), UIUtil.get_text_by_id("Common_Confirm"), UIUtil.get_text_by_id("Common_Cancel"), self:_get_queue_name())
  
  local function take_popup()
    if popup_token ~= self._exit_popup_token then
      return false
    end
    self._exit_popup_token = self._exit_popup_token + 1
    self._exit_queue_popup_guid = nil
    return true
  end
  
  local function on_close()
    take_popup()
  end
  
  local function on_confirm()
    if not take_popup() then
      return
    end
    if self._coordinator and (connection_epoch ~= self._coordinator:get_connection_epoch() or self._coordinator:is_connection_suspended()) then
      return
    end
    on_confirm_action()
  end
  
  popup:set_callbacks(on_confirm, on_close, on_close)
  local popup_guid = popup:show()
  if popup_token == self._exit_popup_token then
    self._exit_queue_popup_guid = popup_guid
  elseif popup_guid then
    UIManagerInstance:close(popup_guid)
  end
end

return M
