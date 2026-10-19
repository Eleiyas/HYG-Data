riddle_module = riddle_module or {}
local ANSWER_PAGE_PATH = "UI/MainActivity_y1/Riddle/RiddleAnswerPage"

function riddle_module:add_event()
  riddle_module:remove_event()
  self._events = {}
  self._events[EventID.LuaRiddleAnswerBubbleUpdate] = pack(self, riddle_module._on_answer_bubble_update)
  self._events[EventID.LuaRiddleCheckDailyRefreshAbort] = pack(self, riddle_module._on_check_daily_refresh_abort)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function riddle_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function riddle_module:_on_answer_bubble_update(context)
  self._pending_answer_bubble_context = context
  local page = UIManagerInstance:is_show(ANSWER_PAGE_PATH)
  if page == nil or page.on_riddle_answer_bubble_update == nil then
    return
  end
  local consumed = page:on_riddle_answer_bubble_update(context)
  if consumed == true then
    self._pending_answer_bubble_context = nil
  end
end

function riddle_module:consume_pending_answer_bubble_context()
  local context = self._pending_answer_bubble_context
  self._pending_answer_bubble_context = nil
  return context
end

function riddle_module:cache_pending_answer_bubble_context(context)
  self._pending_answer_bubble_context = context
end

function riddle_module:_on_check_daily_refresh_abort()
  if self:is_activity_ended() then
    Logger.Log("[riddle_module] 活动已结束，跨天收尾让位给「活动已结束」弹窗")
    return
  end
  EventCenter.Broadcast(EventID.LuaRiddleConfirmAnswerSessionAbort)
end

function riddle_module:request_activity_info_if_needed(event_id)
  if CsRiddleModuleUtil == nil or CsRiddleModuleUtil.RequestActivityInfo == nil then
    return
  end
  if self:has_activity_info() then
    return
  end
  CsRiddleModuleUtil.RequestActivityInfo(event_id or self.default_event_id)
end

function riddle_module:request_take_stage_reward(stage, event_id)
  if CsRiddleModuleUtil == nil or CsRiddleModuleUtil.RequestTakeStageReward == nil then
    return
  end
  CsRiddleModuleUtil.RequestTakeStageReward(stage, event_id or self.default_event_id)
end

function riddle_module:request_take_all_stage_rewards(event_id)
  local stages = self:get_claimable_stages()
  if #stages == 0 then
    return {}, {}
  end
  local item_lists = {}
  for _, stage in ipairs(stages) do
    item_lists[#item_lists + 1] = self:get_stage_reward_items(self:find_stage_reward_by_stage(stage))
  end
  local items = self:merge_reward_items(item_lists)
  for _, stage in ipairs(stages) do
    self:request_take_stage_reward(stage, event_id)
  end
  return stages, items
end

return riddle_module
