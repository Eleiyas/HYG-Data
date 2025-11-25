local M = G.Class("UIIdleTransactionProcessor")

function M:init()
  self._events = nil
  self:_add_event()
  self.npc_favour_level_up_data = {}
  self.npc_favour_task_data = {}
  self.npc_favour_data = {}
end

function M:destroy()
  self:_remove_event()
end

function M:_add_event()
  self:_remove_event()
  self._events = {}
  self._events[EventID.showFavourTip] = pack(self, M._on_npc_favour_level_up)
  self._events[EventID.ShowFavorTaskTips] = pack(self, M._on_npc_favour_task_tip)
  self._events[EventID.CanShowFavourLevelUp] = pack(self, M._set_can_show_favour_level_up_tip)
  self._events[EventID.OnNpcFavourIncrease] = pack(self, M._on_npc_favour_increase)
  self._events[EventID.LuaRefreshPhoneCallEffect] = pack(self, M._on_refresh_phone_call_effect)
  self._events[EventID.OnArchporDataCached] = pack(self, M._on_archpor_data_cached)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function M:_remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function M:tick(deltaTime)
end

function M:try_process_transaction_on_idle()
  if not UIIdleDetectManagerIns.main_idle then
    return
  end
  local success = self:_try_show_favour_level_up_tip()
  if success then
    return
  end
  success = self:_try_update_phone_call_dialog()
  if success then
    return
  end
end

function M:try_process_transaction_on_active()
  if not UIIdleDetectManagerIns.main_active then
    return
  end
  self:_try_show_favour_exp_tip()
  self:_try_show_favour_task_tip()
end

function M:on_main_page_become_idle()
  self:try_process_transaction_on_idle()
  self:_try_tick_archpor_drop()
end

function M:on_main_page_become_active()
  self:try_process_transaction_on_active()
end

function M:on_main_page_become_non_idle()
  self:_close_phone_call_dialog()
end

function M:on_main_page_become_non_active()
end

function M:_on_npc_favour_level_up(data)
  table.insert(self.npc_favour_level_up_data, data)
  self._can_show_level_up_tip = true
  self:_try_show_favour_level_up_tip()
end

function M:_try_show_favour_level_up_tip()
  if not UIIdleDetectManagerIns.main_idle then
    return
  end
  if self._can_show_level_up_tip then
    if #self.npc_favour_level_up_data > 0 then
      local data = {
        level_up_data = self.npc_favour_level_up_data[1],
        is_force = false
      }
      UIManagerInstance:open("UI/NpcFavour/NpcFavourLevelUpTip/NpcFavourLevelUpTip", data)
      table.remove(self.npc_favour_level_up_data, 1)
      return true
    else
      self._can_show_level_up_tip = false
    end
  end
  return false
end

function M:force_show_favour_level_up_tip()
  if #self.npc_favour_level_up_data > 0 then
    local data = {
      level_up_data = self.npc_favour_level_up_data[1],
      is_force = true
    }
    UIManagerInstance:open("UI/NpcFavour/NpcFavourLevelUpTip/NpcFavourLevelUpTip", data)
    table.remove(self.npc_favour_level_up_data, 1)
  end
end

function M:_set_can_show_favour_level_up_tip()
  self._can_show_level_up_tip = true
  self:_try_show_favour_level_up_tip()
end

function M:_on_npc_favour_increase(data)
  table.insert(self.npc_favour_data, data)
  self:_try_show_favour_exp_tip()
end

function M:_try_show_favour_exp_tip()
  if not UIIdleDetectManagerIns.main_active then
    return
  end
  if #self.npc_favour_data > 0 then
    for i, data in ipairs(self.npc_favour_data) do
      if data then
        lua_event_module:send_event(lua_event_module.event_type.show_favor_increase_effect, data)
      end
    end
    table.clear(self.npc_favour_data)
    return true
  end
end

function M:_on_npc_favour_task_tip(data)
  if is_null(data) or self:is_npc_favour_task_data_repeat(data) then
    return
  end
  if self:_is_max_level(data) then
    return
  end
  table.insert(self.npc_favour_task_data, data)
  self:_try_show_favour_task_tip()
end

function M:_is_max_level(data)
  if data then
    return data.level == npc_favour_module:get_npc_max_lv(data.npcId)
  end
end

function M:is_npc_favour_task_data_repeat(data)
  for _, _data in ipairs(self.npc_favour_task_data) do
    if _data and data.level == _data.level then
      return true
    end
  end
  return false
end

function M:_try_show_favour_task_tip()
  if not UIIdleDetectManagerIns.main_active then
    return
  end
  if #self.npc_favour_task_data > 0 then
    local data = {
      level_up_data = self.npc_favour_task_data[1],
      is_force = false
    }
    UIManagerInstance:open("UI/NpcFavour/FavorTaskTip/FavorTaskTip", data)
    table.remove(self.npc_favour_task_data, 1)
    return true
  end
end

function M:_try_tick_archpor_drop()
  CsCompanionStarManagerUtil.TickArchporDrop()
end

function M:_on_refresh_phone_call_effect(effect)
  self:_try_update_phone_call_dialog()
end

function M:_try_update_phone_call_dialog()
  if not UIIdleDetectManagerIns.main_idle then
    self:_close_phone_call_dialog()
    return false
  end
  local npc_id = CsPhoneCallModuleUtil.GetCurrentNpcId()
  if npc_id and 0 < npc_id then
    hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.npc_phone_call, {npc_id = npc_id})
    return true
  end
  self:_close_phone_call_dialog()
  return false
end

function M:_close_phone_call_dialog()
  hud_info_module:remove_hud_info_ui(hud_info_module.hud_ui_type.npc_phone_call)
end

function M:_on_archpor_data_cached()
  if UIManagerInstance:is_main_page_in_idle() then
    self:_try_tick_archpor_drop()
  end
end

return M
