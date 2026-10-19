accompanying_module = accompanying_module or {}

function accompanying_module:_init_data()
end

function accompanying_module:add_event()
  accompanying_module:remove_event()
  self._events = {}
  self._events[EventID.OnFriendCompanionSummaryNotify] = pack(self, self.on_friend_companion_summary_notify)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function accompanying_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function accompanying_module:on_friend_companion_summary_notify(foot_step_value)
  accompanying_module:open_settlement_tips(foot_step_value)
end

AccompanyingConst = AccompanyingConst or {}
AccompanyingConst.play_cfg_leader = 224
AccompanyingConst.play_cfg_follower = 225
AccompanyingConst.settlement_close_duration = 2
return accompanying_module
