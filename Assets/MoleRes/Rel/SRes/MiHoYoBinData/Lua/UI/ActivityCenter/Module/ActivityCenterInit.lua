activity_center_module = activity_center_module or {}
activity_center_module._cname = "activity_center_module"
lua_module_mgr:require("UI/ActivityCenter/Module/ActivityCenterCommon")
lua_module_mgr:require("UI/ActivityCenter/Module/ActivityCenterCfg")
lua_module_mgr:require("UI/ActivityCenter/Module/ActivityCenterData")
lua_module_mgr:require("UI/ActivityCenter/Module/ActivityCenterMain")
require("UI/ActivityCenter/SubPanel/SpringFestival/Module/SpringFestivalActivityInit")
require("UI/ActivityCenter/SubPanel/NewYearSprint/Module/NewYearSprintActivityInit")

function activity_center_module:init()
  self._events = nil
  activity_center_module:add_event()
  spring_festival_activity_module:init()
  new_year_sprint_activity_module:init()
end

function activity_center_module:close()
  activity_center_module:remove_event()
  spring_festival_activity_module:close()
  new_year_sprint_activity_module:close()
end

function activity_center_module:clear_on_disconnect()
  self:clear_activity_time_cache()
end

return activity_center_module
