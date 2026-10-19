new_year_sprint_activity_module = new_year_sprint_activity_module or {}
new_year_sprint_activity_module._cname = "new_year_sprint_activity_module"
lua_module_mgr:require("UI/ActivityCenter/SubPanel/NewYearSprint/Module/NewYearSprintActivityCommon")
lua_module_mgr:require("UI/ActivityCenter/SubPanel/NewYearSprint/Module/NewYearSprintActivityData")
lua_module_mgr:require("UI/ActivityCenter/SubPanel/NewYearSprint/Module/NewYearSprintActivityMain")

function new_year_sprint_activity_module:init()
  self:register_tracking_navigation()
  self:reset_memory_shelf_unlock_state()
  self:add_event()
end

function new_year_sprint_activity_module:close()
  self:unregister_tracking_navigation()
  self:remove_event()
end

function new_year_sprint_activity_module:add_event()
  self:remove_event()
  self._events = {}
  local on_red_dot_dirty = pack(self, new_year_sprint_activity_module.refresh_red_dot)
  self._events[EventID.OnActivityDataChanged] = on_red_dot_dirty
  self._events[EventID.OnActivityListChanged] = on_red_dot_dirty
  self._events[EventID.OnActivityRemoved] = on_red_dot_dirty
  self._events[EventID.onDailyRefresh] = on_red_dot_dirty
  self._events[EventID.TrackerUpdateNotify] = pack(self, new_year_sprint_activity_module.on_tracker_update_notify)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function new_year_sprint_activity_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return new_year_sprint_activity_module
