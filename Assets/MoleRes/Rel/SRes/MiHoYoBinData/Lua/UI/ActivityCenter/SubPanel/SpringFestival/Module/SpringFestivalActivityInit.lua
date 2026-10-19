spring_festival_activity_module = spring_festival_activity_module or {}
spring_festival_activity_module._cname = "spring_festival_activity_module"
require("UI/ActivityCenter/SubPanel/SpringFestival/Module/SpringFestivalActivityCommon")
require("UI/ActivityCenter/SubPanel/SpringFestival/Module/SpringFestivalActivityData")
require("UI/ActivityCenter/SubPanel/SpringFestival/Module/SpringFestivalCalendarData")
require("UI/ActivityCenter/SubPanel/SpringFestival/Module/SpringFestivalActivityMain")

function spring_festival_activity_module:init()
  self:register_tracking_navigation()
  self:add_event()
  self:register_cmd_handler()
end

function spring_festival_activity_module:close()
  self:unregister_tracking_navigation()
  self:remove_event()
  self:unregister_cmd_handler()
end

function spring_festival_activity_module:register_cmd_handler()
  self:unregister_cmd_handler()
  self._cmd_handlers = {
    [CS.Proto.LanternDailyOpenStateNotify] = pack(self, self.on_lantern_daily_open_notify)
  }
  for cmd, handler in pairs(self._cmd_handlers) do
    NetHandlerIns:register_cmd_handler(cmd, handler)
  end
end

function spring_festival_activity_module:unregister_cmd_handler()
  if self._cmd_handlers == nil then
    return
  end
  for cmd, _ in pairs(self._cmd_handlers) do
    NetHandlerIns:unregister_cmd_handler(cmd)
  end
  self._cmd_handlers = nil
end

function spring_festival_activity_module:add_event()
  self:remove_event()
  self._events = {
    [EventID.OnActivityDataChanged] = pack(self, self.refresh_red_dot),
    [EventID.OnActivityListChanged] = pack(self, self.refresh_red_dot),
    [EventID.OnActivityRemoved] = pack(self, self.refresh_red_dot),
    [EventID.OnTaskStateChange] = pack(self, self.refresh_red_dot),
    [EventID.onDailyRefresh] = pack(self, self.refresh_red_dot),
    [EventID.OnRiddleActivityInfoChange] = pack(self, self.notify_red_dot_dirty)
  }
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function spring_festival_activity_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return spring_festival_activity_module
